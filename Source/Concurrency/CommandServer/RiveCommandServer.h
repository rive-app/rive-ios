//  RiveCommandServer.h
//  RiveRuntime
//
//  Created by David Skuza on 5/14/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#ifndef RiveCommandServer_h
#define RiveCommandServer_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RiveCommandQueue;
@class RiveFactory;
@protocol _RiveUIRenderContextProtocol;

/**
 * @protocol RiveCommandServerProtocol
 *
 * Defines the Objective-C interface for the Rive command server, which
 * processes commands from a RiveCommandQueue on a background thread.
 *
 * The command server runs a processing loop that continuously dequeues and
 * executes commands from the associated command queue. This separation allows
 * the main thread to remain responsive while heavy operations (file loading,
 * artboard instantiation, rendering) execute asynchronously.
 *
 * Calling `serveUntilDisconnect` schedules the processing loop on an
 * SDK-managed background queue and returns immediately. The loop runs until
 * `disconnect` is called on the associated command queue.
 *
 * A command queue and render-context pair belong to exactly one command
 * server. Do not process the same pair with another server.
 */
NS_SWIFT_NAME(CommandServerProtocol)
@protocol RiveCommandServerProtocol

/**
 * Serves and processes commands until the server is disconnected.
 *
 * This method schedules the command server's processing loop and returns
 * immediately. The loop continuously processes commands from the associated
 * command queue until `disconnect` is called. Calls made while a loop is
 * scheduled or running have no effect.
 *
 * The method may be called from the main thread; it dispatches the blocking
 * processing loop internally. Retain the server until the associated command
 * queue disconnects.
 */
- (void)serveUntilDisconnect;

@end

/**
 * @class RiveCommandServer
 *
 * A concrete implementation of RiveCommandServerProtocol that processes
 * commands from a RiveCommandQueue on a background thread.
 *
 * The server uses its render context to import resources and render submitted
 * frames while processing its command queue.
 *
 * Threading model:
 * - Commands are submitted from the Swift main actor (or Objective-C main
 *   thread) via RiveCommandQueue
 * - `serveUntilDisconnect` schedules command processing on an internal
 *   background queue and returns
 * - Each server processes its own command queue serially
 * - Responses are forwarded through the command queue's listener and message
 *   delivery mechanisms
 */
NS_SWIFT_NAME(CommandServer)
@interface RiveCommandServer : NSObject <RiveCommandServerProtocol>

/**
 * Initializes a new RiveCommandServer instance.
 *
 * @param commandQueue The command queue from which to process commands
 * @param renderContext The render context used for drawing Rive graphics
 * @return An initialized RiveCommandServer instance
 *
 * @note The server retains both objects. They must belong to the same command-
 *       processing pipeline and must not be served by another command server.
 */
- (instancetype)initWithCommandQueue:(RiveCommandQueue*)commandQueue
                       renderContext:
                           (id<_RiveUIRenderContextProtocol>)renderContext;

@end

NS_ASSUME_NONNULL_END

#endif /* RiveCommandServer_h */
