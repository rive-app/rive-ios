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
- (void)testNothing
{
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations" error:nil];

    RiveStateMachineInstance* stateMachine = [[file artboard:nil] stateMachineFromName:@"nothing"
                                                                                 error:nil];

    XCTAssertEqual([stateMachine inputCount], 0);
    XCTAssertEqual([stateMachine layerCount], 0);
}

/*
 * Test oneLayer
 */
- (void)testOneLayer
{
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations" error:nil];

    RiveStateMachineInstance* stateMachine = [[file artboard:nil] stateMachineFromName:@"one_layer"
                                                                                 error:nil];

    XCTAssertEqual([stateMachine inputCount], 0);
    XCTAssertEqual([stateMachine layerCount], 1);
}

/*
 * Test two layers
 */
- (void)testTwoLayers
{
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations" error:nil];

    RiveStateMachineInstance* stateMachine = [[file artboard:nil] stateMachineFromName:@"two_layers"
                                                                                 error:nil];

    XCTAssertEqual([stateMachine inputCount], 0);
    XCTAssertEqual([stateMachine layerCount], 2);
}

/*
 * Test number input
 */
- (void)testNumberInput
{
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations" error:nil];

    RiveStateMachineInstance* stateMachine =
        [[file artboard:nil] stateMachineFromName:@"number_input" error:nil];

    XCTAssertEqual([stateMachine inputCount], 1);
    XCTAssertEqual([stateMachine layerCount], 1);

    RiveSMIInput* input = [stateMachine inputFromIndex:0 error:nil];

    XCTAssertEqual([input isBoolean], 0);
    XCTAssertEqual([input isTrigger], 0);
    XCTAssertEqual([input isNumber], 1);
    XCTAssertTrue([[input name] isEqualToString:@"Number 1"]);
    XCTAssertTrue([[[stateMachine inputFromName:@"Number 1"
                                          error:nil] name] isEqualToString:@"Number 1"]);
}

/*
 * Test bool input
 */
- (void)testBooleanInput
{
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations" error:nil];

    RiveStateMachineInstance* stateMachine =
        [[file artboard:nil] stateMachineFromName:@"boolean_input" error:nil];

    XCTAssertEqual([stateMachine inputCount], 1);
    XCTAssertEqual([stateMachine layerCount], 1);

    RiveSMIInput* input = [stateMachine inputFromIndex:0 error:nil];

    XCTAssertEqual([input isBoolean], 1);
    XCTAssertEqual([input isTrigger], 0);
    XCTAssertEqual([input isNumber], 0);
    XCTAssertTrue([[input name] isEqualToString:@"Boolean 1"]);
    XCTAssertTrue([[[stateMachine inputFromName:@"Boolean 1"
                                          error:nil] name] isEqualToString:@"Boolean 1"]);
}

/*
 * Test trigger input
 */
- (void)testTriggerInput
{
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations" error:nil];

    RiveStateMachineInstance* stateMachine =
        [[file artboard:nil] stateMachineFromName:@"trigger_input" error:nil];

    XCTAssertEqual([stateMachine inputCount], 1);
    XCTAssertEqual([stateMachine layerCount], 1);

    RiveSMIInput* input = [stateMachine inputFromIndex:0 error:nil];

    XCTAssertEqual([input isBoolean], 0);
    XCTAssertEqual([input isTrigger], 1);
    XCTAssertEqual([input isNumber], 0);
    XCTAssertTrue([[input name] isEqualToString:@"Trigger 1"]);
    XCTAssertTrue([[[stateMachine inputFromName:@"Trigger 1"
                                          error:nil] name] isEqualToString:@"Trigger 1"]);
}

/*
 * Test mixed input
 */
- (void)testMixedInput
{
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations" error:nil];

    RiveStateMachineInstance* stateMachine = [[file artboard:nil] stateMachineFromName:@"mixed"
                                                                                 error:nil];

    XCTAssertEqual([stateMachine inputCount], 6);
    XCTAssertEqual([stateMachine layerCount], 4);
    NSArray* target = [NSArray
        arrayWithObjects:@"zero", @"off", @"trigger", @"two_point_two", @"on", @"three", nil];

    XCTAssertTrue([[stateMachine inputNames] isEqualToArray:target]);

    XCTAssertEqual([[stateMachine inputFromName:@"zero" error:nil] isNumber], true);
    XCTAssertEqual([[stateMachine inputFromName:@"off" error:nil] isBoolean], true);
    XCTAssertEqual([[stateMachine inputFromName:@"trigger" error:nil] isTrigger], true);
    XCTAssertEqual([[stateMachine inputFromName:@"two_point_two" error:nil] isNumber], true);
    XCTAssertEqual([[stateMachine inputFromName:@"on" error:nil] isBoolean], true);
    XCTAssertEqual([[stateMachine inputFromName:@"three" error:nil] isNumber], true);

    XCTAssertEqual(
        [[stateMachine inputFromName:@"zero" error:nil] isKindOfClass:[RiveSMINumber class]], true);
    XCTAssertEqual([(RiveSMINumber*)[stateMachine inputFromName:@"zero" error:nil] value], 0);
    XCTAssertEqual([[stateMachine inputFromName:@"two_point_two"
                                          error:nil] isKindOfClass:[RiveSMINumber class]],
                   true);
    XCTAssertEqual([(RiveSMINumber*)[stateMachine inputFromName:@"two_point_two" error:nil] value],
                   (float)2.2);
    XCTAssertEqual([[stateMachine inputFromName:@"three"
                                          error:nil] isKindOfClass:[RiveSMINumber class]],
                   true);
    XCTAssertEqual([(RiveSMINumber*)[stateMachine inputFromName:@"three" error:nil] value],
                   (float)3);

    XCTAssertEqual([[stateMachine inputFromName:@"on" error:nil] isKindOfClass:[RiveSMIBool class]],
                   true);
    XCTAssertEqual([(RiveSMIBool*)[stateMachine inputFromName:@"on" error:nil] value], true);
    XCTAssertEqual(
        [[stateMachine inputFromName:@"off" error:nil] isKindOfClass:[RiveSMIBool class]], true);
    XCTAssertEqual([(RiveSMIBool*)[stateMachine inputFromName:@"off" error:nil] value], false);

    XCTAssertEqual([[stateMachine inputFromName:@"trigger"
                                          error:nil] isKindOfClass:[RiveSMITrigger class]],
                   true);
}

@end
