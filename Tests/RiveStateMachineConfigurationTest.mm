//
//  RiveStateMachineConfigurationTest.m
//  RiveRuntimeTests
//
//  Created by Maxwell Talbot on 11/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Rive.h"
#import "util.h"

@interface RiveStateMachineConfigurationTest : XCTestCase

@end

@implementation RiveStateMachineConfigurationTest

/*
 * Test nothing
 */
- (void)testNothing {
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations"];
    RiveStateMachine* stateMachine = [[file artboard] stateMachineFromName:@"nothing"];

    XCTAssertEqual([stateMachine inputCount], 0);
    XCTAssertEqual([stateMachine layerCount], 0);
}

/*
 * Test oneLayer
 */
- (void)testOneLayer {
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations"];
    RiveStateMachine* stateMachine = [[file artboard] stateMachineFromName:@"one_layer"];

    XCTAssertEqual([stateMachine inputCount], 0);
    XCTAssertEqual([stateMachine layerCount], 1);
}

/*
 * Test two layers
 */
- (void)testTwoLayers {
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations"];
    RiveStateMachine* stateMachine = [[file artboard] stateMachineFromName:@"two_layers"];

    XCTAssertEqual([stateMachine inputCount], 0);
    XCTAssertEqual([stateMachine layerCount], 2);
}

/*
 * Test number input
 */
- (void)testNumberInput {
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations"];
    RiveStateMachine* stateMachine = [[file artboard] stateMachineFromName:@"number_input"];

    XCTAssertEqual([stateMachine inputCount], 1);
    XCTAssertEqual([stateMachine layerCount], 1);
    
    RiveStateMachineInput* input = [stateMachine inputFromIndex:0];
    
    XCTAssertEqual([input isBoolean], 0);
    XCTAssertEqual([input isTrigger], 0);
    XCTAssertEqual([input isNumber], 1);
    XCTAssertTrue([[input name] isEqualToString:@"Number 1"]);
    XCTAssertTrue([[[stateMachine inputFromName: @"Number 1"] name] isEqualToString:@"Number 1"]);
}

/*
 * Test bool input
 */
- (void)testBooleanInput {
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations"];
    RiveStateMachine* stateMachine = [[file artboard] stateMachineFromName:@"boolean_input"];

    XCTAssertEqual([stateMachine inputCount], 1);
    XCTAssertEqual([stateMachine layerCount], 1);
    
    RiveStateMachineInput* input = [stateMachine inputFromIndex:0];
    
    XCTAssertEqual([input isBoolean], 1);
    XCTAssertEqual([input isTrigger], 0);
    XCTAssertEqual([input isNumber], 0);
    XCTAssertTrue([[input name] isEqualToString:@"Boolean 1"]);
    XCTAssertTrue([[[stateMachine inputFromName: @"Boolean 1"] name] isEqualToString:@"Boolean 1"]);
}


/*
 * Test trigger input
 */
- (void)testTriggerInput {
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations"];
    RiveStateMachine* stateMachine = [[file artboard] stateMachineFromName:@"trigger_input"];

    XCTAssertEqual([stateMachine inputCount], 1);
    XCTAssertEqual([stateMachine layerCount], 1);
    
    RiveStateMachineInput* input = [stateMachine inputFromIndex:0];
    
    XCTAssertEqual([input isBoolean], 0);
    XCTAssertEqual([input isTrigger], 1);
    XCTAssertEqual([input isNumber], 0);
    XCTAssertTrue([[input name] isEqualToString:@"Trigger 1"]);
    XCTAssertTrue([[[stateMachine inputFromName: @"Trigger 1"] name] isEqualToString:@"Trigger 1"]);
}

/*
 * Test mixed input
 */
- (void)testMixedInput {
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations"];
    RiveStateMachine* stateMachine = [[file artboard] stateMachineFromName:@"mixed"];

    XCTAssertEqual([stateMachine inputCount], 6);
    XCTAssertEqual([stateMachine layerCount], 4);
    NSArray * target = [NSArray arrayWithObjects:@"zero", @"off", @"trigger", @"two_point_two", @"on", @"three", nil];
    
    XCTAssertTrue([[stateMachine inputNames] isEqualToArray: target]);
    
    XCTAssertEqual([[stateMachine inputFromName:@"zero"] isNumber], true);
    XCTAssertEqual([[stateMachine inputFromName:@"off"] isBoolean], true);
    XCTAssertEqual([[stateMachine inputFromName:@"trigger"] isTrigger], true);
    XCTAssertEqual([[stateMachine inputFromName:@"two_point_two"] isNumber], true);
    XCTAssertEqual([[stateMachine inputFromName:@"on"] isBoolean], true);
    XCTAssertEqual([[stateMachine inputFromName:@"three"] isNumber], true);
    
    
    XCTAssertEqual([[stateMachine inputFromName:@"zero"] isKindOfClass:[RiveStateMachineNumberInput class]], true);
    XCTAssertEqual([(RiveStateMachineNumberInput *)[stateMachine inputFromName:@"zero"] value], 0);
    XCTAssertEqual([[stateMachine inputFromName:@"two_point_two"] isKindOfClass:[RiveStateMachineNumberInput class]], true);
    XCTAssertEqual([(RiveStateMachineNumberInput *)[stateMachine inputFromName:@"two_point_two"] value], (float)2.2);
    XCTAssertEqual([[stateMachine inputFromName:@"three"] isKindOfClass:[RiveStateMachineNumberInput class]], true);
    XCTAssertEqual([(RiveStateMachineNumberInput *)[stateMachine inputFromName:@"three"] value], (float)3);
    
    XCTAssertEqual([[stateMachine inputFromName:@"on"] isKindOfClass:[RiveStateMachineBoolInput class]], true);
    XCTAssertEqual([(RiveStateMachineBoolInput *)[stateMachine inputFromName:@"on"] value], true);
    XCTAssertEqual([[stateMachine inputFromName:@"off"] isKindOfClass:[RiveStateMachineBoolInput class]], true);
    XCTAssertEqual([(RiveStateMachineBoolInput *)[stateMachine inputFromName:@"off"] value], false);
    
    XCTAssertEqual([[stateMachine inputFromName:@"trigger"] isKindOfClass:[RiveStateMachineTriggerInput class]], true);
}

@end
