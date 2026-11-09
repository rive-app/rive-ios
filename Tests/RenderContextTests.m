//
//  RenderContextTests.m
//  RiveRuntimeTests
//
//  Created by David Skuza on 10/11/24.
//  Copyright © 2024 Rive. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RiveRuntime/RenderContextManager.h>
#import "RenderContext.h"
#import "RiveMetalDrawableView.h"
#import "Concurrency/Renderer/PresentationRecorder.h"

// The context reads only these three view properties during a frame.
@interface PresentationTestDrawableView : NSObject
@property(nonatomic, strong) id<CAMetalDrawable> currentDrawable;
@property(nonatomic) MTLPixelFormat colorPixelFormat;
@property(nonatomic) CGSize drawableSize;
@end

@implementation PresentationTestDrawableView
@end

@interface RenderContextTests : XCTestCase

@end

@implementation RenderContextTests

// These tests intentionally exercise the deprecated compatibility API.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)testLegacyRendererSelectionUsesRiveRenderer
{
  XCTAssertEqual(riveRenderer, 0);
  XCTAssertEqual(cgRenderer, 1);

  RenderContextManager* manager = [[RenderContextManager alloc] init];
  XCTAssertEqual(manager.defaultRenderer, riveRenderer);

  RenderContext* riveContext = [manager newRiveContext];
  XCTAssertNotNil(riveContext);

  RendererType rendererTypes[] = {riveRenderer, cgRenderer};
  for (NSUInteger i = 0; i < 2; ++i)
  {
    manager.defaultRenderer = rendererTypes[i];
    XCTAssertEqual(manager.defaultRenderer, rendererTypes[i]);

    RenderContext* context = [manager newDefaultContext];
    XCTAssertNotNil(context);
    XCTAssertEqual([context class], [riveContext class]);
  }
}

- (void)testLegacyCGContextUsesRiveRenderer
{
  RenderContextManager* manager = [[RenderContextManager alloc] init];
  manager.defaultRenderer = cgRenderer;
  RenderContext* riveContext = [manager newRiveContext];
  RenderContext* context = [manager newCGContext];

  XCTAssertNotNil(riveContext);
  XCTAssertNotNil(context);
  XCTAssertEqual([context class], [riveContext class]);
  XCTAssertTrue([context canDrawInRect:CGRectMake(0, 0, 320, 240)
                          drawableSize:CGSizeMake(320, 240)
                                 scale:1.0f]);
}

- (void)testEndFramePresentsAtCurrentTimeAndCommitsOnce
{
  RenderContext* context = [[RenderContextManager shared] newRiveContext];
  CAMetalLayer* layer = [CAMetalLayer layer];
  layer.device = context.metalDevice;
  layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
  layer.drawableSize = CGSizeMake(1, 1);
  layer.framebufferOnly = context.framebufferOnly;
  id<CAMetalDrawable> drawable = [layer nextDrawable];
  XCTAssertNotNil(drawable);
  if (drawable == nil)
  {
    return;
  }

  PresentationTestDrawableView* view = [PresentationTestDrawableView new];
  view.currentDrawable = drawable;
  view.colorPixelFormat = layer.pixelFormat;
  view.drawableSize = layer.drawableSize;
  PresentationCommandQueueRecorder*
      queueRecorder = [[PresentationCommandQueueRecorder alloc]
          initWithCommandQueue:context.metalQueue];
  context.metalQueue = queueRecorder.commandQueue;
  XCTAssertNotEqual(
      [context beginFrame:(id<RiveMetalDrawableView>)view], nullptr);

  XCTestExpectation* completed = [self
      expectationWithDescription:@"Command buffer completed"];
  CFTimeInterval beforePresentation = CACurrentMediaTime();
  [context endFrame:(id<RiveMetalDrawableView>)view
      withCompletion:^(id<MTLCommandBuffer> buffer) {
        XCTAssertEqual(buffer.status, MTLCommandBufferStatusCompleted);
        [completed fulfill];
      }];
  CFTimeInterval afterPresentation = CACurrentMediaTime();

  PresentationCommandBufferRecorder* recorder = queueRecorder
                                                    .lastCommandBufferRecorder;
  XCTAssertNotNil(recorder);
  // Exercise the real endFrame path, including flush and completion delivery.
  XCTAssertEqual(recorder.timedPresentationCount, 1u);
  XCTAssertEqual(recorder.untimedPresentationCount, 0u);
  XCTAssertEqual(recorder.presentedDrawable, drawable);
  XCTAssertGreaterThanOrEqual(recorder.presentationTime, beforePresentation);
  XCTAssertLessThanOrEqual(recorder.presentationTime, afterPresentation);
  XCTAssertEqual(recorder.commitCount, 1u);
  [self waitForExpectations:@[ completed ] timeout:5];
}

#pragma clang diagnostic pop

- (void)testCanDrawWithValidRectAndDrawableSize
{
  CGRect rect = CGRectMake(0, 0, 320, 240);
  CGSize drawableSize = CGSizeMake(320, 240);
  CGFloat scale = 1.0f;

  RenderContext* context = [[RenderContextManager shared] newRiveContext];
  XCTAssertTrue([context canDrawInRect:rect
                          drawableSize:drawableSize
                                 scale:scale]);
}

- (void)testCanDrawWithValidRectAndScaleAndInvalidDrawableSize
{
  CGRect rect = CGRectMake(0, 0, 320, 240);
  CGSize drawableSize = CGSizeMake(INFINITY, INFINITY);
  CGFloat scale = 1.0f;

  RenderContext* context = [[RenderContextManager shared] newRiveContext];
  XCTAssertFalse([context canDrawInRect:rect
                           drawableSize:drawableSize
                                  scale:scale]);
}

- (void)testCanDrawWithInvalidRectAndValidDrawableSizeAndScale
{
  CGRect rect = CGRectMake(0, 0, 0, 0);
  CGSize drawableSize = CGSizeMake(320, 240);
  CGFloat scale = 1.0f;

  RenderContext* context = [[RenderContextManager shared] newRiveContext];
  XCTAssertFalse([context canDrawInRect:rect
                           drawableSize:drawableSize
                                  scale:scale]);
}

- (void)testCanDrawWithValidRectAndDrawableSizeAndInvalidScale
{
  CGRect rect = CGRectMake(0, 0, 320, 240);
  CGSize drawableSize = CGSizeMake(320, 240);
  CGFloat scale = -1.0f;

  RenderContext* context = [[RenderContextManager shared] newRiveContext];
  XCTAssertFalse([context canDrawInRect:rect
                           drawableSize:drawableSize
                                  scale:scale]);
}

- (void)testCanDrawWithValidRectAndDrawableSizeAndRidiculousScale
{
  CGRect rect = CGRectMake(0, 0, 320, 240);
  CGSize drawableSize = CGSizeMake(320, 240);
  CGFloat scale = 1000.0f;

  RenderContext* context = [[RenderContextManager shared] newRiveContext];
  XCTAssertFalse([context canDrawInRect:rect
                           drawableSize:drawableSize
                                  scale:scale]);
}

@end
