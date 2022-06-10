//
//  AudioCallbacks.cpp
//  VoiceTest
//
//  Created by John Nastos on 6/10/22.
//

#include "AudioCallbacks.hpp"
#import "TPCircularBuffer.h"

float computeEnergy(float* samples, int sampleCount) {
    float energy = 0;
    
    for(int i = 0; i < sampleCount; i++) {
        energy += abs(samples[i]);
    }
    
    return energy;
}

OSStatus AudioUnitRecordingCallback(void* _Nonnull inRefCon,
                                    AudioUnitRenderActionFlags*  _Nonnull ioActionFlags,
                                    const AudioTimeStamp* _Nonnull inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList* _Nullable ioData) {
    
    CustomAudioContext* context = reinterpret_cast<CustomAudioContext*>(inRefCon);
    
    AudioBufferList inputAudioBufferList;
    inputAudioBufferList.mNumberBuffers = 1;
    inputAudioBufferList.mBuffers[0].mNumberChannels = 1;
    inputAudioBufferList.mBuffers[0].mDataByteSize = 0;
    inputAudioBufferList.mBuffers[0].mData = NULL;
    
    OSStatus status = AudioUnitRender(
        context->inputAudioUnit,
        ioActionFlags,
        inTimeStamp,
        inBusNumber,
        inNumberFrames,
        &inputAudioBufferList
    );
    
    if (status != noErr) {
        printf("Error! %i", status);
        return status;
    }
    
    float* buffer = reinterpret_cast<float*>(inputAudioBufferList.mBuffers[0].mData);
    UInt32 bufferSize = inputAudioBufferList.mBuffers[0].mDataByteSize;
    
    float magnitude = computeEnergy(buffer, bufferSize);
    
    printf("Callback at %f  ", inTimeStamp->mSampleTime);
    printf("Magnitude: %f  ", magnitude);
    printf("Frames: %i  ", inNumberFrames);
    printf("\n");
    
    TPCircularBuffer* inputCircularBuffer = reinterpret_cast<TPCircularBuffer*>(context->inputBuffer);
    

    uint32_t inputCircularBufferAvailableSpace;
    void* inputCircularBufferHead = TPCircularBufferHead(inputCircularBuffer, &inputCircularBufferAvailableSpace);
    
    if (inputCircularBufferAvailableSpace < bufferSize) {
        //statistics->inputCircularBufferOverflowCount++;
    } else {
        memcpy(inputCircularBufferHead, buffer, bufferSize);
        TPCircularBufferProduce(inputCircularBuffer, bufferSize);
    }
    
    return noErr;
}

OSStatus AudioUnitPlayoutCallback(void* _Nonnull inRefCon,
                                        AudioUnitRenderActionFlags*  _Nonnull ioActionFlags,
                                        const AudioTimeStamp* _Nonnull inTimeStamp,
                                        UInt32 inBusNumber,
                                        UInt32 inNumberFrames,
                                  AudioBufferList* _Nullable ioData) {
    CustomAudioContext* context = reinterpret_cast<CustomAudioContext*>(inRefCon);
    
    
    TPCircularBuffer* inputCircularBuffer = reinterpret_cast<TPCircularBuffer*>(context->inputBuffer);
    uint32_t availableBytes;
    void* buffer = TPCircularBufferTail(inputCircularBuffer, &availableBytes);
    
    UInt32 bytes = inNumberFrames * 4;
    
    if (availableBytes < bytes) {
        ioData->mBuffers[0].mDataByteSize = 0;
        *ioActionFlags = kAudioUnitRenderAction_OutputIsSilence;
    } else {
        memcpy(ioData->mBuffers[0].mData, buffer, bytes);
        TPCircularBufferConsume(inputCircularBuffer, bytes);
    }
    
    float* outBuffer = reinterpret_cast<float*>(ioData->mBuffers[0].mData);
    
    printf("Playback ");
    printf("Magnitude: %f", computeEnergy(outBuffer, inNumberFrames));
    //printf("Frames: %i  ", inNumberFrames);
    printf("\n");
    
    return noErr;
}
