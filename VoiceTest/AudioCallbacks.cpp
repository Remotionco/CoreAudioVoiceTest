//
//  AudioCallbacks.cpp
//  VoiceTest
//
//  Created by John Nastos on 6/10/22.
//

#include "AudioCallbacks.hpp"

OSStatus AudioUnitRecordingCallback(void* _Nonnull inRefCon,
                                    AudioUnitRenderActionFlags*  _Nonnull ioActionFlags,
                                    const AudioTimeStamp* _Nonnull inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList* _Nullable ioData) {
    
    printf("Callback at %f\n", inTimeStamp->mSampleTime);
    
    return noErr;
}
