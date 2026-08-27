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
#import <RiveRuntime/_RiveUIRenderContextProtocol.h>
#import "RivePrivateHeaders.h"
#import "RiveConcurrency_Private.hh"

NS_ASSUME_NONNULL_BEGIN

@interface RiveCommandServer ()

- (BOOL)connectIfNeeded;
- (void)didDisconnect;

@end

@implementation RiveCommandServer
{
    /** The retained command queue from which commands are processed. */
    RiveCommandQueue* _commandQueue;
    /** The retained render context paired with the command queue. */
    id<_RiveUIRenderContextProtocol> _renderContext;
    /** Whether a processing loop is scheduled or running. */
    BOOL _isConnected;
    /** Serializes processing-loop reservation and release. */
    NSObject* _connectionStateLock;
}

/**
 * Initializes a command server with its command-processing pipeline.
 *
 * The server retains both dependencies and initializes its processing-loop
 * state as disconnected.
 *
 * @param commandQueue The command queue from which to process commands
 * @param renderContext The render context paired with the command queue
 * @return An initialized RiveCommandServer instance
 */
- (instancetype)initWithCommandQueue:(RiveCommandQueue*)commandQueue
                       renderContext:
                           (id<_RiveUIRenderContextProtocol>)renderContext
{
    if (self = [super init])
    {
        _commandQueue = commandQueue;
        _renderContext = renderContext;
        _isConnected = NO;
        _connectionStateLock = [[NSObject alloc] init];
    }
    return self;
}

/**
 * Schedules the command server's processing loop on the shared background
 * queue. If a loop is already scheduled or running, this method has no effect.
 */
- (void)serveUntilDisconnect
{
    if (![self connectIfNeeded])
    {
        return;
    }
    __weak RiveCommandServer* weakSelf = self;
    dispatch_async([RiveCommandServer dispatchQueue], ^{
      __strong RiveCommandServer* strongSelf = weakSelf;
      if (!strongSelf)
          return;

      id<_RiveUIRenderContextProtocol> renderContext =
          strongSelf->_renderContext;
      // The factory is borrowed from the context. The inner scope guarantees
      // the C++ server—and objects imported through it—are destroyed before
      // the context ends the processing session that owns that factory.
      rive::Factory* factory = [renderContext beginCommandProcessing];
      {
          rive::CommandServer commandServer(
              strongSelf->_commandQueue.commandQueue, factory);
          commandServer.serveUntilDisconnect();
      }
      [renderContext endCommandProcessing];
      [strongSelf didDisconnect];
    });
}

/**
 * Atomically reserves the server's single scheduled-or-running processing
 * loop.
 *
 * @return YES when this call reserves the loop, or NO when one is already
 *         scheduled or running
 */
- (BOOL)connectIfNeeded
{
    @synchronized(_connectionStateLock)
    {
        if (_isConnected)
        {
            return NO;
        }
        _isConnected = YES;
        return YES;
    }
}

/** Clears the scheduled-or-running state after the processing loop exits. */
- (void)didDisconnect
{
    @synchronized(_connectionStateLock)
    {
        _isConnected = NO;
    }
}

// MARK: - Private

/**
 * Returns the shared concurrent queue used by command servers. Independent
 * workers can run their blocking command loops in parallel on this queue.
 *
 * @return A concurrent user-initiated dispatch queue
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

@end

NS_ASSUME_NONNULL_END
