//
//  RiveAnimationLoadTest.m
//  RiveRuntimeTests
//
//  Created by Maxwell Talbot on 11/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//



#import <XCTest/XCTest.h>
#import "Rive.h"
#import "util.h"

@interface RiveAnimationLoadTest : XCTestCase

@end

@implementation RiveAnimationLoadTest

/*
 * Test first Animation
 */
- (void)testAnimationFirstAnimation {
    NSError* error = nil;
    RiveFile* file = [Util loadTestFile:@"multipleartboards" error:&error];
    RiveArtboard* artboard = [file artboardFromName:@"artboard1" error:&error];

    RiveLinearAnimation* animation = [artboard firstAnimation:&error];
    XCTAssertNil(error);

    RiveLinearAnimation* animationByIndex = [artboard animationFromIndex:0 error:&error];
    XCTAssertNil(error);
    
    RiveLinearAnimation* animationByName = [artboard animationFromName:@"artboard1animation1" error:&error];
    XCTAssertNil(error);
    
    XCTAssertTrue([animation.name isEqualToString:animationByIndex.name]);
    XCTAssertTrue([animation.name isEqualToString:animationByName.name]);
    
    NSArray *target = [NSArray arrayWithObjects:@"artboard1animation1", nil];
    XCTAssertTrue([[artboard animationNames] isEqualToArray: target]);
}

/*
 * Test second Animation
 */
- (void)testAnimationSecondAnimation {
    NSError* error = nil;
    RiveFile* file = [Util loadTestFile:@"multipleartboards" error:&error];
    RiveArtboard* artboard = [file artboardFromName:@"artboard2" error:&error];
    
    RiveLinearAnimation* animation = [artboard firstAnimation:&error];
    XCTAssertNil(error);
    RiveLinearAnimation* animationByIndex = [artboard animationFromIndex:0 error:&error];
    XCTAssertNil(error);
    RiveLinearAnimation* animationByName = [artboard animationFromName:@"artboard2animation1" error:&error];
    XCTAssertNil(error);
    
    XCTAssertTrue([animation.name isEqualToString:animationByIndex.name]);
    XCTAssertTrue([animation.name isEqualToString:animationByName.name]);
    
    RiveLinearAnimation* animation2ByIndex = [artboard animationFromIndex:1 error:&error];
    XCTAssertNil(error);
    RiveLinearAnimation* animation2ByName = [artboard animationFromName:@"artboard2animation2" error:&error];
    XCTAssertNil(error);
    
    XCTAssertTrue([animation2ByIndex.name isEqualToString:animation2ByName.name]);
    
    
    NSArray *target = [NSArray arrayWithObjects:@"artboard2animation1", @"artboard2animation2", nil];
    XCTAssertTrue([[artboard animationNames] isEqualToArray: target]);
}

/*
 * Test no animations
 */
- (void)testArtboardHasNoAnimations {
    RiveFile* file = [Util loadTestFile:@"noanimation" error:nil];
    RiveArtboard* artboard = [file artboard:nil];
    
    XCTAssertEqual([artboard animationCount], 0);
    
    XCTAssertTrue([[artboard animationNames] isEqualToArray: [NSArray array]]);
}

/*
 * Test access nothing
 */
- (void)testArtboardAnimationDoesntExist {
    
    RiveFile* file = [Util loadTestFile:@"noanimation" error:nil];
    RiveArtboard* artboard = [file artboard:nil];

    NSError* error = nil;
    RiveLinearAnimation* animation = [artboard firstAnimation:&error];
    
    XCTAssertNil(animation);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects([error domain], @"rive.app.ios.runtime");
    XCTAssertEqualObjects([[error userInfo] valueForKey:@"name"], @"NoAnimations");
    XCTAssertEqual([error code], 200);
}

/*
 * Test access index doesnt exist
 */
- (void)testArtboardAnimationAtIndexDoesntExist {
    RiveFile* file = [Util loadTestFile:@"noanimation" error:nil];
    RiveArtboard* artboard = [file artboard:nil];

    NSError* error = nil;
    RiveLinearAnimation* animation = [artboard animationFromIndex:0 error:&error];
    XCTAssertNil(animation);
    
    XCTAssertNotNil(error);
    XCTAssertEqualObjects([error domain], @"rive.app.ios.runtime");
    XCTAssertEqualObjects([[error userInfo] valueForKey:@"name"], @"NoAnimationFound");
    XCTAssertEqual([error code], 201);
}

/*
 * Test access name doesnt exist
 */
- (void)testArtboardAnimationWithNameDoesntExist {
    RiveFile* file = [Util loadTestFile:@"noanimation" error:nil];
    RiveArtboard* artboard = [file artboard:nil];
    
    NSError* error = nil;
    RiveLinearAnimation* animation = [artboard animationFromName:@"boo" error:&error];
    XCTAssertNil(animation);

    XCTAssertNotNil(error);
    XCTAssertEqualObjects([error domain], @"rive.app.ios.runtime");
    XCTAssertEqualObjects([[error userInfo] valueForKey:@"name"], @"NoAnimationFound");
    XCTAssertEqual([error code], 201);
}

@end
