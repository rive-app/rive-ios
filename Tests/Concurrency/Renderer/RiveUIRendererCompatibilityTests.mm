//
//  RiveUIRendererCompatibilityTests.mm
//  RiveRuntimeTests
//
//  Copyright © 2026 Rive. All rights reserved.
//

#import <Metal/Metal.h>
#import <RiveRuntime/RiveUIRenderer.h>
#import <XCTest/XCTest.h>

#import "../../../Source/Concurrency/Renderer/RiveUIRenderer_Private.hh"

@interface RiveUIRendererCompatibilityTests : XCTestCase
@end

@implementation RiveUIRendererCompatibilityTests

- (void)test_legacyFinalizeWithNil_commitsCommandBuffer
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    XCTAssertNotNil(device);
    if (!device)
    {
        return;
    }
    id<MTLCommandQueue> commandQueue = [device newCommandQueue];
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    XCTestExpectation* completed =
        [self expectationWithDescription:@"Command buffer completed"];
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
      XCTAssertEqual(buffer.status, MTLCommandBufferStatusCompleted);
      [completed fulfill];
    }];

    RiveUIRendererInvokeLegacyFinalize(nil, commandBuffer);

    [self waitForExpectations:@[ completed ] timeout:2];
}

@end
