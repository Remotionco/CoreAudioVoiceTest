//
//  Devices+Formats.swift
//  VoiceTest
//
//  Created by John Nastos on 6/10/22.
//

import Foundation

struct DeviceType {
    var isMicrophone: Bool
    var isSpeaker: Bool
}

// For getting devices
extension DeviceManager {
    public class func allDevices() -> [(name: String, id: AudioObjectID, deviceType: DeviceType)] {
        return allDeviceIDs().map { (name: getDeviceName($0) ?? "Unknown - \($0)",
                                     id: $0,
                                     getDeviceType(objectID: $0)
        ) }
    }
    
    class func allDeviceIDs() -> [AudioObjectID] {
        let address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let systemObjectID = AudioObjectID(kAudioObjectSystemObject)
        var allIDs = [AudioObjectID]()
        let status: OSStatus = getPropertyDataArray(systemObjectID, address: address, value: &allIDs, andDefaultValue: 0)

        return noErr == status ? allIDs : []
    }
    
    class func getSampleRateForDevice(_ objectID: AudioObjectID) -> Float64 {
        var kNominalSampleRateAddress: AudioObjectPropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyNominalSampleRate, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var size = UInt32(MemoryLayout<Float64>.size)
        var value: Float64 = 0.0
        let status = AudioObjectGetPropertyData(objectID, &kNominalSampleRateAddress, UInt32(0), nil, &size, &value)
        if status != noErr {
            assertionFailure("Error: \(status)")
        }
        return value
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
            mElement: kAudioObjectPropertyElementMain
        )

        let status: OSStatus = getPropertyData(audioObjectID, address: address, andValue: &name)

        return noErr == status ? (name as String) : nil
    }
    
    class func getPropertyData<T>(_ objectID: AudioObjectID,
                                  address: AudioObjectPropertyAddress,
                                  andValue value: inout T) -> OSStatus {
        var theAddress = address
        var size = UInt32(MemoryLayout<T>.size)
        let status = AudioObjectGetPropertyData(objectID, &theAddress, UInt32(0), nil, &size, &value)

        return status
    }
    
    class func getDeviceType(objectID: AudioObjectID) -> DeviceType {
        var deviceType: DeviceType = DeviceType(isMicrophone: false, isSpeaker: false)
        
        var inputAddress: AudioObjectPropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var status: OSStatus = noErr
        var dataSize: UInt32 = 0
        status = AudioObjectGetPropertyDataSize(objectID,
                                                    &inputAddress,
                                                    0,
                                                    nil,
                                                    &dataSize)
        
        if status != noErr {
            assertionFailure("Error")
            return deviceType
        }
        
        var streamCount: UInt32 = 0
        streamCount = dataSize / 4
        
        if streamCount > 0 {
            deviceType.isMicrophone = true
        }
        
        var outputAddress: AudioObjectPropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        dataSize = 0
        
        status = AudioObjectGetPropertyDataSize(objectID,
                                                &outputAddress,
                                                0,
                                                nil,
                                                &dataSize)
        if status != noErr {
            assertionFailure("Error")
            return deviceType
        }
        
        streamCount = dataSize / 4
        if streamCount > 0 {
            deviceType.isSpeaker = true
        }
        
        return deviceType
    }
}

class FormatManager {
    class func makeAudioStreamBasicDescription(sampleRate: Float64) -> AudioStreamBasicDescription {
        var audioStreamBasicDescription = AudioStreamBasicDescription()

        audioStreamBasicDescription.mSampleRate = sampleRate
        audioStreamBasicDescription.mFormatID = kAudioFormatLinearPCM

        audioStreamBasicDescription.mFormatFlags = kAudioFormatFlagIsFloat
            | kAudioFormatFlagsNativeEndian
            | kAudioFormatFlagIsPacked
            | kAudioFormatFlagIsNonInterleaved

        audioStreamBasicDescription.mChannelsPerFrame = 1
        audioStreamBasicDescription.mFramesPerPacket = 1
        audioStreamBasicDescription.mBitsPerChannel = 32
        audioStreamBasicDescription.mBytesPerFrame = audioStreamBasicDescription.mBitsPerChannel / 8 * audioStreamBasicDescription.mChannelsPerFrame
        audioStreamBasicDescription.mBytesPerPacket = audioStreamBasicDescription.mBytesPerFrame * audioStreamBasicDescription.mFramesPerPacket

        return audioStreamBasicDescription
    }
}

func size<T>(of value: T) -> UInt32 {
    return UInt32(MemoryLayout.size(ofValue: value))
}
