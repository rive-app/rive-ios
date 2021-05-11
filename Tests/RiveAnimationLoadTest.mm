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
    RiveFile* file = [Util loadTestFile:@"multipleartboards"];
    RiveArtboard* artboard = [file artboardFromName:@"artboard1"];
    
    RiveLinearAnimation* animation = [artboard firstAnimation];
    RiveLinearAnimation* animationByIndex = [artboard animationFromIndex:0];
    RiveLinearAnimation* animationByName = [artboard animationFromName:@"artboard1animation1"];
    
    XCTAssertTrue([animation.name isEqualToString:animationByIndex.name]);
    XCTAssertTrue([animation.name isEqualToString:animationByName.name]);
    
    NSArray *target = [NSArray arrayWithObjects:@"artboard1animation1", nil];
    XCTAssertTrue([[artboard animationNames] isEqualToArray: target]);
}

/*
 * Test second Animation
 */
- (void)testAnimationSecondAnimation {
    RiveFile* file = [Util loadTestFile:@"multipleartboards"];
    RiveArtboard* artboard = [file artboardFromName:@"artboard2"];
    
    RiveLinearAnimation* animation = [artboard firstAnimation];
    RiveLinearAnimation* animationByIndex = [artboard animationFromIndex:0];
    RiveLinearAnimation* animationByName = [artboard animationFromName:@"artboard2animation1"];
    
    XCTAssertTrue([animation.name isEqualToString:animationByIndex.name]);
    XCTAssertTrue([animation.name isEqualToString:animationByName.name]);
    
    
    RiveLinearAnimation* animation2ByIndex = [artboard animationFromIndex:1];
    RiveLinearAnimation* animation2ByName = [artboard animationFromName:@"artboard2animation2"];
    
    XCTAssertTrue([animation2ByIndex.name isEqualToString:animation2ByName.name]);
    
    
    NSArray *target = [NSArray arrayWithObjects:@"artboard2animation1", @"artboard2animation2", nil];
    XCTAssertTrue([[artboard animationNames] isEqualToArray: target]);
}

/*
 * Test no animations
 */
- (void)testArtboardHasNoAnimations {
    RiveFile* file = [Util loadTestFile:@"noanimation"];
    RiveArtboard* artboard = [file artboard];
    
    XCTAssertEqual([artboard animationCount], 0);
    
    XCTAssertTrue([[artboard animationNames] isEqualToArray: [NSArray array]]);
}

/*
 * Test access nothing
 */
- (void)testArtboardAnimationDoesntExist {
    RiveFile* file = [Util loadTestFile:@"noanimation"];
    RiveArtboard* artboard = [file artboard];
    
    XCTAssertThrowsSpecificNamed(
         [artboard firstAnimation],
         RiveException,
         @"NoAnimations"
    );
}

/*
 * Test access index doesnt exist
 */
- (void)testArtboardAnimationAtIndexDoesntExist {
    RiveFile* file = [Util loadTestFile:@"noanimation"];
    RiveArtboard* artboard = [file artboard];
    
    
    XCTAssertThrowsSpecificNamed(
         [artboard animationFromIndex:0],
         RiveException,
         @"NoAnimationFound"
    );
}

/*
 * Test access name doesnt exist
 */
- (void)testArtboardAnimationWithNameDoesntExist {
    RiveFile* file = [Util loadTestFile:@"noanimation"];
    RiveArtboard* artboard = [file artboard];
    
    
    XCTAssertThrowsSpecificNamed(
         [artboard animationFromName:@"boo"],
         RiveException,
         @"NoAnimationFound"
    );
}

@end
