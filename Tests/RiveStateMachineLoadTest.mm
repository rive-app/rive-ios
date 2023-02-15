//
//  RiveStateMachineLoadTest.m
//  RiveRuntimeTests
//
//  Created by Maxwell Talbot on 11/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Rive.h"
#import "util.h"

@interface RiveStateMachineLoadTest : XCTestCase

@end

@implementation RiveStateMachineLoadTest

/*
 * Test first StateMachine
 */
- (void)testStateMachineFirstStateMachine
{
    NSError* error = nil;
    RiveFile* file = [Util loadTestFile:@"multipleartboards" error:&error];
    RiveArtboard* artboard = [file artboardFromName:@"artboard1" error:&error];

    RiveStateMachineInstance* animationByIndex = [artboard stateMachineFromIndex:0 error:&error];
    XCTAssertNil(error);
    RiveStateMachineInstance* animationByName =
        [artboard stateMachineFromName:@"artboard1stateMachine1" error:&error];
    XCTAssertNil(error);

    XCTAssertTrue([animationByName.name isEqualToString:animationByIndex.name]);

    NSArray* target = [NSArray arrayWithObjects:@"artboard1stateMachine1", nil];
    XCTAssertTrue([[artboard stateMachineNames] isEqualToArray:target]);
}

/*
 * Test second StateMachine
 */
- (void)testStateMachineSecondStateMachine
{
    NSError* error = nil;
    RiveFile* file = [Util loadTestFile:@"multipleartboards" error:&error];
    RiveArtboard* artboard = [file artboardFromName:@"artboard2" error:&error];

    RiveStateMachineInstance* animationByIndex = [artboard stateMachineFromIndex:0 error:&error];
    XCTAssertNil(error);
    RiveStateMachineInstance* animationByName =
        [artboard stateMachineFromName:@"artboard2stateMachine1" error:&error];
    XCTAssertNil(error);

    XCTAssertTrue([animationByName.name isEqualToString:animationByIndex.name]);

    RiveStateMachineInstance* animation2ByIndex = [artboard stateMachineFromIndex:1 error:&error];
    XCTAssertNil(error);
    RiveStateMachineInstance* animation2ByName =
        [artboard stateMachineFromName:@"artboard2stateMachine2" error:&error];
    XCTAssertNil(error);

    XCTAssertTrue([animation2ByIndex.name isEqualToString:animation2ByName.name]);

    NSArray* target =
        [NSArray arrayWithObjects:@"artboard2animation1", @"artboard2animation2", nil];
    XCTAssertTrue([[artboard animationNames] isEqualToArray:target]);
}

/*
 * Test no state machines
 */
- (void)testArtboardHasNoStateMachine
{
    RiveFile* file = [Util loadTestFile:@"noanimation" error:nil];
    RiveArtboard* artboard = [file artboard:nil];

    XCTAssertEqual([artboard animationCount], 0);

    XCTAssertTrue([[artboard animationNames] isEqualToArray:[NSArray array]]);
}

/*
 * Test access index doesnt exist
 */
- (void)testArtboardStateMachineAtIndexDoesntExist
{
    RiveFile* file = [Util loadTestFile:@"noanimation" error:nil];
    RiveArtboard* artboard = [file artboard:nil];

    NSError* error = nil;
    RiveStateMachineInstance* stateMachine = [artboard stateMachineFromIndex:0 error:&error];

    XCTAssertNil(stateMachine);
    XCTAssertEqualObjects([error domain], @"rive.app.ios.runtime");
    XCTAssertEqualObjects([[error userInfo] valueForKey:@"name"], @"NoStateMachineFound");
    XCTAssertEqual([error code], 301);
}

/*
 * Test access name doesnt exist
 */
- (void)testArtboardStateMachineWithNameDoesntExist
{
    RiveFile* file = [Util loadTestFile:@"noanimation" error:nil];
    RiveArtboard* artboard = [file artboard:nil];

    NSError* error = nil;
    RiveStateMachineInstance* stateMachine = [artboard stateMachineFromName:@"boo" error:&error];
    XCTAssertNil(stateMachine);
    XCTAssertEqualObjects([error domain], @"rive.app.ios.runtime");
    XCTAssertEqualObjects([[error userInfo] valueForKey:@"name"], @"NoStateMachineFound");
    XCTAssertEqual([error code], 301);
}

@end
