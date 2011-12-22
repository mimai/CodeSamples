//
//  SSRS232Port.m
//  ArduinoConsole
//
//  Created by Michael Imai on 11-12-13.
//  Copyright (c) 2011 Michael Imai. All rights reserved.
//

#import "SSRS232Port.h"

#import "LoggerClient.h"

#define kCircularBufferSize 2048
#define kReadBufferSize 512

@interface SSRS232Port ()
@property (nonatomic, strong) RscMgr *redparkSerialControlManager;

@property (readwrite) int bytesAvailable;
@property (readwrite) TPCircularBuffer circularBuffer;

@end

@implementation SSRS232Port

@synthesize redparkSerialControlManager = _redparkSerialControlManager;

@synthesize bytesAvailable = _bytesAvailable;
@synthesize circularBuffer = _circularBuffer;

static SSRS232Port *sharedInstance = nil; 

+ (void)initialize
{
    if (sharedInstance == nil) {
        sharedInstance = [[self alloc] init];
    }
}

+ (id)sharedSSRS232Port
{
    //Already set by +initialize.
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone*)zone
{
    //Usually already set by +initialize.
    if (sharedInstance) {
        //The caller expects to receive a new object, so implicitly retain it
        //to balance out the eventual release message.
        return [sharedInstance retain];
    } else {
        //When not already set, +initialize is our caller.
        //It's creating the shared instance, let this go through.
        return [super allocWithZone:zone];
    }
}


- (id) init
{
    self = [super init];
    if (nil != self) {
        TPCircularBufferInit(&_circularBuffer, kCircularBufferSize);

        _redparkSerialControlManager = [[RscMgr alloc] init]; 
        [_redparkSerialControlManager setDelegate:self];
    }
    
    return self;
}


- (void)dealloc {
    // Release buffer resources
    TPCircularBufferCleanup(&_circularBuffer);
    
    [super dealloc];
}


- (int) write:(UInt8 *)writeBuffer length:(UInt32)numberOfBytesToSend
{
    int numberOfBytesWritten = [_redparkSerialControlManager write:writeBuffer
                                                            Length:numberOfBytesToSend];
    
    return  numberOfBytesWritten;
}


- (int) read:(UInt8 *)data bufferLength:(UInt32)bufferLength
{
    int numberOfBytesRead = 0;
    
    SInt16 *rxBuffer = TPCircularBufferTail(&_circularBuffer, &numberOfBytesRead);
    int sampleCount = MIN(bufferLength, numberOfBytesRead);
    memcpy(data, rxBuffer, sampleCount);
    TPCircularBufferConsume(&_circularBuffer, sampleCount);
    _bytesAvailable -= sampleCount;
        
    return sampleCount;
}


#pragma mark - RscMgrDelegate Methods

// Redpark Serial Cable has been connected and/or application moved to foreground.
// protocol is the string which matched from the protocol list passed to initWithProtocol:
- (void) cableConnected:(NSString *)protocol
{
	LogMessage(@"SSRS232Port", 0, [NSString stringWithFormat:@"%s: %d", __FUNCTION__, __LINE__]);
    [_redparkSerialControlManager setBaud:9600];
	[_redparkSerialControlManager open];
}


// Redpark Serial Cable was disconnected and/or application moved to background
- (void) cableDisconnected
{
	LogMessage(@"SSRS232Port", 0, [NSString stringWithFormat:@"%s: %d", __FUNCTION__, __LINE__]);
}


// serial port status has changed
// user can call getModemStatus or getPortStatus to get current state
- (void) portStatusChanged
{
	LogMessage(@"SSRS232Port", 0, [NSString stringWithFormat:@"%s: %d", __FUNCTION__, __LINE__]);
}


// bytes are available to be read (user calls read:)
- (void) readBytesAvailable:(UInt32)numberOfBytesAvailable
{
    UInt8 rxBuffer[kReadBufferSize];
    
    int numberOfBytesRead = [_redparkSerialControlManager read:rxBuffer Length:kReadBufferSize];
    
    TPCircularBufferProduceBytes(&_circularBuffer, rxBuffer, numberOfBytesRead);
    self.bytesAvailable = _bytesAvailable + numberOfBytesRead;
}

@end
