//
//  RiveStateMachineInstance.mm
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>

/*
 * RiveStateMachineInstance
 */
@implementation RiveStateMachineInstance {
    const rive::StateMachine *stateMachine;
    rive::StateMachineInstance *instance;
}

// Creates a new RiveStateMachineInstance from a cpp StateMachine
- (instancetype)initWithStateMachine:(const rive::StateMachine *)stateMachine {
    if (self = [super init]) {
        self->stateMachine = stateMachine;
        instance = new rive::StateMachineInstance(stateMachine);
        return self;
    } else {
        return nil;
    }
}

- (void) applyTo:(RiveArtboard*)artboard {
    instance->apply(artboard.artboard);
}

- (bool) advanceBy:(double)elapsedSeconds {
    return instance->advance(elapsedSeconds);
}

- (RiveStateMachine *)stateMachine {
    const rive::StateMachine *stateMachine = instance->stateMachine();
    return [[RiveStateMachine alloc] initWithStateMachine: stateMachine];
}

- (RiveSMIBool *)getBool:(NSString *) name {
    std::string stdName = std::string([name UTF8String]);
    rive::SMIBool *smi = instance->getBool(stdName);
    if (smi == nullptr) {
        return NULL;
    } else {
        return [[RiveSMIBool alloc] initWithSMIInput: smi];
    }
}

- (RiveSMITrigger *)getTrigger:(NSString *) name {
    std::string stdName = std::string([name UTF8String]);
    rive::SMITrigger *smi = instance->getTrigger(stdName);
    if (smi == nullptr) {
        return NULL;
    } else {
        return [[RiveSMITrigger alloc] initWithSMIInput: smi];
    }
}

- (RiveSMINumber *)getNumber:(NSString *) name {
    std::string stdName = std::string([name UTF8String]);
    rive::SMINumber *smi = instance->getNumber(stdName);
    if (smi == nullptr) {
        return NULL;
    } else {
        return [[RiveSMINumber alloc] initWithSMIInput: smi];
    }
}

- (NSString *)name {
    std::string str = stateMachine->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

- (NSInteger)inputCount{
    return instance->inputCount();
}

- (RiveSMIInput *)_convertInput:(const rive::SMIInput *)input{
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
        @throw [[RiveException alloc] initWithName:@"UnkownInput" reason: @"Unknown State Machine Input" userInfo:nil];
    }
}

// Creates a new instance of this state machine
- (RiveSMIInput *)inputFromIndex:(NSInteger)index {
    if (index >= [self inputCount]) {
        @throw [[RiveException alloc] initWithName:@"NoStateMachineInputFound" reason:[NSString stringWithFormat: @"No Input found at index %ld.", index] userInfo:nil];
    }
    return [self _convertInput: instance->input(index) ];
}

// Creates a new instance of this state machine
- (RiveSMIInput *)inputFromName:(NSString*)name {
    std::string stdName = std::string([name UTF8String]);
    
    RiveSMIInput* input = [RiveSMIInput alloc];
    for (int i=0; i< [self inputCount]; i++) {
        input = [self inputFromIndex: i];
        if ([[input name] isEqualToString: name]){
            return input;
        }
    }
    @throw [[RiveException alloc] initWithName:@"NoStateMachineInputFound" reason:[NSString stringWithFormat: @"No State Machine Input found with name %@.", name] userInfo:nil];
}

- (NSArray *)inputNames{
    NSMutableArray *inputNames = [NSMutableArray array];
    
    for (NSUInteger i=0; i<[self inputCount]; i++){
        [inputNames addObject:[[self inputFromIndex: i] name]];
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
        @throw [[RiveException alloc] initWithName:@"UnkownLayerState" reason: @"Unknown Layer State" userInfo:nil];
    }
}

- (RiveLayerState *)stateChangedFromIndex:(NSInteger)index{
    const rive::LayerState *layerState = instance->stateChangedByIndex(index);
    if (layerState == nullptr) {
        @throw [[RiveException alloc] initWithName:@"NoStateChangeFound" reason:[NSString stringWithFormat: @"No State Changed found at index %lu.", index] userInfo:nil];
    } else {
        return [self _convertLayerState: layerState];
    }
}
- (NSArray *)stateChanges{
    NSMutableArray *inputNames = [NSMutableArray array];
    
    for (NSUInteger i=0; i<[self stateChangedCount]; i++){
        [inputNames addObject:[[self stateChangedFromIndex: i] name]];
    }
    return inputNames;
}

@end
