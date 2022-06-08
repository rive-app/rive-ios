//
//  RiveStateMachineInstance.mm
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>

@interface RiveStateMachineInstance ()

/// Holds references to SMIInputs
@property NSMutableDictionary *inputs;

@end

/*
 * RiveStateMachineInstance
 */
@implementation RiveStateMachineInstance {
    rive::StateMachineInstance *instance;
}

// Creates a new RiveStateMachineInstance from a cpp StateMachine
- (instancetype)initWithStateMachine:(rive::StateMachineInstance *)stateMachine {
    if (self = [super init]) {
        instance = stateMachine;
        _inputs = [[NSMutableDictionary alloc] init];
        return self;
    } else {
        return nil;
    }
}


- (bool) advanceBy:(double)elapsedSeconds  {
    return instance->advanceAndApply(elapsedSeconds);
}

- (RiveSMIBool *)getBool:(NSString *)name {
    // Create a unique dictionary name for numbers;
    // this lets us use one dictionary for the three different types
    NSString * dictName = [NSString stringWithFormat:@"%@%s", name, "_boo"];
    // Check if the input is already instanced
    if ([_inputs objectForKey:dictName] != nil) {
        return _inputs[dictName];
    }
    // Otherwise, try to retrieve from runtime
    std::string stdName = std::string([name UTF8String]);
    rive::SMIBool *smi = instance->getBool(stdName);
    if (smi == nullptr) {
        return NULL;
    } else {
        _inputs[dictName] = [[RiveSMIBool alloc] initWithSMIInput: smi];
        return _inputs[dictName];
    }
}

- (RiveSMITrigger *)getTrigger:(NSString *)name {
    // Create a unique dictionary name for numbers;
    // this lets us use one dictionary for the three different types
    NSString * dictName = [NSString stringWithFormat:@"%@%s", name, "_trg"];
    // Check if the input is already instanced
    if ([_inputs objectForKey:dictName] != nil) {
        return _inputs[dictName];
    }
    // Otherwise, try to retrieve from runtime
    std::string stdName = std::string([name UTF8String]);
    rive::SMITrigger *smi = instance->getTrigger(stdName);
    if (smi == nullptr) {
        return NULL;
    } else {
        _inputs[dictName] = [[RiveSMITrigger alloc] initWithSMIInput: smi];
        return _inputs[dictName];
    }
}

- (RiveSMINumber *)getNumber:(NSString *)name {
    // Create a unique dictionary name for numbers;
    // this lets us use one dictionary for the three different types
    NSString * dictName = [NSString stringWithFormat:@"%@%s", name, "_num"];
    // Check if the input is already instanced
    if ([_inputs objectForKey:dictName] != nil) {
        return _inputs[dictName];
    }
    // Otherwise, try to retrieve from runtime
    std::string stdName = std::string([name UTF8String]);
    rive::SMINumber *smi = instance->getNumber(stdName);
    if (smi == nullptr) {
        return NULL;
    } else {
        _inputs[dictName] = [[RiveSMINumber alloc] initWithSMIInput: smi];;
        return _inputs[dictName];
    }
}

- (NSString *)name {
    std::string str = instance->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

- (NSInteger)inputCount{
    return instance->inputCount();
}

- (RiveSMIInput *)_convertInput:(const rive::SMIInput *)input error:(NSError**)error {
    if (input->input()->is<rive::StateMachineBool>()){
        return [[RiveSMIBool alloc] initWithSMIInput: input];
    }
    else if (input->input()->is<rive::StateMachineNumber>()){
        return [[RiveSMINumber alloc] initWithSMIInput: input];
    }
    else if (input->input()->is<rive::StateMachineTrigger>()){
        return [[RiveSMITrigger alloc] initWithSMIInput: input];
    }
    else {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveUnknownStateMachineInput userInfo:@{NSLocalizedDescriptionKey: @"Unknown State Machine Input", @"name": @"UnknownStateMachineInput"}];
        return nil;
    }
}

// Creates a new instance of this state machine
- (RiveSMIInput *)inputFromIndex:(NSInteger)index error:(NSError**)error {
    if (index >= [self inputCount]) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoStateMachineInputFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No Input found at index %ld.", (long)index], @"name": @"NoStateMachineInputFound"}];
        return nil;
    }
    return [self _convertInput: instance->input(index) error:error];
}

// Creates a new instance of this state machine
- (RiveSMIInput *)inputFromName:(NSString*)name error:(NSError**)error {
    std::string stdName = std::string([name UTF8String]);
    
    RiveSMIInput* input = [RiveSMIInput alloc];
    for (int i=0; i< [self inputCount]; i++) {
        input = [self inputFromIndex: i error:error];
        if (input == nil) {
            return nil;
        }
        if ([[input name] isEqualToString: name]){
            return input;
        }
    }
    *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoStateMachineInputFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No State Machine Input found with name %@.", name], @"name": @"NoStateMachineInputFound"}];
    return nil;
}

- (NSArray *)inputNames{
    NSMutableArray *inputNames = [NSMutableArray array];
    
    for (NSUInteger i=0; i<[self inputCount]; i++){
        [inputNames addObject:[[self inputFromIndex: i error:nil] name]];
    }
    return inputNames;
}

- (NSInteger)stateChangedCount{
    return instance->stateChangedCount();
}

- (RiveLayerState *)_convertLayerState:(const rive::LayerState *)layerState{
    if (layerState->is<rive::EntryState>()){
        return [[RiveEntryState alloc] initWithLayerState: layerState];
    }
    else if (layerState->is<rive::AnyState>()){
        return [[RiveAnyState alloc] initWithLayerState: layerState];
    }
    else if (layerState->is<rive::ExitState>()){
        return [[RiveExitState alloc] initWithLayerState: layerState];
    }
    else if (layerState->is<rive::AnimationState>()){
        return [[RiveAnimationState alloc] initWithLayerState: layerState];
    }
    else {
        return [[RiveUnknownState alloc] initWithLayerState: layerState];
    }
}

- (RiveLayerState *)stateChangedFromIndex:(NSInteger)index error:(NSError**)error {
    const rive::LayerState *layerState = instance->stateChangedByIndex(index);
    if (layerState == nullptr) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoStateChangeFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No State Changed found at index %ld.", (long)index], @"name": @"NoStateChangeFound"}];
        return nil;
    } else {
        return [self _convertLayerState: layerState];
    }
}
- (NSArray *)stateChanges{
    NSMutableArray *inputNames = [NSMutableArray array];
    
    for (NSUInteger i=0; i<[self stateChangedCount]; i++){
        [inputNames addObject:[[self stateChangedFromIndex: i error:nil] name]];
    }
    return inputNames;
}

- (void)touchBeganAtLocation:(CGPoint)touchLocation {
    instance->pointerDown(rive::Vec2D(touchLocation.x, touchLocation.y));
    NSLog(@"SMI: pointerDown at x:%f, y:%f", touchLocation.x, touchLocation.y);
}

- (void)touchMovedAtLocation:(CGPoint)touchLocation {
    instance->pointerMove(rive::Vec2D(touchLocation.x, touchLocation.y));
}

- (void)touchEndedAtLocation:(CGPoint)touchLocation {
    instance->pointerUp(rive::Vec2D(touchLocation.x, touchLocation.y));
}

- (void)touchCancelledAtLocation:(CGPoint)touchLocation {
    instance->pointerUp(rive::Vec2D(touchLocation.x, touchLocation.y));
}

- (NSInteger)layerCount {
    auto machine = instance->stateMachine();
    return machine->layerCount();
}

- (void)dealloc {
    delete instance;
}

@end
