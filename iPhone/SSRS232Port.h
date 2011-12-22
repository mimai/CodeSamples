//
//  SSRS232Port.h
//  ArduinoConsole
//
//  Created by Michael Imai on 11-12-13.
//  Copyright (c) 2011 Michael Imai. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RscMgr.h"

#include "TPCircularBuffer.h"

@interface SSRS232Port : NSObject
<
RscMgrDelegate
>
{
    RscMgr *_redparkSerialControlManager;
    
    int _bytesAvailable;
    TPCircularBuffer _circularBuffer;
}

@property (readonly) int bytesAvailable;

+ (void)initialize;
+ (id)sharedSSRS232Port;

// read write serial bytes
- (int) write:(UInt8 *)data length:(UInt32)numberOfBytesToSend;
- (int) read:(UInt8 *)data bufferLength:(UInt32)bufferLength;

@end
