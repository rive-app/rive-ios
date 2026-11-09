// Copyright © 2026 Rive. All rights reserved.

#import "PresentationRecorder.h"

@implementation PresentationCommandBufferRecorder
{
  id<MTLCommandBuffer> _wrappedCommandBuffer;
}

- (instancetype)initWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
  if ((self = [super init]))
  {
    _wrappedCommandBuffer = commandBuffer;
  }
  return self;
}

- (id<MTLCommandBuffer>)commandBuffer
{
  // Only the methods below are intercepted; Metal encoding forwards unchanged.
  return (id<MTLCommandBuffer>)self;
}

- (id)forwardingTargetForSelector:(SEL)selector
{
  return _wrappedCommandBuffer;
}

- (BOOL)respondsToSelector:(SEL)selector
{
  return [super respondsToSelector:selector] ||
         [_wrappedCommandBuffer respondsToSelector:selector];
}

- (void)presentDrawable:(id<MTLDrawable>)drawable
{
  ++_untimedPresentationCount;
  _presentedDrawable = drawable;
  [_wrappedCommandBuffer presentDrawable:drawable];
}

- (void)presentDrawable:(id<MTLDrawable>)drawable
                 atTime:(CFTimeInterval)presentationTime
{
  ++_timedPresentationCount;
  _presentedDrawable = drawable;
  _presentationTime = presentationTime;
  [_wrappedCommandBuffer presentDrawable:drawable atTime:presentationTime];
}

- (void)commit
{
  ++_commitCount;
  [_wrappedCommandBuffer commit];
}

@end

@implementation PresentationCommandQueueRecorder
{
  id<MTLCommandQueue> _wrappedCommandQueue;
}

- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
  if ((self = [super init]))
  {
    _wrappedCommandQueue = commandQueue;
  }
  return self;
}

- (id<MTLCommandQueue>)commandQueue
{
  return (id<MTLCommandQueue>)self;
}

- (id)forwardingTargetForSelector:(SEL)selector
{
  return _wrappedCommandQueue;
}

- (BOOL)respondsToSelector:(SEL)selector
{
  return [super respondsToSelector:selector] ||
         [_wrappedCommandQueue respondsToSelector:selector];
}

- (id<MTLCommandBuffer>)commandBuffer
{
  id<MTLCommandBuffer> buffer = [_wrappedCommandQueue commandBuffer];
  if (buffer == nil)
  {
    return nil;
  }
  _lastCommandBufferRecorder = [[PresentationCommandBufferRecorder alloc]
      initWithCommandBuffer:buffer];
  return _lastCommandBufferRecorder.commandBuffer;
}

@end
