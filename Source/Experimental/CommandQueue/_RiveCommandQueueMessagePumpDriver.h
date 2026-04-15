//
//  _RiveCommandQueueMessagePump.h
//  RiveRuntime
//
//  Internal command queue message pump protocol.
//

#ifndef _RiveCommandQueueMessagePumpDriver_h
#define _RiveCommandQueueMessagePumpDriver_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(_CommandQueueMessagePumpDriver)
@protocol _RiveCommandQueueMessagePumpDriver

- (void)startMessageProcessing;
- (void)stopMessageProcessing;

@end

NS_ASSUME_NONNULL_END

#endif /* _RiveCommandQueueMessagePumpDriver_h */
