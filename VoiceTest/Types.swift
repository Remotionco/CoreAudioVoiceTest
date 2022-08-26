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
    case cantFindAudioHALOutputComponent
    case cantInstantiateHALOutputComponent(error: OSStatus)
    case audioUnitNil
    case halCantDisableInputIO(error: OSStatus)
    case halCantEnableOutputIO(error: OSStatus)
    case halCantSetOutputDevice(error: OSStatus)
    case cantSetInputFormat(error: OSStatus)
    case cantSetRenderCallback(error: OSStatus)
    case couldNotSetOutputSampleRate(error: OSStatus)
    case unknown
}

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
