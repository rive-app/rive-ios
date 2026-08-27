//
//  RiveUIRenderContext.h
//  RiveRuntime
//
//  Created by David Skuza on 9/10/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MTLCommandBuffer;
@protocol MTLDevice;
@protocol _RiveUIRenderContextProtocol;

/// The immediate render context for one Metal rendering pipeline.
///
/// This object owns an immediate Rive GPU render context and a Metal command
/// queue for one device.
///
/// A context is pipeline-scoped. Do not share it between command-processing
/// pipelines or use it concurrently from multiple command servers. Textures
/// rendered through this context must be created by the device supplied at
/// initialization.
///
/// Threading:
/// - Command buffers should be created on the thread where they are encoded
/// - Worker rendering creates them on the serialized command-server thread
@interface RiveUIRenderContext : NSObject <_RiveUIRenderContextProtocol>

/// Creates an immediate context dedicated to `device`.
- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Creates a new Metal command buffer for rendering operations.
 *
 * This method returns a command buffer that can be used to encode Metal
 * rendering commands. The command buffer is associated with the render
 * context's Metal device.
 *
 * @return A new Metal command buffer ready for encoding commands
 * @note A direct caller must commit the returned buffer. Call this method on
 *       the thread that will encode and commit the commands, normally the
 *       command-server thread.
 */
- (id<MTLCommandBuffer>)newCommandBuffer;
@end

NS_ASSUME_NONNULL_END
