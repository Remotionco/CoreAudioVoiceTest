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
    @Published var listedDevices: [(name: String, id: AudioObjectID)] = []
        
    struct DeviceState {
        var inputUnit: AudioUnit?
        var outputUnit: AudioUnit?
    }
    
    private var deviceState = DeviceState()
    
    func getPermissions() {
        AVCaptureDevice.requestAccess(for: .audio) { value in
            print("Permission: \(value)")
        }
    }
    
    func listDevices() {
        self.listedDevices = DeviceManager.allDevices()
    }
    
    func setupAudio(deviceID: AudioDeviceID) {
        // AudioStreamBasicDescription
        let sampleRate = DeviceManager.getSampleRateForDevice(deviceID)
        print("Sample rate: \(sampleRate)")
        let desc: AudioStreamBasicDescription = FormatManager.makeAudioStreamBasicDescription(sampleRate: sampleRate)
        
        // Setup the audio units
        do {
            let inputUnit = try DeviceManager.makeAudioInputUnit(rawContext: contextPointer,
                                                                       audioDeviceID: deviceID,
                                                                       audioStreamBasicDescription: desc)
            deviceState.inputUnit = inputUnit
            
            contextPointer.pointee.inputAudioUnit = inputUnit
        } catch {
            assertionFailure("Error: \(error)")
        }
        
        // Setup the buffers
        
        isSetup = true
        print("Setup success")
    }
    
    func toggleAudio() {
        guard isSetup else {
            assertionFailure("Not setup")
            return
        }
        if isRunning {
            stopAudio()
        } else {
            startAudio()
        }
    }
    
    func startAudio() {
        guard let inputUnit = deviceState.inputUnit else {
            assertionFailure()
            return
        }
        do {
            try startAudioUnit(inputUnit)
        } catch {
            assertionFailure("Start error: \(error)")
        }
        self.isRunning = true
        print("Started")
    }
    
    enum CustomAudioPipelineError: Error {
        case couldNotInitialize(error: OSStatus)
        case couldNotStart(error: OSStatus)
        case couldNotSetBufferSize(error: OSStatus)
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
        guard let inputUnit = deviceState.inputUnit else {
            assertionFailure()
            return
        }
        stopAudioUnit(inputUnit)
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
    
    // Core Audio constants
    static let outputBus = UInt32(0) // stream to output hardware
    static let inputBus = UInt32(1) // stream from HAL input hardware
    static var enabled = UInt32(1)
    static var disabled = UInt32(0)
    
    enum AudioUnitInputCreationError: Error {
        case cantFindAudioHALOutputComponent
        case cantInstantiateHALOutputComponent(error: OSStatus)
        case audioUnitNil
        case halCantEnableInputIO(error: OSStatus)
        case halCantDisableOutputIO(error: OSStatus)
        case halCantSetInputDevice(error: OSStatus)
        case cantSetOutputFormat(error: OSStatus)
        case cantSetInputCallback(error: OSStatus)
        case couldNotSetInputSampleRate(error: OSStatus)
        case unknown
    }
    
    private class func makeAudioComponentDescriptionHALOutput() -> AudioComponentDescription {
        var audioComponentDescription = AudioComponentDescription()

        audioComponentDescription.componentType = kAudioUnitType_Output
        audioComponentDescription.componentSubType = kAudioUnitSubType_HALOutput
        audioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple
        audioComponentDescription.componentFlags = 0
        audioComponentDescription.componentFlagsMask = 0

        return audioComponentDescription
    }
    
    class func makeAudioInputUnit(rawContext: UnsafeMutableRawPointer,
                            audioDeviceID: AudioObjectID,
                            audioStreamBasicDescription: AudioStreamBasicDescription) throws -> AudioUnit
    {
        var audioComponentDescription: AudioComponentDescription = makeAudioComponentDescriptionHALOutput()

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

        return audioUnit
    }
}
