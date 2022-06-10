//
//  Audio.swift
//  VoiceTest
//
//  Created by John Nastos on 6/10/22.
//

import Foundation
import AudioToolbox

class AudioManager: ObservableObject {
    @Published var isSetup = false
    @Published var isRunning = false
    
    func setupAudio() {
        // Get the current device(s)
        
        // Setup the audio units
        
        // Setup the buffers
        
        isSetup = true
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
        
    }
    
    func stopAudio() {
        
    }
}

class DeviceManager {
    // Core Audio constants
    let outputBus = UInt32(0) // stream to output hardware
    let inputBus = UInt32(1) // stream from HAL input hardware
    var enabled = UInt32(1)
    var disabled = UInt32(0)
    
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
    
    func makeAudioComponentDescriptionHALOutput() -> AudioComponentDescription {
        var audioComponentDescription = AudioComponentDescription()

        audioComponentDescription.componentType = kAudioUnitType_Output
        audioComponentDescription.componentSubType = kAudioUnitSubType_HALOutput
        audioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple
        audioComponentDescription.componentFlags = 0
        audioComponentDescription.componentFlagsMask = 0

        return audioComponentDescription
    }
    
    func makeAudioInputUnit(rawContext: UnsafeMutableRawPointer,
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

func size<T>(of value: T) -> UInt32 {
    return UInt32(MemoryLayout.size(ofValue: value))
}
