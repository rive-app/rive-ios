//
//  RiveUIRenderer.mm
//  RiveRuntime
//
//  Created by David Skuza on 9/9/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import "RiveUIRenderer.h"
#import "RiveUIRenderer_Private.hh"
#import <RiveRuntime/_RiveUIRenderContextProtocol.h>
#import "RiveUIRenderContext.h"

#include "rive/renderer/metal/render_context_metal_impl.h"
#include "rive/renderer/rive_renderer.hpp"

NS_ASSUME_NONNULL_BEGIN

@implementation RiveUIRenderer
{
    _RiveUIRendererCore* _core;
    NSError* _rendererError;
}

- (instancetype)initWithCommandQueue:(id<RiveCommandQueueProtocol>)commandQueue
                       renderContext:(RiveUIRenderContext*)renderContext
{
    if (self = [super init])
    {
        _core = [[_RiveUIRendererCore alloc]
            initWithCommandQueue:commandQueue
                   renderContext:renderContext
                  hasPendingWork:nil
                       drawFrame:^id<MTLCommandBuffer>(
                           rive::ArtboardInstance* artboard,
                           rive::gpu::RenderTargetMetal* renderTarget,
                           id<MTLTexture> texture,
                           RiveUIRendererConfiguration configuration) {
                         auto riveContext = [renderContext renderContext];
                         renderTarget->setTargetTexture(texture);
                         riveContext->beginFrame(
                             rive::gpu::RenderContext::FrameDescriptor{
                                 .renderTargetWidth = renderTarget->width(),
                                 .renderTargetHeight = renderTarget->height(),
                                 .loadAction = rive::gpu::LoadAction::clear,
                                 .clearColor = configuration.color});

                         auto renderer = rive::RiveRenderer(riveContext);
                         RiveUIDrawArtboard(
                             &renderer, artboard, renderTarget, configuration);

                         id<MTLCommandBuffer> commandBuffer =
                             [renderContext newCommandBuffer];
                         riveContext->flush({
                             .renderTarget = renderTarget,
                             .externalCommandBuffer =
                                 (__bridge void*)commandBuffer,
                         });
                         return commandBuffer;
                       }];
    }
    return self;
}

#if defined(RIVE_CANVAS) && defined(RIVE_ORE)
- (instancetype)initWithRendererError:(NSError*)rendererError
{
    if (self = [super init])
    {
        _rendererError = rendererError;
    }
    return self;
}
#endif

- (BOOL)reportRendererError:(nullable void (^)(NSError*))onError
{
    if (!_rendererError)
    {
        return NO;
    }
    if (onError)
    {
        onError(_rendererError);
    }
    return YES;
}

- (id<_RiveUIRenderContextProtocol>)renderContext
{
    return _core.renderContext;
}

- (void)drawConfiguration:(RiveUIRendererConfiguration)configuration
                toTexture:(id<MTLTexture>)texture
               fromDevice:(id<MTLDevice>)device
                   onDraw:(void (^)(id<MTLCommandBuffer>))onDraw
                onSkipped:(nullable void (^)(void))onSkipped
                  onError:(nullable void (^)(NSError* _Nonnull))onError
{
    if ([self reportRendererError:onError])
    {
        return;
    }
    [_core
        drawConfiguration:configuration
                toTexture:texture
               fromDevice:device
                   onDraw:^(id<MTLCommandBuffer> commandBuffer) {
                     onDraw(commandBuffer);
                     RiveUIRendererCommitCommandBufferIfNeeded(commandBuffer);
                   }
                onSkipped:onSkipped
                  onError:onError];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)drawConfiguration:(RiveUIRendererConfiguration)configuration
                toTexture:(id<MTLTexture>)texture
               fromDevice:(id<MTLDevice>)device
                 finalize:(nullable void (^)(id<MTLCommandBuffer>))finalize
                onSkipped:(nullable void (^)(void))onSkipped
                  onError:(nullable void (^)(NSError* _Nonnull))onError
{
    if ([self reportRendererError:onError])
    {
        return;
    }
    [_core drawConfiguration:configuration
                   toTexture:texture
                  fromDevice:device
                      onDraw:^(id<MTLCommandBuffer> commandBuffer) {
                        RiveUIRendererInvokeLegacyFinalize(finalize,
                                                           commandBuffer);
                      }
                   onSkipped:onSkipped
                     onError:onError];
}
#pragma clang diagnostic pop

@end

NS_ASSUME_NONNULL_END
