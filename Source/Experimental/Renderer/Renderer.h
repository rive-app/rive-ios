//
//  _RiveUIRenderer.h
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
@class RiveRenderContext;

/// Configuration structure for rendering a Rive artboard to a Metal texture.
///
/// This structure contains all the parameters needed to draw an artboard,
/// including which artboard and state machine to use, how to fit and align
/// it, the target texture format, and display scale.
///
/// The renderer uses this configuration to set up the coordinate transformation
/// from artboard space to screen space, which affects both rendering and
/// pointer event handling.
typedef struct
{
    /// The handle of the artboard to render. Must be a valid artboard handle
    /// created via the command queue.
    uint64_t artboardHandle;

    /// The handle of the state machine to advance and render. Must be a valid
    /// state machine handle created from the artboard. Use 0 if no state
    /// machine should be advanced (static artboard rendering).
    uint64_t stateMachineHandle;

    /// How the artboard should be fitted within the target size.
    RiveConfigurationFit fit;

    /// How the artboard should be aligned when there's extra space.
    RiveConfigurationAlignment alignment;

    /// The target size in points for rendering. This is the logical size
    /// before applying the scale factor.
    CGSize size;

    /// The Metal pixel format for the target texture. Must match the format
    /// of the texture passed to
    /// drawConfiguration:toTexture:finalize:onError:.
    MTLPixelFormat pixelFormat;

    /// The display scale factor (e.g., 2.0 for Retina displays). This affects
    /// the actual pixel resolution of the rendered output.
    CGFloat layoutScale;

    /// The background color in ARGB format (32-bit unsigned integer).
    uint32_t color;
} RendererConfiguration;

/// A renderer that draws Rive artboards to Metal textures.
///
/// The Renderer class coordinates the drawing of Rive artboards to Metal
/// textures. It works with a command queue to schedule drawing operations
/// and uses a render context to create Metal command buffers.
///
/// The renderer handles coordinate transformations based on the fit and
/// alignment settings, advances state machines if specified, and executes the
/// actual drawing commands on a background thread.
///
/// Threading:
/// - Drawing operations are queued on the main thread
/// - Actual rendering happens on a background thread (via command server)
/// - Error and finalize callbacks are called on the background thread
NS_SWIFT_NAME(Renderer)
@interface Renderer : NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 * Initializes a renderer with a command queue and render context.
 *
 * @param commandQueue The command queue used to schedule drawing operations
 * @param renderContext The render context used to create Metal command buffers
 * @return An initialized renderer instance
 * @note The command queue must be started before using the renderer. The render
 *       context must be valid and associated with a Metal device.
 */
- (instancetype)initWithCommandQueue:(id<RiveCommandQueueProtocol>)commandQueue
                       renderContext:(nonnull RiveRenderContext*)renderContext;

/**
 * Draws an artboard configuration to a Metal texture.
 *
 * This method queues a drawing operation that will render the specified
 * artboard to the provided Metal texture. The operation is asynchronous and
 * executes on a background thread via the command server.
 *
 * The configuration determines which artboard to draw, how to fit and align it,
 * and what size and pixel format to use.
 *
 * @param configuration The rendering configuration (artboard, fit, alignment,
 * etc.)
 * @param texture The Metal texture to render to. Must match the pixel format
 *                specified in the configuration.
 * @param finalize A block called after drawing completes, receiving the Metal
 *                 command buffer. Use this to commit the buffer or perform
 * cleanup. Can be nil. Any objects captured by this block (e.g.,
 * CAMetalDrawable) will be automatically retained by ARC until the block is
 * released.
 * @param onError A block called if drawing fails, receiving an NSError
 * describing the failure. Can be nil.
 * @note The texture must be a valid Metal texture with the correct pixel
 * format. The drawing operation is queued and executes asynchronously. The
 * finalize and onError blocks are called on the background thread.
 */
- (void)drawConfiguration:(RendererConfiguration)configuration
                toTexture:(id<MTLTexture>)texture
                 finalize:(nullable void (^)(id<MTLCommandBuffer>))finalize
                  onError:(nullable void (^)(NSError*))onError;

@end

NS_ASSUME_NONNULL_END

#endif /* Renderer_h */
