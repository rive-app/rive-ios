// Copyright © 2026 Rive. All rights reserved.

#import "RecordingRenderContext.h"
#import "RiveUIRenderer_Private.hh"

#if defined(RIVE_CANVAS) && defined(RIVE_ORE)

#include "rive/artboard.hpp"
#include "rive/renderer/cmd/deferred_session.hpp"

@interface RecordingRenderContext ()
@property(nonatomic, readonly) rive::cmd::DeferredSession* session;
@end

@interface RecordingRenderer : _RiveUIRendererCore <RiveUIRendererProtocol>
@end

@implementation RecordingRenderContext
{
  std::unique_ptr<rive::cmd::DeferredSession> _session;
  id<MTLCommandQueue> _metalQueue;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
  if (self = [super init])
  {
    _metalQueue = [device newCommandQueue];
  }
  return self;
}

- (id<RiveUIRendererProtocol>)makeRendererWithCommandQueue:
    (id<RiveCommandQueueProtocol>)commandQueue
{
  return [[RecordingRenderer alloc]
      initWithCommandQueue:commandQueue
             renderContext:self
            hasPendingWork:^BOOL {
              return self.checksPendingWork &&
                     self.session->recordedThisFrame();
            }];
}

- (rive::Factory*)beginCommandProcessing
{
  assert(_session == nullptr);
  _session = std::make_unique<rive::cmd::DeferredSession>(
      rive::ore::ReplayCaps{});
  return _session.get();
}

- (void)endCommandProcessing
{
  _session.reset();
}

- (rive::cmd::DeferredSession*)session
{
  return _session.get();
}

- (rive::gpu::RenderContext*)renderContext
{
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:@"Recording tests must not access a GPU context"
               userInfo:nil];
}

- (id<MTLCommandBuffer>)newCommandBuffer
{
  return [_metalQueue commandBuffer];
}

@end

@implementation RecordingRenderer

- (BOOL)recreateRenderTarget:(RiveUIRendererConfiguration)configuration
{
  return NO; // Fixed output: no target changes during this test.
}

- (id<MTLCommandBuffer>)drawArtboard:(rive::ArtboardInstance*)artboard
                           toTexture:(id<MTLTexture>)texture
                       configuration:(RiveUIRendererConfiguration)configuration
{
  auto* session = ((RecordingRenderContext*)self.renderContext).session;
  artboard->draw(session->screenRenderer());
  session->resetFrame();
  return [self.renderContext newCommandBuffer];
}

- (void)drawConfiguration:(RiveUIRendererConfiguration)configuration
                toTexture:(id<MTLTexture>)texture
               fromDevice:(id<MTLDevice>)device
                   onDraw:(void (^)(id<MTLCommandBuffer>))onDraw
                onSkipped:(void (^)(void))onSkipped
                  onError:(void (^)(NSError*))onError
{
  [super drawConfiguration:configuration
                 toTexture:texture
                fromDevice:device
                    onDraw:^(id<MTLCommandBuffer> buffer) {
                      onDraw(buffer);
                      RiveUIRendererCommitCommandBufferIfNeeded(buffer);
                    }
                 onSkipped:onSkipped
                   onError:onError];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)drawConfiguration:(RiveUIRendererConfiguration)configuration
                toTexture:(id<MTLTexture>)texture
               fromDevice:(id<MTLDevice>)device
                 finalize:(void (^)(id<MTLCommandBuffer>))finalize
                onSkipped:(void (^)(void))onSkipped
                  onError:(void (^)(NSError*))onError
{
  [super drawConfiguration:configuration
                 toTexture:texture
                fromDevice:device
                    onDraw:^(id<MTLCommandBuffer> buffer) {
                      RiveUIRendererInvokeLegacyFinalize(finalize, buffer);
                    }
                 onSkipped:onSkipped
                   onError:onError];
}
#pragma clang diagnostic pop

@end

#endif
