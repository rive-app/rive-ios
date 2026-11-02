//
//  RiveUIRendererCompatibilityTests.mm
//  RiveRuntimeTests
//
//  Copyright © 2026 Rive. All rights reserved.
//

#import <Metal/Metal.h>
#import <XCTest/XCTest.h>

#import "RiveUIRenderer_Private.hh"

#include <initializer_list>

// The commit helpers only read status and call commit.
@interface RendererTestCommandBuffer : NSObject
@property(nonatomic) MTLCommandBufferStatus status;
@property(nonatomic, readonly) NSUInteger commitCount;
- (void)commit;
@end

@implementation RendererTestCommandBuffer
- (void)commit
{
  ++_commitCount;
  self.status = MTLCommandBufferStatusCommitted;
}
@end

@interface RiveUIRendererCompatibilityTests : XCTestCase
@end

@implementation RiveUIRendererCompatibilityTests

- (void)test_uncommittedBuffers_commitOnce
{
  for (auto status :
       {MTLCommandBufferStatusNotEnqueued, MTLCommandBufferStatusEnqueued})
  {
    RendererTestCommandBuffer* buffer = [RendererTestCommandBuffer new];
    buffer.status = status;

    RiveUIRendererCommitCommandBufferIfNeeded((id<MTLCommandBuffer>)buffer);
    RiveUIRendererCommitCommandBufferIfNeeded((id<MTLCommandBuffer>)buffer);

    XCTAssertEqual(buffer.commitCount, 1);
    XCTAssertEqual(buffer.status, MTLCommandBufferStatusCommitted);
  }
}

- (void)test_submittedBuffers_doNotCommitAgain
{
  for (auto status :
       {MTLCommandBufferStatusCommitted,
        MTLCommandBufferStatusScheduled,
        MTLCommandBufferStatusCompleted,
        MTLCommandBufferStatusError})
  {
    RendererTestCommandBuffer* buffer = [RendererTestCommandBuffer new];
    buffer.status = status;

    RiveUIRendererCommitCommandBufferIfNeeded((id<MTLCommandBuffer>)buffer);

    XCTAssertEqual(buffer.commitCount, 0);
    XCTAssertEqual(buffer.status, status);
  }
}

- (void)test_legacyFinalizeWithNil_commits
{
  RendererTestCommandBuffer* buffer = [RendererTestCommandBuffer new];

  RiveUIRendererInvokeLegacyFinalize(nil, (id<MTLCommandBuffer>)buffer);

  XCTAssertEqual(buffer.commitCount, 1);
}

- (void)test_legacyFinalizeBlock_ownsCommit
{
  RendererTestCommandBuffer* buffer = [RendererTestCommandBuffer new];
  __block id<MTLCommandBuffer> receivedBuffer = nil;

  RiveUIRendererInvokeLegacyFinalize(
      ^(id<MTLCommandBuffer> commandBuffer) {
        receivedBuffer = commandBuffer;
      },
      (id<MTLCommandBuffer>)buffer);

  XCTAssertTrue((id)receivedBuffer == buffer);
  XCTAssertEqual(buffer.commitCount, 0);
}

- (void)test_legacyFinalizeBlock_canCommitOnce
{
  RendererTestCommandBuffer* buffer = [RendererTestCommandBuffer new];

  RiveUIRendererInvokeLegacyFinalize(
      ^(id<MTLCommandBuffer> commandBuffer) {
        [commandBuffer commit];
      },
      (id<MTLCommandBuffer>)buffer);

  XCTAssertEqual(buffer.commitCount, 1);
}

@end
