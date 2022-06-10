//
//  Audio.swift
//  VoiceTest
//
//  Created by John Nastos on 6/10/22.
//

import Foundation
import AudioToolbox
import AVFoundation

private var context = CustomAudioContext()
private let contextPointer = UnsafeMutablePointer(&context)

class AudioManager: ObservableObject {
    @Published var isSetup = false
    @Published var isRunning = false
    @Published var listedDevices: [AudioDevice] = []
        
    func setupAudio(inputDevice: AudioDevice, outputDevice: AudioDevice, subType: UnitSubType) {
        // Setup the audio units
        do {
            let desc: AudioStreamBasicDescription =
                FormatManager.makeAudioStreamBasicDescription(sampleRate: inputDevice.sampleRate)
            
            let inputUnit = try DeviceManager.makeAudioInputUnit(rawContext: contextPointer,
                                                                 subType: subType,
                                                                 audioDeviceID: inputDevice.id,
                                                                 audioStreamBasicDescription: desc)
            
            // Setup the buffers
            try DeviceManager.setAudioUnitBufferSize(audioUnit: inputUnit, bufferSize: CircularBuffer.calculateSamplesPerBlock(sampleRate: desc.mSampleRate))
            
            contextPointer.pointee.inputAudioUnit = inputUnit
        } catch {
            assertionFailure("Input error: \(error)")
        }
        
        do {
            let desc: AudioStreamBasicDescription =
                FormatManager.makeAudioStreamBasicDescription(sampleRate: outputDevice.sampleRate)
            
            let outputUnit = try DeviceManager.makeAudioOutputUnit(rawContext: contextPointer,
                                                                   subType: subType,
                                                                   audioDeviceID: outputDevice.id,
                                                                   audioStreamBasicDescription: desc)
            // Setup the buffers
            try DeviceManager.setAudioUnitBufferSize(audioUnit: outputUnit, bufferSize: CircularBuffer.calculateSamplesPerBlock(sampleRate: desc.mSampleRate))
            
            contextPointer.pointee.outputAudioUnit = outputUnit
        } catch {
            assertionFailure("Output error: \(error)")
        }
        
        
        isSetup = true
        print("Setup success")
    }
    
    func startAudio() {
        guard let inputUnit = contextPointer.pointee.inputAudioUnit else {
            assertionFailure()
            return
        }
        guard let outputUnit = contextPointer.pointee.outputAudioUnit else {
            assertionFailure()
            return
        }
        do {
            try startAudioUnit(inputUnit)
        } catch {
            assertionFailure("Start input error: \(error)")
        }
        
        do {
            try startAudioUnit(outputUnit)
        } catch {
            assertionFailure("Start output error: \(error)")
        }
        
        self.isRunning = true
        print("Started")
    }
    
    private func startAudioUnit(_ audioUnit: AudioUnit) throws {
        var error: OSStatus = noErr
        error = AudioUnitInitialize(audioUnit)
        guard error == noErr else {
            throw CustomAudioPipelineError.couldNotInitialize(error: error)
        }

        error = AudioOutputUnitStart(audioUnit)
        guard error == noErr else {
            throw CustomAudioPipelineError.couldNotStart(error: error)
        }
    }
    
    func stopAudio() {
        guard let inputUnit = contextPointer.pointee.inputAudioUnit else {
            assertionFailure()
            return
        }
        guard let outputUnit = contextPointer.pointee.outputAudioUnit else {
            assertionFailure()
            return
        }
        stopAudioUnit(inputUnit)
        stopAudioUnit(outputUnit)
        self.isRunning = false
    }
    
    private func stopAudioUnit(_ audioUnit: AudioUnit) {
        var error: OSStatus = noErr

        error = AudioOutputUnitStop(audioUnit)
        
        if error != noErr {
            assertionFailure("Stop error: \(error)")
        }
    }
}

class DeviceManager {
    var activeInputID: AudioObjectID?
    var activeOutputID: AudioObjectID?
    
    private class func makeAudioComponentDescriptionHALOutput(subType: UnitSubType) -> AudioComponentDescription {
        var audioComponentDescription = AudioComponentDescription()
        audioComponentDescription.componentType = kAudioUnitType_Output
        audioComponentDescription.componentSubType = subType.subTypeValue // either HALOutput or VoiceProcessingIO
        audioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple
        audioComponentDescription.componentFlags = 0
        audioComponentDescription.componentFlagsMask = 0

        return audioComponentDescription
    }
    
    class func makeAudioInputUnit(rawContext: UnsafeMutableRawPointer,
                                  subType: UnitSubType,
                            audioDeviceID: AudioObjectID,
                            audioStreamBasicDescription: AudioStreamBasicDescription) throws -> AudioUnit
    {
        var audioComponentDescription: AudioComponentDescription = makeAudioComponentDescriptionHALOutput(subType: subType)

        guard let audioComponent = AudioComponentFindNext(nil, &audioComponentDescription) else {
            throw AudioUnitInputCreationError.cantFindAudioHALOutputComponent
        }

        var optionalAudioUnit: AudioUnit?
        var error = AudioComponentInstanceNew(audioComponent, &optionalAudioUnit)
        guard error == noErr else {
            throw AudioUnitInputCreationError.cantInstantiateHALOutputComponent(error: error)
        }

        guard let audioUnit: AudioUnit = optionalAudioUnit else {
            throw AudioUnitInputCreationError.audioUnitNil
        }

        error = AudioUnitSetProperty(audioUnit,
                                     kAudioOutputUnitProperty_EnableIO,
                                     kAudioUnitScope_Input,
                                     inputBus,
                                     &enabled,
                                     size(of: enabled))
        guard error == noErr else {
            throw AudioUnitInputCreationError.halCantEnableInputIO(error: error)
        }

        error = AudioUnitSetProperty(audioUnit,
                                     kAudioOutputUnitProperty_EnableIO,
                                     kAudioUnitScope_Output,
                                     outputBus,
                                     &disabled,
                                     size(of: disabled))
        guard error == noErr else {
            throw AudioUnitInputCreationError.halCantDisableOutputIO(error: error)
        }

        var audioDeviceIDPassable: AudioObjectID = audioDeviceID
        error = AudioUnitSetProperty(audioUnit,
                                     kAudioOutputUnitProperty_CurrentDevice,
                                     kAudioUnitScope_Global,
                                     inputBus,
                                     &audioDeviceIDPassable,
                                     size(of: audioDeviceID))
        guard error == noErr else {
            throw AudioUnitInputCreationError.halCantSetInputDevice(error: error)
        }

        var audioStreamBasicDescription = audioStreamBasicDescription
        error = AudioUnitSetProperty(audioUnit,
                                     kAudioUnitProperty_StreamFormat,
                                     kAudioUnitScope_Output,
                                     inputBus,
                                     &audioStreamBasicDescription,
                                     size(of: audioStreamBasicDescription))
        guard error == noErr else {
            throw AudioUnitInputCreationError.cantSetOutputFormat(error: error)
        }

        var renderCallbackStruct = AURenderCallbackStruct()
        renderCallbackStruct.inputProc = AudioUnitRecordingCallback
        renderCallbackStruct.inputProcRefCon = rawContext

        error = AudioUnitSetProperty(audioUnit,
                                     kAudioOutputUnitProperty_SetInputCallback,
                                     kAudioUnitScope_Global,
                                     inputBus,
                                     &renderCallbackStruct,
                                     size(of: renderCallbackStruct))
        guard error == noErr else {
            throw AudioUnitInputCreationError.cantSetInputCallback(error: error)
        }
        
        CircularBuffer.destroy(contextPointer.pointee.inputBuffer)
        contextPointer.pointee.inputBuffer = CircularBuffer.makeCircularBuffer(
            sampleRate: audioStreamBasicDescription.mSampleRate
        )
        
        contextPointer.pointee.bytesPerBlock = Int32(CircularBuffer.calculateSamplesPerBlock(sampleRate: audioStreamBasicDescription.mSampleRate))

        return audioUnit
    }
    
    class func makeAudioOutputUnit(rawContext: UnsafeMutableRawPointer,
                                   subType: UnitSubType,
                                   audioDeviceID: AudioObjectID,
                                   audioStreamBasicDescription: AudioStreamBasicDescription) throws -> AudioUnit
    {
        var audioComponentDescription: AudioComponentDescription = makeAudioComponentDescriptionHALOutput(subType: subType)

        guard let audioComponent = AudioComponentFindNext(nil, &audioComponentDescription) else {
            throw AudioUnitOutputCreationError.cantFindAudioHALOutputComponent
        }

        var optionalAudioUnit: AudioUnit?
        var error = AudioComponentInstanceNew(audioComponent, &optionalAudioUnit)
        guard error == noErr else {
            throw AudioUnitOutputCreationError.cantInstantiateHALOutputComponent(error: error)
        }

        guard let audioUnit: AudioUnit = optionalAudioUnit else {
            throw AudioUnitOutputCreationError.audioUnitNil
        }

        error = AudioUnitSetProperty(audioUnit,
                                     kAudioOutputUnitProperty_EnableIO,
                                     kAudioUnitScope_Input,
                                     inputBus,
                                     &disabled,
                                     size(of: disabled))
        guard error == noErr else {
            throw AudioUnitOutputCreationError.halCantDisableInputIO(error: error)
        }

        error = AudioUnitSetProperty(audioUnit,
                                     kAudioOutputUnitProperty_EnableIO,
                                     kAudioUnitScope_Output,
                                     outputBus,
                                     &enabled,
                                     size(of: enabled))
        guard error == noErr else {
            throw AudioUnitOutputCreationError.halCantEnableOutputIO(error: error)
        }

        var audioDeviceIDPassable: AudioObjectID = audioDeviceID
        error = AudioUnitSetProperty(audioUnit,
                                     kAudioOutputUnitProperty_CurrentDevice,
                                     kAudioUnitScope_Global,
                                     outputBus,
                                     &audioDeviceIDPassable,
                                     size(of: audioDeviceID))
        guard error == noErr else {
            throw AudioUnitOutputCreationError.halCantSetOutputDevice(error: error)
        }

        var audioStreamBasicDescription = audioStreamBasicDescription
        error = AudioUnitSetProperty(audioUnit,
                                     kAudioUnitProperty_StreamFormat,
                                     kAudioUnitScope_Input,
                                     outputBus,
                                     &audioStreamBasicDescription,
                                     size(of: audioStreamBasicDescription))
        guard error == noErr else {
            throw AudioUnitOutputCreationError.cantSetInputFormat(error: error)
        }

        var renderCallbackStruct = AURenderCallbackStruct()
        renderCallbackStruct.inputProc = AudioUnitPlayoutCallback

        // Using UnsafeMutableRawPointer with a global variable is safe. It must not be used in any other context but this one.
        renderCallbackStruct.inputProcRefCon = rawContext

        error = AudioUnitSetProperty(audioUnit,
                                     kAudioUnitProperty_SetRenderCallback,
                                     kAudioUnitScope_Input,
                                     outputBus,
                                     &renderCallbackStruct,
                                     size(of: renderCallbackStruct))
        guard error == noErr else {
            throw AudioUnitOutputCreationError.cantSetRenderCallback(error: error)
        }

        return audioUnit
    }
    
    class func setAudioUnitBufferSize(audioUnit: AudioUnit?, bufferSize: Int) throws {
        guard bufferSize > 0, let audioUnit = audioUnit else {
            return
        }
        
        print("Set buffer to: \(bufferSize)")
        
        var bufferSize = UInt32(bufferSize)
        let error = AudioUnitSetProperty(audioUnit,
                                         kAudioDevicePropertyBufferFrameSize,
                                         kAudioUnitScope_Global,
                                         0,
                                         &bufferSize,
                                         size(of: bufferSize))
        guard error == noErr else {
            assertionFailure("Can't set buffer size")
            throw CustomAudioPipelineError.couldNotSetBufferSize(error: error)
        }
    }
}

extension DeviceManager {
    
    // Core Audio constants
    static let outputBus = UInt32(0) // stream to output hardware
    static let inputBus = UInt32(1) // stream from HAL input hardware
    static var enabled = UInt32(1)
    static var disabled = UInt32(0)
    
}
