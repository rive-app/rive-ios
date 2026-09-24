//
//  BlobListener.h
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

#ifndef BlobListener_h
#define BlobListener_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @protocol RiveBlobListener
 *
 * Protocol defining the interface for objects that receive asynchronous
 * notifications about blob decoding operations from the command queue.
 *
 * This protocol follows the observer pattern: you provide an observer object
 * implementing this protocol when decoding blobs (e.g.,
 * decodeBlob:listener:requestID:). The command queue will call the appropriate
 * methods on your observer when decoding completes, fails, or the blob is
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
NS_SWIFT_NAME(BlobListener)
@protocol RiveBlobListener <NSObject>

- (void)onBlobDecoded:(uint64_t)blobHandle requestID:(uint64_t)requestID;

- (void)onBlobError:(uint64_t)blobHandle
          requestID:(uint64_t)requestID
            message:(NSString*)message;

- (void)onBlobDeleted:(uint64_t)blobHandle requestID:(uint64_t)requestID;

@end

NS_ASSUME_NONNULL_END

#endif /* BlobListener_h */
