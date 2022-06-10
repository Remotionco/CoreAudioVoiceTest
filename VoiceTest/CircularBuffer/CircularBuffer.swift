//
//  CircularBuffer.swift
//  VoiceTest
//
//  Created by John Nastos on 6/10/22.
//

import Foundation

var blockDurationMs = 10
let maxBlocksPerBuffer = 3

final class CircularBuffer {
    static func calculateSamplesPerBlock(sampleRate: Float64) -> Int {
        return Int(sampleRate) * blockDurationMs / 1000
    }
    
    static func calculateBytesPerBlock(sampleRate: Float64, bytesPerSample: Int) -> Int {
        return calculateSamplesPerBlock(sampleRate: sampleRate) * bytesPerSample
    }
    
    static func calculateSize(sampleRate: Float64) -> Int {
        return calculateBytesPerBlock(sampleRate: sampleRate, bytesPerSample: 4) * maxBlocksPerBuffer
    }

    static func makeCircularBuffer(sampleRate: Float64) -> UnsafeMutableRawPointer {
        return CircularBufferCreate(Int32(calculateSize(sampleRate: sampleRate)), true)
    }

    static func destroy(_ buffer: UnsafeMutableRawPointer?) {
        if let buffer = buffer {
            CircularBufferDestroy(buffer)
        }
    }
}
