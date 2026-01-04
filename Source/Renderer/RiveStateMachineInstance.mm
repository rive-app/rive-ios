//
//  RiveStateMachineInstance.mm
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <RiveRuntime/RiveRuntime-Swift.h>

// MARK: - Globals

static int smInstanceCount = 0;

/// Returns a RiveHitResult value, converting from the Rive C++ type.
RiveHitResult RiveHitResultFromRuntime(rive::HitResult result)
{
    if (result == rive::HitResult::none)
    {
        return none;
    }
    else if (result == rive::HitResult::hit)
    {
        return hit;
    }
    else if (result == rive::HitResult::hitOpaque)
    {
        return hitOpaque;
    }
    else
    {
        return none;
    }
}

// MARK: - RiveStateMachineInstance

@interface RiveStateMachineInstance ()

/// Holds references to SMIInputs
@property NSMutableDictionary* inputs;

@end

@implementation RiveStateMachineInstance
{
    std::unique_ptr<rive::StateMachineInstance> instance;
}

// MARK: Lifecycle

// Creates a new RiveStateMachineInstance from a cpp StateMachine
- (instancetype)initWithStateMachine:
    (std::unique_ptr<rive::StateMachineInstance>)stateMachine
{
    if (self = [super init])
    {
#if RIVE_ENABLE_REFERENCE_COUNTING
        [RiveStateMachineInstance raiseInstanceCount];
#endif // RIVE_ENABLE_REFERENCE_COUNTING

        instance = std::move(stateMachine);
        _inputs = [[NSMutableDictionary alloc] init];
        return self;
    }
    else
    {
        return nil;
    }
}

- (void)dealloc
{
#if RIVE_ENABLE_REFERENCE_COUNTING
    [RiveStateMachineInstance reduceInstanceCount];
#endif // RIVE_ENABLE_REFERENCE_COUNTING

    instance.reset(nullptr);
}

// MARK: Reference Counting

+ (int)instanceCount
{
    return smInstanceCount;
}

+ (void)raiseInstanceCount
{
    smInstanceCount++;
    NSLog(@"+ StateMachine: %d", smInstanceCount);
}

+ (void)reduceInstanceCount
{
    smInstanceCount--;
    NSLog(@"- StateMachine: %d", smInstanceCount);
}

// MARK: C++ Bindings

- (bool)advanceBy:(double)elapsedSeconds
{
    [RiveLogger logStateMachine:self advance:elapsedSeconds];
    return instance->advanceAndApply(elapsedSeconds);
}

- (RiveSMIBool*)getBool:(NSString*)name
{
    // Create a unique dictionary name for numbers;
    // this lets us use one dictionary for the three different types
    NSString* dictName = [NSString stringWithFormat:@"%@%s", name, "_boo"];
    // Check if the input is already instanced
    if ([_inputs objectForKey:dictName] != nil)
    {
        return _inputs[dictName];
    }
    // Otherwise, try to retrieve from runtime
    std::string stdName = std::string([name UTF8String]);
    rive::SMIBool* smi = instance->getBool(stdName);
    if (smi == nullptr)
    {
        [RiveLogger
            logStateMachine:self
                      error:[NSString
                                stringWithFormat:
                                    @"Could not find input named %@", name]];
        return NULL;
    }
    else
    {
        _inputs[dictName] = [[RiveSMIBool alloc] initWithSMIInput:smi];
        return _inputs[dictName];
    }
}

- (RiveSMITrigger*)getTrigger:(NSString*)name
{
    // Create a unique dictionary name for numbers;
    // this lets us use one dictionary for the three different types
    NSString* dictName = [NSString stringWithFormat:@"%@%s", name, "_trg"];
    // Check if the input is already instanced
    if ([_inputs objectForKey:dictName] != nil)
    {
        return _inputs[dictName];
    }
    // Otherwise, try to retrieve from runtime
    std::string stdName = std::string([name UTF8String]);
    rive::SMITrigger* smi = instance->getTrigger(stdName);
    if (smi == nullptr)
    {
        [RiveLogger
            logStateMachine:self
                      error:[NSString
                                stringWithFormat:
                                    @"Could not find trigger named %@", name]];
        return NULL;
    }
    else
    {
        _inputs[dictName] = [[RiveSMITrigger alloc] initWithSMIInput:smi];
        return _inputs[dictName];
    }
}

- (RiveSMINumber*)getNumber:(NSString*)name
{
    // Create a unique dictionary name for numbers;
    // this lets us use one dictionary for the three different types
    NSString* dictName = [NSString stringWithFormat:@"%@%s", name, "_num"];
    // Check if the input is already instanced
    if ([_inputs objectForKey:dictName] != nil)
    {
        return _inputs[dictName];
    }
    // Otherwise, try to retrieve from runtime
    std::string stdName = std::string([name UTF8String]);
    rive::SMINumber* smi = instance->getNumber(stdName);
    if (smi == nullptr)
    {
        [RiveLogger
            logStateMachine:self
                      error:[NSString
                                stringWithFormat:
                                    @"Could not find input named %@", name]];
        return NULL;
    }
    else
    {
        _inputs[dictName] = [[RiveSMINumber alloc] initWithSMIInput:smi];
        ;
        return _inputs[dictName];
    }
}

- (NSString*)name
{
    std::string str = instance->name();
    return [NSString stringWithCString:str.c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

- (NSInteger)inputCount
{
    return instance->inputCount();
}

- (RiveSMIInput*)_convertInput:(const rive::SMIInput*)input
                         error:(NSError**)error
{
    if (input->input()->is<rive::StateMachineBool>())
    {
        return [[RiveSMIBool alloc] initWithSMIInput:input];
    }
    else if (input->input()->is<rive::StateMachineNumber>())
    {
        return [[RiveSMINumber alloc] initWithSMIInput:input];
    }
    else if (input->input()->is<rive::StateMachineTrigger>())
    {
        return [[RiveSMITrigger alloc] initWithSMIInput:input];
    }
    else
    {
        *error = [NSError errorWithDomain:RiveErrorDomain
                                     code:RiveUnknownStateMachineInput
                                 userInfo:@{
                                     NSLocalizedDescriptionKey :
                                         @"Unknown State Machine Input",
                                     @"name" : @"UnknownStateMachineInput"
                                 }];
        return nil;
    }
}

// Creates a new instance of this state machine
- (RiveSMIInput*)inputFromIndex:(NSInteger)index error:(NSError**)error
{
    if (index >= [self inputCount])
    {
        *error = [NSError
            errorWithDomain:RiveErrorDomain
                       code:RiveNoStateMachineInputFound
                   userInfo:@{
                       NSLocalizedDescriptionKey : [NSString
                           stringWithFormat:@"No Input found at index %ld.",
                                            (long)index],
                       @"name" : @"NoStateMachineInputFound"
                   }];
        return nil;
    }
    return [self _convertInput:instance->input(index) error:error];
}

// Creates a new instance of this state machine
- (RiveSMIInput*)inputFromName:(NSString*)name error:(NSError**)error
{
    std::string stdName = std::string([name UTF8String]);

    RiveSMIInput* input = [RiveSMIInput alloc];
    for (int i = 0; i < [self inputCount]; i++)
    {
        input = [self inputFromIndex:i error:error];
        if (input == nil)
        {
            return nil;
        }
        if ([[input name] isEqualToString:name])
        {
            return input;
        }
    }
    *error = [NSError
        errorWithDomain:RiveErrorDomain
                   code:RiveNoStateMachineInputFound
               userInfo:@{
                   NSLocalizedDescriptionKey : [NSString
                       stringWithFormat:
                           @"No State Machine Input found with name %@.", name],
                   @"name" : @"NoStateMachineInputFound"
               }];
    return nil;
}

- (NSArray*)inputNames
{
    NSMutableArray* inputNames = [NSMutableArray array];

    for (NSUInteger i = 0; i < [self inputCount]; i++)
    {
        RiveSMIInput* input = [self inputFromIndex:i error:nil];
        if (input != nil)
        {
            [inputNames addObject:[input name]];
        }
    }
    return inputNames;
}

- (NSInteger)stateChangedCount
{
    return instance->stateChangedCount();
}

- (NSInteger)reportedEventCount
{
    return instance->reportedEventCount();
}

- (RiveEvent*)_convertEvent:(const rive::Event*)event delay:(float)delay
{
    if (event->is<rive::OpenUrlEvent>())
    {
        return [[RiveOpenUrlEvent alloc] initWithRiveEvent:event delay:delay];
    }
    else if (event->is<rive::Event>())
    {
        return [[RiveGeneralEvent alloc] initWithRiveEvent:event delay:delay];
    }
    return nil;
}

- (RiveLayerState*)_convertLayerState:(const rive::LayerState*)layerState
{
    if (layerState->is<rive::EntryState>())
    {
        return [[RiveEntryState alloc] initWithLayerState:layerState];
    }
    else if (layerState->is<rive::AnyState>())
    {
        return [[RiveAnyState alloc] initWithLayerState:layerState];
    }
    else if (layerState->is<rive::ExitState>())
    {
        return [[RiveExitState alloc] initWithLayerState:layerState];
    }
    else if (layerState->is<rive::AnimationState>())
    {
        return [[RiveAnimationState alloc] initWithLayerState:layerState];
    }
    else
    {
        return [[RiveUnknownState alloc] initWithLayerState:layerState];
    }
}

- (RiveEvent*)reportedEventAt:(NSInteger)index
{
    const rive::EventReport report = instance->reportedEventAt(index);
    const rive::Event* event = report.event();
    if (event == nullptr)
    {
        return nil;
    }
    else
    {
        return [self _convertEvent:event delay:report.secondsDelay()];
    }
}

- (RiveLayerState*)stateChangedFromIndex:(NSInteger)index error:(NSError**)error
{
    const rive::LayerState* layerState = instance->stateChangedByIndex(index);
    if (layerState == nullptr)
    {
        *error =
            [NSError errorWithDomain:RiveErrorDomain
                                code:RiveNoStateChangeFound
                            userInfo:@{
                                NSLocalizedDescriptionKey : [NSString
                                    stringWithFormat:
                                        @"No State Changed found at index %ld.",
                                        (long)index],
                                @"name" : @"NoStateChangeFound"
                            }];
        return nil;
    }
    else
    {
        return [self _convertLayerState:layerState];
    }
}
- (NSArray*)stateChanges
{
    NSMutableArray* inputNames = [NSMutableArray array];

    for (NSUInteger i = 0; i < [self stateChangedCount]; i++)
    {
        RiveLayerState* state = [self stateChangedFromIndex:i error:nil];
        if (state != nil)
        {
            [inputNames addObject:[state name]];
        }
    }
    return inputNames;
}

- (NSInteger)layerCount
{
    auto machine = instance->stateMachine();
    return machine->layerCount();
}

// MARK: Touch

- (RiveHitResult)touchBeganAtLocation:(CGPoint)touchLocation
{
    return [self touchBeganAtLocation:touchLocation touchID:0];
}

- (RiveHitResult)touchBeganAtLocation:(CGPoint)touchLocation
                              touchID:(int)touchID
{
    return RiveHitResultFromRuntime(instance->pointerDown(
        rive::Vec2D(touchLocation.x, touchLocation.y), touchID));
}

- (RiveHitResult)touchMovedAtLocation:(CGPoint)touchLocation
{
    return [self touchMovedAtLocation:touchLocation touchID:0];
}

- (RiveHitResult)touchMovedAtLocation:(CGPoint)touchLocation
                              touchID:(int)touchID
{
    return RiveHitResultFromRuntime(instance->pointerMove(
        rive::Vec2D(touchLocation.x, touchLocation.y), 0, touchID));
}

- (RiveHitResult)touchEndedAtLocation:(CGPoint)touchLocation
{
    return [self touchEndedAtLocation:touchLocation touchID:0];
}

- (RiveHitResult)touchEndedAtLocation:(CGPoint)touchLocation
                              touchID:(int)touchID
{
    return RiveHitResultFromRuntime(instance->pointerUp(
        rive::Vec2D(touchLocation.x, touchLocation.y), touchID));
}

- (RiveHitResult)touchCancelledAtLocation:(CGPoint)touchLocation
{
    return [self touchCancelledAtLocation:touchLocation touchID:0];
}

- (RiveHitResult)touchCancelledAtLocation:(CGPoint)touchLocation
                                  touchID:(int)touchID
{
    return RiveHitResultFromRuntime(instance->pointerUp(
        rive::Vec2D(touchLocation.x, touchLocation.y), touchID));
}

- (RiveHitResult)touchExitedAtLocation:(CGPoint)touchLocation
{
    return [self touchExitedAtLocation:touchLocation touchID:0];
}

- (RiveHitResult)touchExitedAtLocation:(CGPoint)touchLocation
                               touchID:(int)touchID
{
    return RiveHitResultFromRuntime(instance->pointerExit(
        rive::Vec2D(touchLocation.x, touchLocation.y), touchID));
}

#pragma mark - Data Binding

// Argument named i to not conflict with higher-level private variable named
// instance
- (void)bindViewModelInstance:(RiveDataBindingViewModelInstance*)i
{
    // Let's walk through the instances of the word instance
    //
    // instance is the underlying c++ type of ourself
    // to which we bind
    //
    // i is the ObjC bridging type of the underlying
    // c++ type of a view model instance.
    //
    // i.instance is the underlying c++ type of the bridging type
    // so that we can call into the c++ runtime
    //
    // i.instance->instance() is the c++ rcp of the actual
    // type that gets bound to the state machine
    instance->bindViewModelInstance(i.instance->instance());
    _viewModelInstance = i;
    [RiveLogger logStateMachine:self instanceBind:i.name];
}

@end
