//
//  Audio.swift
//  VoiceTest
//
//  Created by John Nastos on 6/10/22.
//

import Foundation
import AudioToolbox
import AVFoundation

class AudioManager: ObservableObject {
    @Published var isSetup = false
    @Published var isRunning = false
    
    func getPermissions() {
        AVCaptureDevice.requestAccess(for: .audio) { value in
            print("Permission: \(value)")
        }
    }
    
    func listDevices() {
        print(DeviceManager.allDevices())
    }
    
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

// For getting devices
extension DeviceManager {
    public class func allDevices() -> [(name: String, id: AudioObjectID)] {
        return allDeviceIDs().map { (name: getDeviceName($0) ?? "Unknown - \($0)", id: $0) }
    }
    
    class func allDeviceIDs() -> [AudioObjectID] {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        let systemObjectID = AudioObjectID(kAudioObjectSystemObject)
        var allIDs = [AudioObjectID]()
        let status: OSStatus = getPropertyDataArray(systemObjectID, address: address, value: &allIDs, andDefaultValue: 0)

        return noErr == status ? allIDs : []
    }
    
    class func getPropertyDataSize<Q>(_ objectID: AudioObjectID,
                                      address: AudioObjectPropertyAddress,
                                      qualifierDataSize: UInt32?,
                                      qualifierData: inout Q,
                                      andSize size: inout UInt32) -> (OSStatus)
    {
        var theAddress = address

        return AudioObjectGetPropertyDataSize(objectID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size)
    }
    
    class func getPropertyDataArray<T, Q>(_ objectID: AudioObjectID,
                                          address: AudioObjectPropertyAddress,
                                          qualifierDataSize: UInt32?,
                                          qualifierData: inout Q,
                                          value: inout [T],
                                          andDefaultValue defaultValue: T) -> OSStatus
    {
        var size = UInt32(0)
        let sizeStatus = getPropertyDataSize(objectID, address: address, qualifierDataSize: qualifierDataSize, qualifierData: &qualifierData,
                                             andSize: &size)

        if noErr == sizeStatus {
            value = [T](repeating: defaultValue, count: Int(size) / MemoryLayout<T>.size)
        } else {
            return sizeStatus
        }

        var theAddress = address
        let status = AudioObjectGetPropertyData(objectID, &theAddress, qualifierDataSize ?? UInt32(0), &qualifierData, &size, &value)

        return status
    }
    
    class func getPropertyDataArray<T>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, value: inout [T],
                                       andDefaultValue defaultValue: T) -> OSStatus
    {
        var nilValue: ExpressibleByNilLiteral?

        return getPropertyDataArray(objectID, address: address, qualifierDataSize: nil, qualifierData: &nilValue, value: &value,
                                    andDefaultValue: defaultValue)
    }
    
    class func getDeviceName(_ audioObjectID: AudioObjectID) -> String? {
        var name: CFString = "" as CFString

        let address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        let status: OSStatus = getPropertyData(audioObjectID, address: address, andValue: &name)

        return noErr == status ? (name as String) : nil
    }
    
    class func getPropertyData<T>(_ objectID: AudioObjectID, address: AudioObjectPropertyAddress, andValue value: inout T) -> OSStatus {
        var theAddress = address
        var size = UInt32(MemoryLayout<T>.size)
        let status = AudioObjectGetPropertyData(objectID, &theAddress, UInt32(0), nil, &size, &value)

        return status
    }
}

func size<T>(of value: T) -> UInt32 {
    return UInt32(MemoryLayout.size(ofValue: value))
}
