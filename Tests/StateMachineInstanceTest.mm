//
//  StateMachineInstanceTest.m
//  RiveRuntimeTests
//
//  Created by Maxwell Talbot on 12/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//


#import <XCTest/XCTest.h>
#import "Rive.h"
#import "util.h"

@interface RiveStateMachineInstanceTest : XCTestCase

@end

@implementation RiveStateMachineInstanceTest

/*
 * Test nothing
 */
- (void)testNothing {
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations"];
    RiveStateMachineInstance* stateMachineInstance  = [[[file artboard] stateMachineFromName:@"nothing"] instance];

    XCTAssertEqual([stateMachineInstance inputCount], 0);
}

/*
 * Test number input
 */
- (void)testNumberInput {
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations"];
    RiveStateMachineInstance* stateMachineInstance  = [[[file artboard] stateMachineFromName:@"number_input"] instance];

    XCTAssertEqual([stateMachineInstance inputCount], 1);
    
    RiveSMIInput* input = [stateMachineInstance inputFromIndex:0];
    
    XCTAssertEqual([input isBoolean], 0);
    XCTAssertEqual([input isTrigger], 0);
    XCTAssertEqual([input isNumber], 1);
    XCTAssertTrue([[input name] isEqualToString:@"Number 1"]);
    XCTAssertTrue([[[stateMachineInstance inputFromName: @"Number 1"] name] isEqualToString:@"Number 1"]);
    
    [(RiveSMINumber*)input setValue: 15];
    XCTAssertEqual([(RiveSMINumber*)input value], 15);
}

/*
 * Test bool input
 */
- (void)testBooleanInput {
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations"];
    RiveStateMachineInstance* stateMachineInstance  = [[[file artboard] stateMachineFromName:@"boolean_input"] instance];

    XCTAssertEqual([stateMachineInstance inputCount], 1);
    
    RiveSMIInput* input = [stateMachineInstance inputFromIndex:0];
    
    XCTAssertEqual([input isBoolean], 1);
    XCTAssertEqual([input isTrigger], 0);
    XCTAssertEqual([input isNumber], 0);
    XCTAssertTrue([[input name] isEqualToString:@"Boolean 1"]);
    XCTAssertTrue([[[stateMachineInstance inputFromName: @"Boolean 1"] name] isEqualToString:@"Boolean 1"]);
    
    [(RiveSMIBool*)input setValue: false];
    XCTAssertEqual([(RiveSMIBool*)input value], false);
    
    [(RiveSMIBool*)input setValue: true];
    XCTAssertEqual([(RiveSMIBool*)input value], true);
}

/*
 * Test trigger input
 */
- (void)testTriggerInput {
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations"];
    RiveStateMachineInstance* stateMachineInstance  = [[[file artboard] stateMachineFromName:@"trigger_input"] instance];

    XCTAssertEqual([stateMachineInstance inputCount], 1);
    
    RiveSMIInput* input = [stateMachineInstance inputFromIndex:0];
    
    XCTAssertEqual([input isBoolean], 0);
    XCTAssertEqual([input isTrigger], 1);
    XCTAssertEqual([input isNumber], 0);
    XCTAssertTrue([[input name] isEqualToString:@"Trigger 1"]);
    XCTAssertTrue([[[stateMachineInstance inputFromName: @"Trigger 1"] name] isEqualToString:@"Trigger 1"]);
    
    [(RiveSMITrigger*)input fire];
}

/*
 * Test mixed input
 */
- (void)testMixedInput {
    RiveFile* file = [Util loadTestFile:@"state_machine_configurations"];
    RiveStateMachineInstance* stateMachineInstance = [[[file artboard] stateMachineFromName:@"mixed"] instance];

    XCTAssertEqual([stateMachineInstance inputCount], 6);
    NSArray * target = [NSArray arrayWithObjects:@"zero", @"off", @"trigger", @"two_point_two", @"on", @"three", nil];
    
    XCTAssertTrue([[stateMachineInstance inputNames] isEqualToArray: target]);
    
    XCTAssertEqual([[stateMachineInstance inputFromName:@"zero"] isNumber], true);
    XCTAssertEqual([[stateMachineInstance inputFromName:@"off"] isBoolean], true);
    XCTAssertEqual([[stateMachineInstance inputFromName:@"trigger"] isTrigger], true);
    XCTAssertEqual([[stateMachineInstance inputFromName:@"two_point_two"] isNumber], true);
    XCTAssertEqual([[stateMachineInstance inputFromName:@"on"] isBoolean], true);
    XCTAssertEqual([[stateMachineInstance inputFromName:@"three"] isNumber], true);
    
    
    XCTAssertEqual([[stateMachineInstance inputFromName:@"zero"] isKindOfClass:[RiveSMINumber class]], true);
    XCTAssertEqual([(RiveSMINumber *)[stateMachineInstance inputFromName:@"zero"] value], 0);
    XCTAssertEqual([[stateMachineInstance inputFromName:@"two_point_two"] isKindOfClass:[RiveSMINumber class]], true);
    XCTAssertEqual([(RiveSMINumber *)[stateMachineInstance inputFromName:@"two_point_two"] value], (float)2.2);
    XCTAssertEqual([[stateMachineInstance inputFromName:@"three"] isKindOfClass:[RiveSMINumber class]], true);
    XCTAssertEqual([(RiveSMINumber *)[stateMachineInstance inputFromName:@"three"] value], (float)3);
    
    XCTAssertEqual([[stateMachineInstance inputFromName:@"on"] isKindOfClass:[RiveSMIBool class]], true);
    XCTAssertEqual([(RiveSMIBool *)[stateMachineInstance inputFromName:@"on"] value], true);
    XCTAssertEqual([[stateMachineInstance inputFromName:@"off"] isKindOfClass:[RiveSMIBool class]], true);
    XCTAssertEqual([(RiveSMIBool *)[stateMachineInstance inputFromName:@"off"] value], false);
    
    XCTAssertEqual([[stateMachineInstance inputFromName:@"trigger"] isKindOfClass:[RiveSMITrigger class]], true);
}

@end
