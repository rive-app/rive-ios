//
//  RiveCommandServer.mm
//  RiveRuntime
//
//  Created by David Skuza on 5/14/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <RiveRuntime/RiveFactory.h>
#import <RiveRuntime/RiveCommandQueue.h>
#import <RiveRuntime/RenderContext.h>
#import <RiveRuntime/RiveRenderContext.h>
#import "RivePrivateHeaders.h"
#import "RiveExperimental_Private.hh"

NS_ASSUME_NONNULL_BEGIN

@implementation RiveCommandServer
{
    /** The underlying C++ command server that processes Rive commands */
    rive::CommandServer* _commandServer;
    /** The command queue from which commands are processed */
    RiveCommandQueue* _commandQueue;
    /** The render context used for drawing Rive graphics */
    RiveRenderContext* _renderContext;
    /** Flag indicating whether the server is currently connected and serving */
    BOOL _isConnected;
    /** Lock object for thread-safe access to the connection state */
    NSObject* _isConnectedLock;
}

/**
 * Initializes a new RiveCommandServer instance with the specified dependencies.
 *
 * This initializer creates a new C++ command server and sets up the connection
 * state tracking. The command server is configured to process commands from the
 * specified command queue using the provided render context.
 *
 * @param commandQueue The command queue from which to process commands
 * @param renderContext The render context used for drawing Rive graphics
 * @return An initialized RiveCommandServer instance
 */
- (instancetype)initWithCommandQueue:(RiveCommandQueue*)commandQueue
                       renderContext:(RiveRenderContext*)renderContext
{
    if (self = [super init])
    {
        _commandQueue = commandQueue;
        _renderContext = renderContext;
        _commandServer = new rive::CommandServer(commandQueue.commandQueue,
                                                 renderContext.factory);
        _isConnected = NO;
        _isConnectedLock = [[NSObject alloc] init];
    }
    return self;
}

/**
 * Cleans up resources when the command server is deallocated.
 */
- (void)dealloc
{
    delete _commandServer;
}

/**
 * Starts the command server's main processing loop.
 *
 * This method initiates the command server's background processing loop,
 * which continuously processes commands from the associated command queue
 * until the server is disconnected. The processing occurs on a background
 * thread to maintain UI responsiveness.
 *
 * If the server is already connected, this method has no effect.
 */
- (void)serveUntilDisconnect
{
    if (self.isConnected)
    {
        return;
    }
    self.isConnected = YES;
    __weak RiveCommandServer* weakSelf = self;
    dispatch_async([RiveCommandServer dispatchQueue], ^{
      __strong RiveCommandServer* strongSelf = weakSelf;
      if (!strongSelf)
          return;
      [strongSelf commandServer]->serveUntilDisconnect();
      strongSelf.isConnected = NO;
    });
}

/**
 * Returns the current connection state of the command server.
 *
 * Used to ensure the server is only started once. The lock prevents race
 * conditions when checking/setting the connection state from multiple threads.
 * While the server is run on a separate thread, serveUntilDisconnect can be
 * called on any thread.
 *
 * @return YES if the server is currently connected and serving, NO otherwise
 */
- (BOOL)isConnected
{
    @synchronized(_isConnectedLock)
    {
        return _isConnected;
    }
}

/**
 * Sets the connection state of the command server.
 *
 * Used to track whether the server is running its serveUntilDisconnect loop.
 * The lock prevents race conditions when checking/setting the connection state
 * from multiple threads. While the server is run on a separate thread,
 * serveUntilDisconnect can be called on any thread.
 *
 * @param isConnected The new connection state to set
 */
- (void)setIsConnected:(BOOL)isConnected
{
    @synchronized(_isConnectedLock)
    {
        _isConnected = isConnected;
    }
}

// MARK: - Private

/**
 * Returns the dispatch queue used for background command processing.
 *
 * This method provides a dedicated serial queue for processing Rive commands
 * in the background. The queue is configured with high priority to ensure
 * responsive command processing while maintaining UI responsiveness.
 *
 * @return A serial dispatch queue for command processing
 */
+ (dispatch_queue_t)dispatchQueue
{
    static dispatch_once_t onceToken;
    static dispatch_queue_t dispatchQueue;
    dispatch_once(&onceToken, ^{
      auto attrs = dispatch_queue_attr_make_with_qos_class(
          DISPATCH_QUEUE_CONCURRENT, QOS_CLASS_USER_INITIATED, -1);
      dispatchQueue = dispatch_queue_create("app.rive.command-server", attrs);
    });
    return dispatchQueue;
}

/**
 * Returns the underlying C++ command server for internal operations.
 *
 * This method provides access to the C++ command server for internal operations
 * and integration with other C++ components.
 *
 * @return A pointer to the C++ command server
 */
- (rive::CommandServer*)commandServer
{
    return _commandServer;
}

@end

NS_ASSUME_NONNULL_END
