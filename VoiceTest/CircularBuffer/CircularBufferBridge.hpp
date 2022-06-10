//
//  CircularBuffer.hpp
//  Remotion
//
//  Created by Fernando Barbat on 8/31/20.
//  Copyright © 2020 GroupUp Inc. All rights reserved.
//

#ifndef CircularBuffer_hpp
#define CircularBuffer_hpp

#ifdef __cplusplus
extern "C" {
#endif
    
// This module is just a C++ wrapper with C bindings of TPCircularBuffer.
// It only supports it's creation/destruction but not it's usage. This is enough for our needs, we just need to set it up from Swift
// and then let it run in C++.
// We need to do this in order to guarantee that atomic library is the same (the C++ version, <atomic>) no matter how it is imported.
// It seems it was working anyways but we don't have strong guarantees about that to be the case in the future, so we need this wrapper.
void* CircularBufferCreate(int length, bool atomic);
void CircularBufferDestroy(void* buffer);

#ifdef __cplusplus
}
#endif

#endif /* CircularBuffer_hpp */
