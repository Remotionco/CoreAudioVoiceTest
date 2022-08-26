//
//  Formats.swift
//  VoiceTest
//
//  Created by John Nastos on 6/10/22.
//

import Foundation

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
