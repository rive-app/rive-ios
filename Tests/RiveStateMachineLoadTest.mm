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
- (void)testStateMachineFirstStateMachine {
    RiveFile* file = [Util loadTestFile:@"multipleartboards"];
    RiveArtboard* artboard = [file artboardFromName:@"artboard1"];
    
    RiveStateMachine* animation = [artboard firstStateMachine];
    RiveStateMachine* animationByIndex = [artboard stateMachineFromIndex:0];
    RiveStateMachine* animationByName = [artboard stateMachineFromName:@"artboard1stateMachine1"];
    
    XCTAssertTrue([animation.name isEqualToString:animationByIndex.name]);
    XCTAssertTrue([animation.name isEqualToString:animationByName.name]);
    
    NSArray *target = [NSArray arrayWithObjects:@"artboard1stateMachine1", nil];
    XCTAssertTrue([[artboard stateMachineNames] isEqualToArray: target]);
}

/*
 * Test second StateMachine
 */
- (void)testStateMachineSecondStateMachine {
    RiveFile* file = [Util loadTestFile:@"multipleartboards"];
    RiveArtboard* artboard = [file artboardFromName:@"artboard2"];
    
    RiveStateMachine* animation = [artboard firstStateMachine];
    RiveStateMachine* animationByIndex = [artboard stateMachineFromIndex:0];
    RiveStateMachine* animationByName = [artboard stateMachineFromName:@"artboard2stateMachine1"];
    
    XCTAssertTrue([animation.name isEqualToString:animationByIndex.name]);
    XCTAssertTrue([animation.name isEqualToString:animationByName.name]);
    
    
    RiveStateMachine* animation2ByIndex = [artboard stateMachineFromIndex:1];
    RiveStateMachine* animation2ByName = [artboard stateMachineFromName:@"artboard2stateMachine2"];
    
    XCTAssertTrue([animation2ByIndex.name isEqualToString:animation2ByName.name]);
    
    
    NSArray *target = [NSArray arrayWithObjects:@"artboard2animation1", @"artboard2animation2", nil];
    XCTAssertTrue([[artboard animationNames] isEqualToArray: target]);
}

/*
 * Test no state machines
 */
- (void)testArtboardHasNoStateMachine {
    RiveFile* file = [Util loadTestFile:@"noanimation"];
    RiveArtboard* artboard = [file artboard];
    
    XCTAssertEqual([artboard animationCount], 0);
    
    XCTAssertTrue([[artboard animationNames] isEqualToArray: [NSArray array]]);
}

/*
 * Test access nothing
 */
- (void)testArtboardStateMachineDoesntExist {
    RiveFile* file = [Util loadTestFile:@"noanimation"];
    RiveArtboard* artboard = [file artboard];
    
    XCTAssertThrowsSpecificNamed(
         [artboard firstStateMachine],
         RiveException,
         @"NoStateMachines"
    );
}

/*
 * Test access index doesnt exist
 */
- (void)testArtboardStateMachineAtIndexDoesntExist {
    RiveFile* file = [Util loadTestFile:@"noanimation"];
    RiveArtboard* artboard = [file artboard];
    
    
    XCTAssertThrowsSpecificNamed(
         [artboard stateMachineFromIndex:0],
         RiveException,
         @"NoStateMachineFound"
    );
}

/*
 * Test access name doesnt exist
 */
- (void)testArtboardStateMachineWithNameDoesntExist {
    RiveFile* file = [Util loadTestFile:@"noanimation"];
    RiveArtboard* artboard = [file artboard];
    
    
    XCTAssertThrowsSpecificNamed(
         [artboard stateMachineFromName:@"boo"],
         RiveException,
         @"NoStateMachineFound"
    );
}

@end
