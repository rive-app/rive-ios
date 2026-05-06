//
//  _RiveUIRenderer.m
//  RiveRuntime
//
//  Created by David Skuza on 9/9/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import "RiveUIRenderer.h"
#import <RiveRuntime/RiveConcurrency.h>
#import <RiveRuntime/RiveCommandQueue.h>
#import <RiveRuntime/RiveRuntime-Swift.h>
#import <RiveRuntime/RiveUIRenderContext.h>
#include "rive/command_server.hpp"
#include "rive/renderer/metal/render_context_metal_impl.h"
#include "rive/renderer/rive_renderer.hpp"
#include "rive/animation/state_machine_instance.hpp"

NS_ASSUME_NONNULL_BEGIN

static rive::Fit RiveConfigurationFitCppValue(RiveConfigurationFit fit)
{
    switch (fit)
    {
        case RiveConfigurationFitFill:
            return rive::Fit::fill;
        case RiveConfigurationFitContain:
            return rive::Fit::contain;
        case RiveConfigurationFitCover:
            return rive::Fit::cover;
        case RiveConfigurationFitFitWidth:
            return rive::Fit::fitWidth;
        case RiveConfigurationFitFitHeight:
            return rive::Fit::fitHeight;
        case RiveConfigurationFitNone:
            return rive::Fit::none;
        case RiveConfigurationFitScaleDown:
            return rive::Fit::scaleDown;
        case RiveConfigurationFitLayout:
            return rive::Fit::layout;
    }
}

static rive::Alignment RiveConfigurationAlignmentCppValue(
    RiveConfigurationAlignment alignment)
{
    switch (alignment)
    {
        case RiveConfigurationAlignmentTopLeft:
            return rive::Alignment::topLeft;
        case RiveConfigurationAlignmentTopCenter:
            return rive::Alignment::topCenter;
        case RiveConfigurationAlignmentTopRight:
            return rive::Alignment::topRight;
        case RiveConfigurationAlignmentCenterLeft:
            return rive::Alignment::centerLeft;
        case RiveConfigurationAlignmentCenter:
            return rive::Alignment::center;
        case RiveConfigurationAlignmentCenterRight:
            return rive::Alignment::centerRight;
        case RiveConfigurationAlignmentBottomLeft:
            return rive::Alignment::bottomLeft;
        case RiveConfigurationAlignmentBottomCenter:
            return rive::Alignment::bottomCenter;
        case RiveConfigurationAlignmentBottomRight:
            return rive::Alignment::bottomRight;
    }
}

@implementation RiveUIRenderer
{
    id<RiveCommandQueueProtocol> _commandQueue;
    rive::rcp<rive::gpu::RenderTargetMetal> _renderTarget;
    RiveUIRenderContext* _renderContext;
    uint64_t _drawKey;
}

- (instancetype)initWithCommandQueue:(id<RiveCommandQueueProtocol>)commandQueue
                       renderContext:(nonnull RiveUIRenderContext*)renderContext
{
    if (self = [super init])
    {
        _commandQueue = commandQueue;
        _renderContext = renderContext;
        _drawKey = [commandQueue createDrawKey];
    }
    return self;
}

- (void)dealloc
{
    _renderTarget = nullptr;
}

- (rive::rcp<rive::gpu::RenderTargetMetal>)renderTarget
{
    // Does this need a lock, in case this renderer gets dealloc'd before a
    // frame draws?
    return _renderTarget;
}

- (void)setRenderTarget:(rive::rcp<rive::gpu::RenderTargetMetal>)renderTarget
{
    _renderTarget = renderTarget;
}

- (RiveUIRenderContext*)renderContext
{
    return _renderContext;
}

- (void)drawConfiguration:(RiveUIRendererConfiguration)configuration
                toTexture:(id<MTLTexture>)texture
               fromDevice:(id<MTLDevice>)device
                 finalize:(nullable void (^)(id<MTLCommandBuffer>))finalize
                onSkipped:(nullable void (^)(void))onSkipped
                  onError:(nullable void (^)(NSError* _Nonnull))onError
{
    BOOL (^CGSizeWithinRange)(CGSize, CGSize) =
        ^BOOL(CGSize size, CGSize maxSize) {
          BOOL isWidthValid = size.width > 0 && size.width <= maxSize.width;
          BOOL isHeightValid = size.height > 0 && size.height <= maxSize.height;
          return isWidthValid && isHeightValid;
        };

    // CGSizeWithinRange checks for width > 0 && height > 0,
    // so negative-width, 0-width, negative-height, 0-height,
    // and > max texture size are all accounted for.
    if (!CGSizeWithinRange(configuration.size,
                           CGSizeMaximum2DTextureSize(device)))
    {
        NSError* invalidSize = [NSError
            errorWithDomain:@"app.rive.renderer"
                       code:RendererErrorInvalidSize
                   userInfo:@{
                       NSLocalizedDescriptionKey : [NSString
                           stringWithFormat:@"Cannot draw size {%f, %f}",
                                            configuration.size.width,
                                            configuration.size.height]
                   }];
        if (onError)
        {
            onError(invalidSize);
        }
    }

    __weak RiveUIRenderer* weakSelf = self;

    // The draw callback is bridged into a C++ std::function via
    // RiveCommandQueue. When the C++ side destroys the std::function,
    // ARC may not release the block's captured ObjC objects. Use __block
    // variables and nil them explicitly after use so Metal resources
    // (textures, drawables) are freed immediately.
    __block id<MTLTexture> blockTexture = texture;
    __block void (^blockFinalize)(id<MTLCommandBuffer>) = finalize;
    __block void (^blockOnSkipped)(void) = onSkipped;
    __block void (^blockOnError)(NSError*) = onError;

    [_commandQueue
            draw:_drawKey
        callback:^(void* cppServer) {
          // Ensure autoreleased ObjC objects produced by the nil-outs
          // and Metal teardown drain immediately rather than waiting for
          // the GCD-level pool to drain.
          @autoreleasepool
          {
              void (^cleanup)(void) = ^{
                blockTexture = nil;
                blockFinalize = nil;
                blockOnSkipped = nil;
                blockOnError = nil;
              };

              __strong RiveUIRenderer* strongSelf = weakSelf;
              if (!strongSelf)
              {
                  NSError* invalidRenderer =
                      [NSError errorWithDomain:@"app.rive.renderer"
                                          code:RendererErrorInvalidRenderer
                                      userInfo:@{
                                          NSLocalizedDescriptionKey :
                                              @"Invalid renderer for drawing."
                                      }];
                  if (blockOnError)
                  {
                      blockOnError(invalidRenderer);
                  }
                  cleanup();
                  return;
              }
              auto server = static_cast<rive::CommandServer*>(cppServer);
              auto artboard = server->getArtboardInstance(
                  reinterpret_cast<rive::ArtboardHandle>(
                      configuration.artboardHandle));
              if (artboard == nullptr)
              {
                  NSError* invalidArtboard = [NSError
                      errorWithDomain:@"app.rive.renderer"
                                 code:RendererErrorInvalidArtboard
                             userInfo:@{
                                 @"artboard" : @(configuration.artboardHandle),
                                 NSLocalizedDescriptionKey :
                                     @"Attempted to draw with invalid artboard."
                             }];
                  if (blockOnError)
                  {
                      blockOnError(invalidArtboard);
                  }
                  cleanup();
                  return;
              }

              // When the render target is missing or stale (first draw, or the
              // viewport resized) we must still render so the newly-sized
              // drawable gets populated and presented. Otherwise MTKView keeps
              // presenting the previous drawable stretched to its new bounds —
              // which is what happens for non-layout fits, where the artboard's
              // own state doesn't change on resize and `didChange()` returns
              // false.
              auto renderTarget = strongSelf.renderTarget;
              BOOL renderTargetNeedsResize =
                  renderTarget == nullptr ||
                  renderTarget->width() != configuration.size.width ||
                  renderTarget->height() != configuration.size.height;

              if (renderTargetNeedsResize == NO &&
                  artboard->didChange() == false)
              {
                  if (blockOnSkipped)
                  {
                      blockOnSkipped();
                  }
                  if (renderTarget)
                  {
                      renderTarget->setTargetTexture(nil);
                  }
                  cleanup();
                  return;
              }

              auto stateMachine = server->getStateMachineInstance(
                  reinterpret_cast<rive::StateMachineHandle>(
                      configuration.stateMachineHandle));
              if (stateMachine == nullptr)
              {
                  NSError* invalidStateMachine = [NSError
                      errorWithDomain:@"app.rive.renderer"
                                 code:RendererErrorInvalidStateMachine
                             userInfo:@{
                                 @"stateMachine" :
                                     @(configuration.stateMachineHandle),
                                 NSLocalizedDescriptionKey :
                                     @"Attempted to draw with invalid "
                                     @"state machine."
                             }];
                  if (blockOnError)
                  {
                      blockOnError(invalidStateMachine);
                  }
                  if (renderTarget)
                  {
                      renderTarget->setTargetTexture(nil);
                  }
                  cleanup();
                  return;
              }

              auto riveContext =
                  static_cast<rive::gpu::RenderContext*>(server->factory());

              auto metalContext =
                  riveContext
                      ->static_impl_cast<rive::gpu::RenderContextMetalImpl>();
              if (renderTargetNeedsResize)
              {
                  renderTarget = metalContext->makeRenderTarget(
                      MTLRiveColorPixelFormat(),
                      (uint32_t)configuration.size.width,
                      (uint32_t)configuration.size.height);
                  strongSelf.renderTarget = renderTarget;
              }
              renderTarget->setTargetTexture(blockTexture);

              riveContext->beginFrame(rive::gpu::RenderContext::FrameDescriptor{
                  .renderTargetWidth = renderTarget->width(),
                  .renderTargetHeight = renderTarget->height(),
                  .loadAction = rive::gpu::LoadAction::clear,
                  .clearColor = configuration.color});

              auto renderer = rive::RiveRenderer(riveContext);
              renderer.align(
                  RiveConfigurationFitCppValue(configuration.fit),
                  RiveConfigurationAlignmentCppValue(configuration.alignment),
                  rive::AABB(0.0f,
                             0.0f,
                             renderTarget->width(),
                             renderTarget->height()),
                  artboard->bounds(),
                  configuration.layoutScale);

              artboard->draw(&renderer);

              id<MTLCommandBuffer> commandBuffer =
                  [strongSelf.renderContext newCommandBuffer];
              riveContext->flush(
                  {.renderTarget = strongSelf.renderTarget.get(),
                   .externalCommandBuffer = (__bridge void*)commandBuffer});

              if (blockFinalize)
              {
                  blockFinalize(commandBuffer);
              }

              renderTarget->setTargetTexture(nil);
              cleanup();
          }
        }];
}

@end

NS_ASSUME_NONNULL_END
