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

/// A render context that provides Metal command buffers for rendering.
///
/// The render context abstracts the creation of Metal command buffers used
/// for rendering Rive content. It's associated with a Metal device and provides
/// a factory for creating Rive render resources.
///
/// The render context is used by both the Renderer (for drawing operations)
/// and the RiveCommandServer (for processing render commands from the queue).
///
/// Threading:
/// - Command buffers should be created on the thread where they'll be used
/// - Typically, this is the background thread where the command server runs
@interface RiveRenderContext : NSObject

/**
 * Creates a new Metal command buffer for rendering operations.
 *
 * This method returns a command buffer that can be used to encode Metal
 * rendering commands. The command buffer is associated with the render
 * context's Metal device.
 *
 * @return A new Metal command buffer ready for encoding commands
 * @note The command buffer must be committed (via commit) to execute the
 * commands. This method should be called on the thread that will encode and
 * commit the commands (typically the command server's background thread).
 */
- (id<MTLCommandBuffer>)newCommandBuffer;
@end

NS_ASSUME_NONNULL_END
