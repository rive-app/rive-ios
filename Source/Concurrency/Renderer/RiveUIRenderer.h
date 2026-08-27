//
//  RiveUIRenderer.h
//  RiveRuntime
//
//  Created by David Skuza on 9/9/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#ifndef Renderer_h
#define Renderer_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <RiveRuntime/RiveEnums.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RiveCommandQueueProtocol;
@protocol MTLTexture;
@protocol MTLCommandBuffer;
@protocol MTLDevice;
@class RiveUIRenderContext;

/// Configuration structure for rendering a Rive artboard to a Metal texture.
///
/// This structure contains all the parameters needed to draw an artboard,
/// including artboard and state-machine handles, layout, and target texture
/// properties.
///
/// The renderer uses this configuration to set up the coordinate transformation
/// from artboard space to screen space, which affects both rendering and
/// pointer event handling. Use the same fit, alignment, and layout scale when
/// mapping pointer events so input agrees with the rendered geometry.
typedef struct
{
    /// The handle of the artboard to render. Must be a valid, nonzero handle
    /// owned by the command queue that backs the renderer.
    uint64_t artboardHandle;

    /// The state-machine instance associated with the artboard. Must be a
    /// valid, nonzero handle created from the artboard and owned by the same
    /// command queue as the renderer.
    uint64_t stateMachineHandle;

    /// How the artboard should be fitted within the target size.
    RiveConfigurationFit fit;

    /// How the artboard should be aligned when there's extra space.
    RiveConfigurationAlignment alignment;

    /// The target texture dimensions in pixels. Width and height must be
    /// positive whole-pixel values, must match the supplied texture, and must
    /// not exceed `CGSizeMaximum2DTextureSize` for the supplied device.
    CGSize size;

    /// The Metal pixel format for the target texture. Must match the format
    /// of the texture passed to the renderer.
    MTLPixelFormat pixelFormat;

    /// The scale used by `RiveConfigurationFitLayout` to map layout
    /// coordinates to target pixels. This does not change `size` and is
    /// ignored by other fit modes.
    CGFloat layoutScale;

    /// The background color in ARGB format (32-bit unsigned integer).
    uint32_t color;
} RiveUIRendererConfiguration;

/// An interface for drawing Rive artboards to Metal textures.
///
/// Use ``Rive/makeRenderer()`` to create a renderer that matches the backing
/// worker's configuration.
///
/// A renderer keeps render-target and skip state for one output surface.
/// Retain one renderer per surface; drawable textures may rotate as long as
/// they belong to that same surface.
///
/// Submit only configurations whose handles belong to the renderer's command
/// queue. The texture and device must use the same Metal device as the
/// renderer's render context.
///
/// Call `drawConfiguration:toTexture:fromDevice:onDraw:onSkipped:onError:`
/// from the main actor in Swift, or the main thread in Objective-C. Preflight
/// errors, such as an invalid size, call `onError` synchronously on that
/// calling context. Otherwise, drawing is performed asynchronously on the
/// backing command-server thread, where `onDraw`, `onSkipped`, and `onError`
/// are called.
///
/// Pending submissions for one renderer may be coalesced. Only the most recent
/// submission for that renderer in a command-server batch is drawn; blocks
/// belonging to superseded submissions are released without being called.
@protocol RiveUIRendererProtocol <NSObject>

/**
 * Queues an artboard configuration to be drawn to a Metal texture.
 *
 * @param configuration The artboard, state machine, layout, and output
 *                      configuration to draw.
 * @param texture The Metal render-target texture. Its dimensions and pixel
 *                format must match the configuration, its usage must include
 *                `MTLTextureUsageRenderTarget`, and it must belong to the
 *                renderer's Metal device.
 * @param device The Metal device that owns the texture and backs the renderer's
 *               render context.
 * @param onDraw A required block called with the uncommitted command buffer
 *               after the draw commands have been recorded. Present the
 *               drawable, if needed, and configure any completion handlers
 *               from this block. If it remains uncommitted, the renderer
 *               commits it after the block returns. If the block commits it
 *               synchronously before returning, the renderer does not commit
 *               it again. Do not wait for it to be scheduled or completed, or
 *               retain it to configure or commit later.
 * @param onSkipped A block called when a frame is intentionally skipped. Can
 *                  be nil.
 * @param onError A block called with an error if drawing fails. Can be nil.
 */
- (void)drawConfiguration:(RiveUIRendererConfiguration)configuration
                toTexture:(id<MTLTexture>)texture
               fromDevice:(id<MTLDevice>)device
                   onDraw:(void (^)(id<MTLCommandBuffer>))onDraw
                onSkipped:(nullable void (^)(void))onSkipped
                  onError:(nullable void (^)(NSError*))onError;

/**
 * Queues an artboard configuration to be drawn to a Metal texture.
 *
 * All parameters other than `finalize` have the same requirements as the
 * `onDraw` overload.
 *
 * @param finalize A block called with the uncommitted command buffer after the
 *                 draw commands have been recorded. When nonnull, the block
 *                 must commit the command buffer. When nil, the renderer
 *                 commits it automatically.
 */
- (void)drawConfiguration:(RiveUIRendererConfiguration)configuration
                toTexture:(id<MTLTexture>)texture
               fromDevice:(id<MTLDevice>)device
                 finalize:(nullable void (^)(id<MTLCommandBuffer>))finalize
                onSkipped:(nullable void (^)(void))onSkipped
                  onError:(nullable void (^)(NSError*))onError
    DEPRECATED_MSG_ATTRIBUTE(
        "Use onDraw instead; the renderer commits after onDraw returns.");

@end

/// The immediate implementation of ``RiveUIRendererProtocol``.
///
/// Prefer ``Rive/makeRenderer()`` so the implementation matches the worker's
/// selected rendering mode.
@interface RiveUIRenderer : NSObject <RiveUIRendererProtocol>

- (instancetype)init NS_UNAVAILABLE;

/**
 * Initializes an immediate renderer with a command queue and render context.
 *
 * @param commandQueue The command queue used to schedule drawing operations
 * @param renderContext The render context used to create Metal command buffers
 * @return An initialized renderer instance
 * @note The renderer retains both objects. They must belong to the same active
 *       command-processing pipeline, and `renderContext` must be an immediate
 *       context. Use ``Rive/makeRenderer()`` for a worker configured for
 *       deferred rendering.
 *       Initialize on the Swift main actor or Objective-C main thread.
 */
- (instancetype)initWithCommandQueue:(id<RiveCommandQueueProtocol>)commandQueue
                       renderContext:(RiveUIRenderContext*)renderContext;

#if defined(RIVE_CANVAS) && defined(RIVE_ORE)
/// Creates a disabled renderer that reports `rendererError` from draw calls.
/// Used internally to preserve deprecated initializer behavior without pairing
/// an immediate renderer with a deferred context.
- (instancetype)initWithRendererError:(NSError*)rendererError
    NS_SWIFT_NAME(init(rendererError:));
#endif

- (void)drawConfiguration:(RiveUIRendererConfiguration)configuration
                toTexture:(id<MTLTexture>)texture
               fromDevice:(id<MTLDevice>)device
                   onDraw:(void (^)(id<MTLCommandBuffer>))onDraw
                onSkipped:(nullable void (^)(void))onSkipped
                  onError:(nullable void (^)(NSError*))onError;

- (void)drawConfiguration:(RiveUIRendererConfiguration)configuration
                toTexture:(id<MTLTexture>)texture
               fromDevice:(id<MTLDevice>)device
                 finalize:(nullable void (^)(id<MTLCommandBuffer>))finalize
                onSkipped:(nullable void (^)(void))onSkipped
                  onError:(nullable void (^)(NSError*))onError
    DEPRECATED_MSG_ATTRIBUTE(
        "Use onDraw instead; the renderer commits after onDraw returns.");

@end

NS_ASSUME_NONNULL_END

#endif /* Renderer_h */
