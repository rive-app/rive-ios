// Copyright © 2026 Rive. All rights reserved.

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

/// Records presentation and submission while forwarding to a real Metal buffer.
@interface PresentationCommandBufferRecorder : NSObject
- (instancetype)initWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer;
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic, readonly) id<MTLCommandBuffer> commandBuffer;
@property(nonatomic, readonly) NSUInteger timedPresentationCount;
@property(nonatomic, readonly) NSUInteger untimedPresentationCount;
@property(nonatomic, readonly) NSUInteger commitCount;
@property(nonatomic, readonly) CFTimeInterval presentationTime;
@property(nonatomic, weak, readonly, nullable) id<MTLDrawable>
    presentedDrawable;
@end

/// Wraps the buffer created by the legacy renderer's injectable command queue.
@interface PresentationCommandQueueRecorder : NSObject
- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic, readonly) id<MTLCommandQueue> commandQueue;
@property(nonatomic, readonly, nullable)
    PresentationCommandBufferRecorder* lastCommandBufferRecorder;
@end

NS_ASSUME_NONNULL_END
