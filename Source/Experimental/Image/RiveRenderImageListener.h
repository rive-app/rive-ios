//
//  RenderImageListener.h
//  RiveRuntime
//
//  Created by David Skuza on 12/2/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#ifndef RenderImageListener_h
#define RenderImageListener_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @protocol RiveRenderImageListener
 *
 * Protocol defining the interface for objects that receive asynchronous
 * notifications about image decoding operations from the command queue.
 *
 * This protocol follows the observer pattern: you provide an observer object
 * implementing this protocol when decoding images (e.g.,
 * decodeImage:listener:requestID:). The command queue will call the appropriate
 * methods on your observer when decoding completes, fails, or the image is
 * deleted.
 *
 * Request ID correlation:
 * Each command queue operation accepts a requestID parameter. When the
 * operation completes, the corresponding listener method is called with the
 * same requestID. Use this to correlate requests with responses.
 *
 * Threading:
 * Listener methods are typically called on the main thread, but this is
 * implementation-dependent. Ensure your implementations are thread-safe.
 */
NS_SWIFT_NAME(RenderImageListener)
@protocol RiveRenderImageListener <NSObject>

- (void)onRenderImageDecoded:(uint64_t)renderImageHandle
                   requestID:(uint64_t)requestID;

- (void)onRenderImageError:(uint64_t)renderImageHandle
                 requestID:(uint64_t)requestID
                   message:(NSString*)message;

- (void)onRenderImageDeleted:(uint64_t)renderImageHandle
                   requestID:(uint64_t)requestID;

@end

NS_ASSUME_NONNULL_END

#endif /* RenderImageListener_h */
