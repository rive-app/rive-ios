//
//  RiveCommandServerTests.m
//  RiveRuntimeTests
//
//  Copyright © 2026 Rive. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RiveRuntime/RiveCommandQueue.h>
#import <RiveRuntime/RiveCommandServer.h>

@interface RiveCommandServer (Testing)

- (BOOL)connectIfNeeded;

@end

@interface RiveCommandServerTests : XCTestCase

@end

@implementation RiveCommandServerTests

- (void)testConnectIfNeededAllowsOneConcurrentCaller
{
    RiveCommandQueue* commandQueue = [[RiveCommandQueue alloc] init];
    NSObject* renderContext = [[NSObject alloc] init];
    RiveCommandServer* commandServer =
        [[RiveCommandServer alloc] initWithCommandQueue:commandQueue
                                          renderContext:(id)renderContext];

    const NSUInteger callCount = 32;
    dispatch_queue_t queue = dispatch_queue_create(
        "app.rive.command-server-tests", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    dispatch_semaphore_t startGate = dispatch_semaphore_create(0);
    NSObject* countLock = [[NSObject alloc] init];
    __block NSUInteger connectionCount = 0;

    for (NSUInteger index = 0; index < callCount; index++)
    {
        dispatch_group_async(group, queue, ^{
          dispatch_semaphore_wait(startGate, DISPATCH_TIME_FOREVER);
          if ([commandServer connectIfNeeded])
          {
              @synchronized(countLock)
              {
                  connectionCount++;
              }
          }
        });
    }

    for (NSUInteger index = 0; index < callCount; index++)
    {
        dispatch_semaphore_signal(startGate);
    }

    XCTAssertEqual(
        dispatch_group_wait(group,
                            dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC)),
        0);
    XCTAssertEqual(connectionCount, 1);
}

@end
