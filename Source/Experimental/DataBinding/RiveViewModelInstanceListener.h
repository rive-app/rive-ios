//
//  RiveViewModelInstanceListener.h
//  RiveRuntime
//
//  Created by David Skuza on 11/19/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#ifndef RiveViewModelInstanceListener_h
#define RiveViewModelInstanceListener_h

#import <Foundation/Foundation.h>

@class RiveViewModelInstanceData;

NS_ASSUME_NONNULL_BEGIN

/**
 * @protocol RiveViewModelInstanceListener
 *
 * Protocol defining the interface for objects that receive asynchronous
 * notifications about view model instance operations from the command queue.
 *
 * This protocol follows the observer pattern: you provide an observer object
 * implementing this protocol when creating view model instances or subscribing
 * to property changes. The command queue will call the appropriate methods
 * on your observer when operations complete or property values change.
 *
 * Request ID correlation:
 * Each command queue operation accepts a requestID parameter. When the
 * operation completes, the corresponding listener method is called with the
 * same requestID. Use this to correlate requests with responses.
 *
 * Property subscriptions:
 * When you subscribe to a property (via subscribeToViewModelProperty:), you
 * will receive onViewModelDataReceived: calls whenever that property changes.
 * This enables reactive updates in your application.
 *
 * Threading:
 * Listener methods are typically called on the main thread, but this is
 * implementation-dependent. Ensure your implementations are thread-safe.
 */
NS_SWIFT_NAME(ViewModelInstanceListener)
@protocol RiveViewModelInstanceListener <NSObject>

- (void)onViewModelDataReceived:(uint64_t)viewModelInstanceHandle
                      requestID:(uint64_t)requestID
                           data:(RiveViewModelInstanceData*)data;

- (void)onViewModelListSizeReceived:(uint64_t)viewModelInstanceHandle
                          requestID:(uint64_t)requestID
                               path:(NSString*)path
                               size:(NSInteger)size;

- (void)onViewModelInstanceNameReceived:(uint64_t)viewModelInstanceHandle
                              requestID:(uint64_t)requestID
                                   name:(NSString*)name;

@end

NS_ASSUME_NONNULL_END

#endif /* RiveViewModelInstanceListener_h */
