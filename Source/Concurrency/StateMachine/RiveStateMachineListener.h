//
//  RiveStateMachineListener.h
//  RiveRuntime
//
//  Created by David Skuza on 2/19/26.
//

#ifndef RiveStateMachineListener_h
#define RiveStateMachineListener_h

#import <Foundation/Foundation.h>

@class RiveSemanticsDiff;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(StateMachineListener)
@protocol RiveStateMachineListener <NSObject>

- (void)onStateMachineError:(uint64_t)stateMachineHandle
                  requestID:(uint64_t)requestID
                    message:(NSString*)message;

- (void)onStateMachineDeleted:(uint64_t)stateMachineHandle
                    requestID:(uint64_t)requestID;

- (void)onStateMachineSettled:(uint64_t)stateMachineHandle
                    requestID:(uint64_t)requestID;

- (void)onSemanticsDiffReceived:(uint64_t)stateMachineHandle
                      requestID:(uint64_t)requestID
                           diff:(RiveSemanticsDiff*)diff;

@end

NS_ASSUME_NONNULL_END

#endif /* RiveStateMachineListener_h */
