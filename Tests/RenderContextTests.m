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

@interface RenderContextTests : XCTestCase

@end

@implementation RenderContextTests

- (void)testCanDrawWithValidRectAndDrawableSize
{
    CGRect rect = CGRectMake(0, 0, 320, 240);
    CGSize drawableSize = CGSizeMake(320, 240);
    CGFloat scale = 1.0f;

    RenderContext* context = [[RenderContextManager shared] newRiveContext];
    XCTAssertTrue([context canDrawInRect:rect
                            drawableSize:drawableSize
                                   scale:scale]);

    context = [[RenderContextManager shared] newCGContext];
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

    context = [[RenderContextManager shared] newCGContext];
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

    context = [[RenderContextManager shared] newCGContext];
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

    context = [[RenderContextManager shared] newCGContext];
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

    context = [[RenderContextManager shared] newCGContext];
    XCTAssertFalse([context canDrawInRect:rect
                             drawableSize:drawableSize
                                    scale:scale]);
}

@end
