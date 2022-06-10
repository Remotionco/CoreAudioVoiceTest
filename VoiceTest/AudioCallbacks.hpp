//
//  AudioCallbacks.hpp
//  VoiceTest
//
//  Created by John Nastos on 6/10/22.
//

#ifndef AudioCallbacks_hpp
#define AudioCallbacks_hpp

#include <AudioToolbox/AudioToolbox.h>
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CustomAudioContext {
    void* _Nullable inputBuffer;
} CustomAudioContext;

OSStatus AudioUnitRecordingCallback(void* _Nonnull inRefCon,
                                    AudioUnitRenderActionFlags*  _Nonnull ioActionFlags,
                                    const AudioTimeStamp* _Nonnull inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList* _Nullable ioData);



#ifdef __cplusplus
}
#endif

#endif /* AudioCallbacks_hpp */
