//
//  Types.swift
//  VoiceTest
//
//  Created by John Nastos on 6/10/22.
//

import Foundation
import AudioToolbox

enum CustomAudioPipelineError: Error {
    case couldNotInitialize(error: OSStatus)
    case couldNotStart(error: OSStatus)
    case couldNotSetBufferSize(error: OSStatus)
}

enum AudioUnitOutputCreationError: Error {
    case cantFindAudioOutputComponent
    case cantInstantiateOutputComponent(error: OSStatus)
    case audioUnitNil
    case cantDisableInputIO(error: OSStatus)
    case cantEnableOutputIO(error: OSStatus)
    case cantSetOutputDevice(error: OSStatus)
    case cantSetInputFormat(error: OSStatus)
    case cantSetRenderCallback(error: OSStatus)
    case couldNotSetOutputSampleRate(error: OSStatus)
    case unknown
}

enum AudioUnitInputCreationError: Error {
    case cantFindAudioOutputComponent
    case cantInstantiateOutputComponent(error: OSStatus)
    case audioUnitNil
    case cantEnableInputIO(error: OSStatus)
    case cantDisableOutputIO(error: OSStatus)
    case cantSetInputDevice(error: OSStatus)
    case cantSetOutputFormat(error: OSStatus)
    case cantSetInputCallback(error: OSStatus)
    case couldNotSetInputSampleRate(error: OSStatus)
    case unknown
}


func size<T>(of value: T) -> UInt32 {
    return UInt32(MemoryLayout.size(ofValue: value))
}

struct DeviceType: Equatable {
    var isMicrophone: Bool
    var isSpeaker: Bool
}

struct AudioDevice: Identifiable {
    var id: AudioObjectID
    var name: String
    var deviceType: DeviceType
    var sampleRate: Float64
    var nominalSampleRates: [Float64]
}

extension AudioDevice: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
}
