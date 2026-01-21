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
@class RiveRenderContext;

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
 * The server must be started on a background thread and will run until
 * disconnect() is called on the associated command queue. Multiple command
 * servers can process commands from the same queue, though typically only
 * one is needed.
 */
NS_SWIFT_NAME(CommandServerProtocol)
@protocol RiveCommandServerProtocol

/**
 * Serves and processes commands until the server is disconnected.
 *
 * This method starts the command server's main processing loop, which
 * continuously processes commands from the associated command queue until
 * disconnect is called.
 *
 * @note This method should be called on a background thread to avoid blocking
 *       the main UI thread.
 */
- (void)serveUntilDisconnect;

@end

/**
 * @class RiveCommandServer
 *
 * A concrete implementation of RiveCommandServerProtocol that processes
 * commands from a RiveCommandQueue on a background thread.
 *
 * The command server wraps a C++ command server that executes Rive operations
 * (file loading, artboard creation, state machine advancement, etc.) and
 * delivers results back through listener protocols. It uses the provided
 * RiveRenderContext to create render resources and execute drawing commands.
 *
 * Threading model:
 * - Commands are queued from the main thread via RiveCommandQueue
 * - The server processes commands on a background thread (via
 * serveUntilDisconnect)
 * - Responses are delivered to listeners, typically on the main thread
 *
 * @note The command server should be started on a background thread to
 *       maintain UI responsiveness. Use dispatch_async to a background queue
 *       when calling serveUntilDisconnect.
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
 * @note The command queue and factory must be valid and properly initialized
 *       before creating the command server.
 */
- (instancetype)initWithCommandQueue:(RiveCommandQueue*)commandQueue
                       renderContext:(RiveRenderContext*)renderContext;

@end

NS_ASSUME_NONNULL_END

#endif /* RiveCommandServer_h */
