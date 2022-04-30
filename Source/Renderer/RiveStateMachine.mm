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
- (RiveStateMachineInstance *)instanceWithArtboard:(RiveArtboard *)artboard {
    return [[RiveStateMachineInstance alloc] initWithStateMachine:stateMachine artboard:artboard];
}

- (RiveStateMachineInput *)_convertInput:(const rive::StateMachineInput *)input error:(NSError**)error {
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
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveUnknownStateMachineInput userInfo:@{NSLocalizedDescriptionKey: @"Unknown State Machine Input", @"name": @"UnknownStateMachineInput"}];
        return nil;
    }
}

// Creates a new instance of this state machine
- (RiveStateMachineInput *)inputFromIndex:(NSInteger)index error:(NSError**)error {
    if (index >= [self inputCount]) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoStateMachineInputFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No Input found at index %ld.", (long)index], @"name": @"NoStateMachineInputFound"}];
        return nil;
    }
    return [self _convertInput: stateMachine->input(index) error:error];
}

// Creates a new instance of this state machine
- (RiveStateMachineInput *)inputFromName:(NSString*)name error:(NSError**)error {
    std::string stdName = std::string([name UTF8String]);
    const rive::StateMachineInput *stateMachineInput = stateMachine->input(stdName);
    if (stateMachineInput == nullptr) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoStateMachineInputFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No State Machine Input found with name %@.", name], @"name": @"NoStateMachineInputFound"}];
        return nil;
    } else {
        return [self _convertInput: stateMachineInput error:error];
    }
}

- (NSArray *)inputNames{
    NSMutableArray *inputNames = [NSMutableArray array];
    for (NSUInteger i=0; i<[self inputCount]; i++){
        [inputNames addObject:[[self inputFromIndex:i error:nil] name]];
    }
    return inputNames;
}
@end
