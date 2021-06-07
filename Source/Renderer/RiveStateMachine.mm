//
//  RiveStateMachine.mm
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>

/*
 * RiveStateMachine
 */
@implementation RiveStateMachine {
    const rive::StateMachine *stateMachine;
}

// Creates a new RiveStateMachine from a cpp StateMachine
- (instancetype)initWithStateMachine:(const rive::StateMachine *)stateMachine {
    if (self = [super init]) {
        self->stateMachine = stateMachine;
        return self;
    } else {
        return nil;
    }
}

// Returns the name of the state machine
- (NSString *)name {
    std::string str = stateMachine->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

// Returns the number of inputs in the state machine
- (NSInteger)inputCount {
    return stateMachine->inputCount();
}

// Returns the number of layers in the state machine
- (NSInteger)layerCount {
    return stateMachine->layerCount();
}

// Creates a new instance of this state machine
- (RiveStateMachineInstance *)instance {
    return [[RiveStateMachineInstance alloc] initWithStateMachine: stateMachine];
}

- (RiveStateMachineInput *)_convertInput:(const rive::StateMachineInput *)input{
    if (input->is<rive::StateMachineBool>()){
        return [[RiveStateMachineBoolInput alloc] initWithStateMachineInput: input];
    }
    else if (input->is<rive::StateMachineNumber>()){
        return [[RiveStateMachineNumberInput alloc] initWithStateMachineInput: input];
    }
    else if (input->is<rive::StateMachineTrigger>()){
        return [[RiveStateMachineTriggerInput alloc] initWithStateMachineInput: input];
    }
    else {
        @throw [[RiveException alloc] initWithName:@"UnkownInput" reason: @"Unknown State Machine Input" userInfo:nil];
    }
}

// Creates a new instance of this state machine
- (RiveStateMachineInput *)inputFromIndex:(NSInteger)index {
    if (index >= [self inputCount]) {
        @throw [[RiveException alloc] initWithName:@"NoStateMachineInputFound" reason:[NSString stringWithFormat: @"No Input found at index %ld.", (long)index] userInfo:nil];
    }
    return [self _convertInput: stateMachine->input(index) ];
}

// Creates a new instance of this state machine
- (RiveStateMachineInput *)inputFromName:(NSString*)name {
    
    std::string stdName = std::string([name UTF8String]);
    const rive::StateMachineInput *stateMachineInput = stateMachine->input(stdName);
    if (stateMachineInput == nullptr) {
        @throw [[RiveException alloc] initWithName:@"NoStateMachineInputFound" reason:[NSString stringWithFormat: @"No State Machine Input found with name %@.", name] userInfo:nil];
    } else {
        return [self _convertInput: stateMachineInput];
    }
}

- (NSArray *)inputNames{
    NSMutableArray *inputNames = [NSMutableArray array];
    
    for (NSUInteger i=0; i<[self inputCount]; i++){
        [inputNames addObject:[[self inputFromIndex: i] name]];
    }
    return inputNames;
}
@end
