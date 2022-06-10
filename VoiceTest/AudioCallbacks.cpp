//
//  AudioCallbacks.cpp
//  VoiceTest
//
//  Created by John Nastos on 6/10/22.
//

#include "AudioCallbacks.hpp"

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
    printf("\n");
    
    return noErr;
}

OSStatus AudioUnitPlayoutCallback(void* _Nonnull inRefCon,
                                        AudioUnitRenderActionFlags*  _Nonnull ioActionFlags,
                                        const AudioTimeStamp* _Nonnull inTimeStamp,
                                        UInt32 inBusNumber,
                                        UInt32 inNumberFrames,
                                  AudioBufferList* _Nullable ioData) {
    CustomAudioContext* context = reinterpret_cast<CustomAudioContext*>(inRefCon);
    
    printf("Playback\n");
    
    return noErr;
}
