//
//  RiveUIRenderer_Private.hh
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

#ifndef RiveUIRenderer_Private_hh
#define RiveUIRenderer_Private_hh

#import <RiveRuntime/RiveUIRenderer.h>

namespace rive
{
class ArtboardInstance;
class Renderer;
namespace gpu
{
class RenderTargetMetal;
}
} // namespace rive

NS_ASSUME_NONNULL_BEGIN

@protocol _RiveUIRenderContextProtocol;

/// Reports backend-wide work that is not represented by
/// `ArtboardInstance::didChange`. When the target, configuration, and artboard
/// are otherwise unchanged, this is queried without consuming the work on the
/// serialized command-server thread before deciding to skip.
typedef BOOL (^_RiveUIRendererHasPendingWorkBlock)(void);

/// Encodes one frame on the serialized command-server thread. Returns an
/// uncommitted command buffer, or nil when the backend consumed work without
/// producing a visible screen frame.
typedef id<MTLCommandBuffer> _Nullable (^_RiveUIRendererDrawFrameBlock)(
    rive::ArtboardInstance* artboard,
    rive::gpu::RenderTargetMetal* renderTarget,
    id<MTLTexture> texture,
    RiveUIRendererConfiguration configuration);

/// Per-output-surface scheduling, validation, and cache core shared by the
/// immediate and deferred renderer adapters.
///
/// Submission originates on the Swift main actor (or Objective-C main thread).
/// Its mutable render-target and last-drawn-configuration state is accessed
/// by the command queue's serialized draw callbacks, with final render-target
/// teardown in `dealloc`. A unique draw key lets newer submissions replace
/// older pending work for this surface.
///
/// The core retains its queue, context, and backend blocks. Its queued draw
/// directly captures the core weakly and holds the submitted texture and
/// terminal blocks until execution, coalescing, or queue teardown discards it.
@interface _RiveUIRendererCore : NSObject

/// The worker-scoped context retained by this core.
@property(nonatomic, readonly) id<_RiveUIRenderContextProtocol> renderContext;

- (instancetype)
    initWithCommandQueue:(id<RiveCommandQueueProtocol>)commandQueue
           renderContext:(id<_RiveUIRenderContextProtocol>)renderContext
          hasPendingWork:
              (nullable _RiveUIRendererHasPendingWorkBlock)hasPendingWork
               drawFrame:(_RiveUIRendererDrawFrameBlock)drawFrame;

- (instancetype)init NS_UNAVAILABLE;

/// Validates and queues a draw. An executed submission takes exactly one
/// success, skip, or error path and invokes that path's block when supplied. A
/// submission discarded by coalescing or queue teardown invokes no block.
- (void)drawConfiguration:(RiveUIRendererConfiguration)configuration
                toTexture:(id<MTLTexture>)texture
               fromDevice:(id<MTLDevice>)device
                   onDraw:(void (^)(id<MTLCommandBuffer>))onDraw
                onSkipped:(nullable void (^)(void))onSkipped
                  onError:(nullable void (^)(NSError*))onError;

@end

/// Applies the shared fit/alignment transform, then draws the artboard through
/// either a real renderer or a deferred recording renderer.
void RiveUIDrawArtboard(rive::Renderer* _Nonnull renderer,
                        rive::ArtboardInstance* _Nonnull artboard,
                        rive::gpu::RenderTargetMetal* _Nonnull renderTarget,
                        RiveUIRendererConfiguration configuration);

/// Called immediately after `onDraw` returns. Commits a buffer in the
/// `NotEnqueued` or `Enqueued` state; otherwise does nothing.
void RiveUIRendererCommitCommandBufferIfNeeded(
    id<MTLCommandBuffer> _Nonnull commandBuffer);

/// Preserves the deprecated finalizer contract: a supplied block owns the
/// commit, while a nil block commits automatically.
void RiveUIRendererInvokeLegacyFinalize(
    void (^_Nullable finalize)(id<MTLCommandBuffer>),
    id<MTLCommandBuffer> _Nonnull commandBuffer);

NS_ASSUME_NONNULL_END

#endif /* RiveUIRenderer_Private_hh */
