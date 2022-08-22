//
//  CircularBufferBridge.cpp
//  Remotion
//
//  Created by Fernando Barbat on 8/31/20.
//  Copyright © 2020 GroupUp Inc. All rights reserved.
//

#include "CircularBufferBridge.hpp"
#include "TPCircularBuffer.h"

void* CircularBufferCreate(int length, bool atomic){
    TPCircularBuffer* circularBuffer = new TPCircularBuffer();
    _TPCircularBufferInit(circularBuffer, length, sizeof(TPCircularBuffer));
    TPCircularBufferSetAtomic(circularBuffer, atomic);
    return reinterpret_cast<void*>(circularBuffer);
}

void CircularBufferDestroy(void* buffer){
    TPCircularBuffer* circularBuffer = reinterpret_cast<TPCircularBuffer*>(buffer);
    TPCircularBufferCleanup(circularBuffer);
    delete circularBuffer;
}
