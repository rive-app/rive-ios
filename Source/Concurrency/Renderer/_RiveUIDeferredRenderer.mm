//
//  _RiveUIDeferredRenderer.mm
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

#import <RiveRuntime/RiveUIRenderer.h>
#import "_RiveUIDeferredRenderer.h"

#if defined(RIVE_CANVAS) && defined(RIVE_ORE)

#import "RiveUIRenderer_Private.hh"
#import <RiveRuntime/_RiveUIRenderContextProtocol.h>
#import <RiveRuntime/_RiveUIDeferredRenderContext.h>

#include "rive/renderer/cmd/deferred_host.hpp"
#include "rive/renderer/metal/render_context_metal_impl.h"
#include "rive/renderer/rive_renderer.hpp"

#include <memory>
#include <utility>

NS_ASSUME_NONNULL_BEGIN

namespace
{
/// Supplies Apple screen-target hooks while `DeferredReplayer` executes one
/// recorded frame on the real context. `DeferredInlineHost::screenRenderer()`
/// returns the session-owned `DeferredRenderer` that records commands; this
/// sink's `m_renderer` is the short-lived real `RiveRenderer` that executes
/// screen commands during replay. The borrowed context and owned target,
/// texture, and renderer remain valid until synchronous replay returns. The
/// surrounding draw pipeline owns screen flush, presentation, and commit.
class RiveUIFrameSink final : public rive::cmd::HostFrameSink
{
public:
    RiveUIFrameSink(rive::gpu::RenderContext* renderContext,
                    rive::rcp<rive::gpu::RenderTargetMetal> renderTarget,
                    id<MTLTexture> texture,
                    bool clear,
                    uint32_t color,
                    uint64_t target,
                    bool replayOre) :
        HostFrameSink(clear, color, target, replayOre),
        m_renderContext(renderContext),
        m_renderTarget(std::move(renderTarget)),
        m_texture(texture)
    {}

    rive::gpu::RenderContext* renderContext() override
    {
        return m_renderContext;
    }

    rive::Renderer* beginScreen(uint64_t, bool clear, uint32_t color) override
    {
        m_renderTarget->setTargetTexture(m_texture);
        m_renderContext->beginFrame({
            .renderTargetWidth = m_renderTarget->width(),
            .renderTargetHeight = m_renderTarget->height(),
            .loadAction = clear ? rive::gpu::LoadAction::clear
                                : rive::gpu::LoadAction::preserveRenderTarget,
            .clearColor = color,
        });
        m_renderer = std::make_unique<rive::RiveRenderer>(m_renderContext);
        return m_renderer.get();
    }

private:
    rive::gpu::RenderContext* m_renderContext;
    rive::rcp<rive::gpu::RenderTargetMetal> m_renderTarget;
    id<MTLTexture> m_texture;
    std::unique_ptr<rive::RiveRenderer> m_renderer;
};
} // namespace

@implementation _RiveUIDeferredRenderer
{
    _RiveUIRendererCore* _core;
}

- (instancetype)initWithCommandQueue:(id<RiveCommandQueueProtocol>)commandQueue
                       renderContext:
                           (_RiveUIDeferredRenderContext*)renderContext
{
    if (self = [super init])
    {
        _core = [[_RiveUIRendererCore alloc] initWithCommandQueue:commandQueue
            renderContext:renderContext
            hasPendingWork:^BOOL {
              auto host = [renderContext deferredHost];
              // Sample before `drawFrame` calls beginRecord. beginRecord adds
              // an Ore replay marker and would otherwise make every request
              // appear dirty, defeating unchanged-frame skipping.
              return host->session()->recordedThisFrame();
            }
            drawFrame:^id<MTLCommandBuffer> _Nullable(
                rive::ArtboardInstance* artboard,
                rive::gpu::RenderTargetMetal* renderTarget,
                id<MTLTexture> texture,
                RiveUIRendererConfiguration configuration) {
              auto host = [renderContext deferredHost];
              auto riveContext = [renderContext renderContext];

              host->beginRecord(true, configuration.color);
              RiveUIDrawArtboard(host->screenRenderer(),
                                 artboard,
                                 renderTarget,
                                 configuration);

              RiveUIFrameSink sink(riveContext,
                                   rive::ref_rcp(renderTarget),
                                   texture,
                                   host->doClear(),
                                   host->clearColor(),
                                   host->target(),
                                   host->replayOre());
              id<MTLCommandBuffer> commandBuffer =
                  [renderContext newCommandBuffer];
              void* externalCommandBuffer = (__bridge void*)commandBuffer;
              BOOL didEncodeScreen = NO;
              // replayInline replays and resets the pending frame before this
              // callback. By then the screen frame is encoded, so flush here.
              host->replayInline(sink, [&] {
                  riveContext->flush({
                      .renderTarget = renderTarget,
                      .externalCommandBuffer = externalCommandBuffer,
                  });
                  didEncodeScreen = YES;
              });
              return didEncodeScreen ? commandBuffer : nil;
            }];
    }
    return self;
}

- (void)drawConfiguration:(RiveUIRendererConfiguration)configuration
                toTexture:(id<MTLTexture>)texture
               fromDevice:(id<MTLDevice>)device
                   onDraw:(void (^)(id<MTLCommandBuffer>))onDraw
                onSkipped:(nullable void (^)(void))onSkipped
                  onError:(nullable void (^)(NSError*))onError
{
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
                  onError:(nullable void (^)(NSError*))onError
{
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

#endif // RIVE_CANVAS && RIVE_ORE
