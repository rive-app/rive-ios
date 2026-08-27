//
//  RiveUIRenderer_Private.mm
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

#import "RiveUIRenderer_Private.hh"

#import <RiveRuntime/RiveCommandQueue.h>
#import <RiveRuntime/RiveRuntime-Swift.h>
#import <RiveRuntime/_RiveUIRenderContextProtocol.h>

#include <optional>

#include "../Utilities/RiveConfiguration_Private.hh"
#include "rive/animation/state_machine_instance.hpp"
#include "rive/artboard.hpp"
#include "rive/command_server.hpp"
#include "rive/renderer/metal/render_context_metal_impl.h"
#include "rive/renderer/rive_renderer.hpp"

NS_ASSUME_NONNULL_BEGIN

void RiveUIDrawArtboard(rive::Renderer* renderer,
                        rive::ArtboardInstance* artboard,
                        rive::gpu::RenderTargetMetal* renderTarget,
                        RiveUIRendererConfiguration configuration)
{
    renderer->align(
        RiveConfigurationFitCppValue(configuration.fit),
        RiveConfigurationAlignmentCppValue(configuration.alignment),
        rive::AABB(0.0f, 0.0f, renderTarget->width(), renderTarget->height()),
        artboard->bounds(),
        configuration.layoutScale);
    artboard->draw(renderer);
}

void RiveUIRendererCommitCommandBufferIfNeeded(
    id<MTLCommandBuffer> commandBuffer)
{
    MTLCommandBufferStatus status = commandBuffer.status;
    if (status == MTLCommandBufferStatusNotEnqueued ||
        status == MTLCommandBufferStatusEnqueued)
    {
        [commandBuffer commit];
    }
}

void RiveUIRendererInvokeLegacyFinalize(
    void (^_Nullable finalize)(id<MTLCommandBuffer>),
    id<MTLCommandBuffer> commandBuffer)
{
    if (finalize)
    {
        finalize(commandBuffer);
    }
    else
    {
        [commandBuffer commit];
    }
}

static NSError* _Nullable RiveUIRendererValidateSize(
    RiveUIRendererConfiguration configuration, id<MTLDevice> device)
{
    CGSize maximumSize = CGSizeMaximum2DTextureSize(device);
    bool sizeIsValid = configuration.size.width > 0 &&
                       configuration.size.width <= maximumSize.width &&
                       configuration.size.height > 0 &&
                       configuration.size.height <= maximumSize.height;
    if (sizeIsValid)
    {
        return nil;
    }

    return [NSError
        errorWithDomain:@"app.rive.renderer"
                   code:RendererErrorInvalidSize
               userInfo:@{
                   NSLocalizedDescriptionKey :
                       [NSString stringWithFormat:@"Cannot draw size {%f, %f}",
                                                  configuration.size.width,
                                                  configuration.size.height]
               }];
}

static NSError* _Nullable RiveUIRendererValidateTexture(
    RiveUIRendererConfiguration configuration,
    id<MTLTexture> texture,
    id<MTLDevice> device)
{
    CGSize textureSize = CGSizeMake(texture.width, texture.height);
    bool textureIsValid = CGSizeEqualToSize(configuration.size, textureSize) &&
                          configuration.pixelFormat == texture.pixelFormat &&
                          (texture.usage & MTLTextureUsageRenderTarget) != 0 &&
                          texture.device == device;
    if (textureIsValid)
    {
        return nil;
    }

    return [NSError errorWithDomain:@"app.rive.renderer"
                               code:RendererErrorInvalidTexture
                           userInfo:@{
                               NSLocalizedDescriptionKey :
                                   @"Target texture does not match the "
                                   @"renderer configuration or device."
                           }];
}

static NSError* _Nullable RiveUIRendererValidateInstance(id _Nullable renderer)
{
    if (renderer)
    {
        return nil;
    }

    return [NSError
        errorWithDomain:@"app.rive.renderer"
                   code:RendererErrorInvalidRenderer
               userInfo:@{
                   NSLocalizedDescriptionKey : @"Invalid renderer for drawing."
               }];
}

static NSError* _Nullable RiveUIRendererValidateArtboard(
    rive::ArtboardInstance* _Nullable artboard,
    RiveUIRendererConfiguration configuration)
{
    if (artboard)
    {
        return nil;
    }

    return [NSError errorWithDomain:@"app.rive.renderer"
                               code:RendererErrorInvalidArtboard
                           userInfo:@{
                               @"artboard" : @(configuration.artboardHandle),
                               NSLocalizedDescriptionKey :
                                   @"Attempted to draw with invalid artboard."
                           }];
}

static NSError* _Nullable RiveUIRendererValidateStateMachine(
    rive::StateMachineInstance* _Nullable stateMachine,
    RiveUIRendererConfiguration configuration)
{
    if (stateMachine)
    {
        return nil;
    }

    return [NSError
        errorWithDomain:@"app.rive.renderer"
                   code:RendererErrorInvalidStateMachine
               userInfo:@{
                   @"stateMachine" : @(configuration.stateMachineHandle),
                   NSLocalizedDescriptionKey :
                       @"Attempted to draw with invalid state machine."
               }];
}

static bool RiveUIRendererResizeRenderTargetIfNeeded(
    rive::gpu::RenderContext* renderContext,
    RiveUIRendererConfiguration configuration,
    rive::rcp<rive::gpu::RenderTargetMetal>& renderTarget)
{
    bool renderTargetNeedsResize =
        renderTarget == nullptr ||
        renderTarget->width() != configuration.size.width ||
        renderTarget->height() != configuration.size.height ||
        renderTarget->pixelFormat() != configuration.pixelFormat;
    if (renderTargetNeedsResize)
    {
        auto metalContext =
            renderContext
                ->static_impl_cast<rive::gpu::RenderContextMetalImpl>();
        renderTarget =
            metalContext->makeRenderTarget(configuration.pixelFormat,
                                           (uint32_t)configuration.size.width,
                                           (uint32_t)configuration.size.height);
    }
    return renderTargetNeedsResize;
}

static bool RiveUIRendererConfigurationEqualToConfiguration(
    RiveUIRendererConfiguration lhs, RiveUIRendererConfiguration rhs)
{
    return lhs.artboardHandle == rhs.artboardHandle &&
           lhs.stateMachineHandle == rhs.stateMachineHandle &&
           lhs.fit == rhs.fit && lhs.alignment == rhs.alignment &&
           CGSizeEqualToSize(lhs.size, rhs.size) &&
           lhs.pixelFormat == rhs.pixelFormat &&
           lhs.layoutScale == rhs.layoutScale && lhs.color == rhs.color;
}

@implementation _RiveUIRendererCore
{
    id<RiveCommandQueueProtocol> _commandQueue;
    id<_RiveUIRenderContextProtocol> _renderContext;
    rive::rcp<rive::gpu::RenderTargetMetal> _renderTarget;
    uint64_t _drawKey;
    _RiveUIRendererHasPendingWorkBlock _hasPendingWork;
    _RiveUIRendererDrawFrameBlock _drawFrame;
    std::optional<RiveUIRendererConfiguration> _lastDrawnConfiguration;
}

- (instancetype)
    initWithCommandQueue:(id<RiveCommandQueueProtocol>)commandQueue
           renderContext:(id<_RiveUIRenderContextProtocol>)renderContext
          hasPendingWork:
              (nullable _RiveUIRendererHasPendingWorkBlock)hasPendingWork
               drawFrame:(_RiveUIRendererDrawFrameBlock)drawFrame
{
    if (self = [super init])
    {
        _commandQueue = commandQueue;
        _renderContext = renderContext;
        _drawKey = [commandQueue createDrawKey];
        _hasPendingWork = [hasPendingWork copy];
        _drawFrame = [drawFrame copy];
    }
    return self;
}

- (void)dealloc
{
    // Release C++ render-target resources while `_renderContext` is still
    // retained and its real GPU context is valid.
    _renderTarget = nullptr;
}

- (id<_RiveUIRenderContextProtocol>)renderContext
{
    return _renderContext;
}

- (void)drawConfiguration:(RiveUIRendererConfiguration)configuration
                toTexture:(id<MTLTexture>)texture
               fromDevice:(id<MTLDevice>)device
                   onDraw:(void (^)(id<MTLCommandBuffer>))onDraw
                onSkipped:(nullable void (^)(void))onSkipped
                  onError:(nullable void (^)(NSError*))onError
{
    if (NSError* sizeError = RiveUIRendererValidateSize(configuration, device))
    {
        if (onError)
        {
            onError(sizeError);
        }
        return;
    }

    if (NSError* textureError =
            RiveUIRendererValidateTexture(configuration, texture, device))
    {
        if (onError)
        {
            onError(textureError);
        }
        return;
    }

    __weak _RiveUIRendererCore* weakSelf = self;
    // C++ owns the callback until execution, replacement, or destruction.
    // Shared `__block` slots let an executed path promptly release its
    // Objective-C captures.
    __block id<MTLTexture> blockTexture = texture;
    __block void (^blockOnDraw)(id<MTLCommandBuffer>) = onDraw;
    __block void (^blockOnSkipped)(void) = onSkipped;
    __block void (^blockOnError)(NSError*) = onError;

    [_commandQueue
            draw:_drawKey
        callback:^(void* cppServer) {
          // The command server's enclosing GCD work item lives until worker
          // disconnect. Bound Objective-C and Metal autoreleases to this draw.
          @autoreleasepool
          {
              void (^cleanup)(void) = ^{
                blockTexture = nil;
                blockOnDraw = nil;
                blockOnSkipped = nil;
                blockOnError = nil;
              };

              __strong _RiveUIRendererCore* strongSelf = weakSelf;
              if (NSError* rendererError =
                      RiveUIRendererValidateInstance(strongSelf))
              {
                  if (blockOnError)
                  {
                      blockOnError(rendererError);
                  }
                  cleanup();
                  return;
              }

              auto server = static_cast<rive::CommandServer*>(cppServer);
              auto artboard = server->getArtboardInstance(
                  reinterpret_cast<rive::ArtboardHandle>(
                      configuration.artboardHandle));
              if (NSError* artboardError =
                      RiveUIRendererValidateArtboard(artboard, configuration))
              {
                  if (blockOnError)
                  {
                      blockOnError(artboardError);
                  }
                  cleanup();
                  return;
              }

              auto stateMachine = server->getStateMachineInstance(
                  reinterpret_cast<rive::StateMachineHandle>(
                      configuration.stateMachineHandle));
              if (NSError* stateMachineError =
                      RiveUIRendererValidateStateMachine(stateMachine,
                                                         configuration))
              {
                  if (blockOnError)
                  {
                      blockOnError(stateMachineError);
                  }
                  cleanup();
                  return;
              }

              auto riveContext = [strongSelf->_renderContext renderContext];
              bool renderTargetWasResized =
                  RiveUIRendererResizeRenderTargetIfNeeded(
                      riveContext, configuration, strongSelf->_renderTarget);
              bool configurationDidChange =
                  !strongSelf->_lastDrawnConfiguration.has_value() ||
                  !RiveUIRendererConfigurationEqualToConfiguration(
                      configuration, *strongSelf->_lastDrawnConfiguration);
              if (!renderTargetWasResized && !configurationDidChange &&
                  !artboard->didChange() &&
                  !(strongSelf->_hasPendingWork &&
                    strongSelf->_hasPendingWork()))
              {
                  if (blockOnSkipped)
                  {
                      blockOnSkipped();
                  }
                  cleanup();
                  return;
              }

              id<MTLCommandBuffer> commandBuffer =
                  strongSelf->_drawFrame(artboard,
                                         strongSelf->_renderTarget.get(),
                                         blockTexture,
                                         configuration);
              // The cached target is renderer-scoped, not texture-scoped.
              // Detach the submitted drawable after encoding so the renderer
              // does not retain it across frames; Metal retains resources used
              // by the encoded command buffer.
              strongSelf->_renderTarget->setTargetTexture(nil);
              if (commandBuffer)
              {
                  strongSelf->_lastDrawnConfiguration = configuration;
                  blockOnDraw(commandBuffer);
              }
              else if (blockOnSkipped)
              {
                  blockOnSkipped();
              }
              cleanup();
          }
        }];
}

@end

NS_ASSUME_NONNULL_END
