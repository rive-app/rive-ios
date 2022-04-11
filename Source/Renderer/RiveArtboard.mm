//
//  RiveArtboard.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>

/*
 * RiveArtboard
 */
@implementation RiveArtboard

- (instancetype)initWithArtboard:(rive::ArtboardInstance *)riveArtboard {
    if (self = [super init]) {
        _artboardInstance = riveArtboard;
        return self;
    } else {
        return NULL;
    }
}

- (NSInteger)animationCount {
    return _artboardInstance->animationCount();
}

// Returns the first animation in the artboard, or null if it has none
- (RiveLinearAnimationInstance *)firstAnimation:(NSError**) error {
    return [self animationFromIndex:0 error:error];
}

- (RiveLinearAnimationInstance *)animationFromIndex:(NSInteger)index error:(NSError**) error {
    auto animInst = _artboardInstance->animationAt(index);
    if (animInst == nullptr) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoAnimationFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No Animation found at index %ld.", (long)index], @"name": @"NoAnimationFound"}];
        return nil;
    }
    return [[RiveLinearAnimationInstance alloc] initWithAnimationInstance:animInst.release()];
}

- (RiveLinearAnimationInstance *)animationFromName:(NSString *)name error:(NSError**) error {
    auto animInst = _artboardInstance->animationNamed(std::string([name UTF8String]));
    if (animInst == nullptr) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoAnimationFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No Animation found with name %@.", name], @"name": @"NoAnimationFound"}];
        return nil;
    }
    return [[RiveLinearAnimationInstance alloc] initWithAnimationInstance:animInst.release()];
}

- (NSArray *)animationNames{
    NSMutableArray *animationNames = [NSMutableArray array];
    for (NSUInteger i=0; i<[self animationCount]; i++){
        [animationNames addObject:[[self animationFromIndex:i error:nil] name]];
    }
    return animationNames;
}

// Returns the number of state machines in the artboard
- (NSInteger)stateMachineCount {
    return _artboardInstance->stateMachineCount();
}

- (RiveStateMachine *)firstStateMachine:(NSError**)error {
    rive::StateMachine *stateMachine = _artboardInstance->firstStateMachine();
    if (stateMachine == nullptr) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoStateMachines userInfo:@{NSLocalizedDescriptionKey: @"No State Machines found.", @"name": @"NoStateMachines"}];
        return nil;
    }
    else {
        return [[RiveStateMachine alloc] initWithStateMachine:stateMachine];
    }
}

// Returns a state machine at the given index, or null if the index is invalid
- (RiveStateMachine *)stateMachineFromIndex:(NSInteger)index error:(NSError**)error {
    if (index < 0 || index >= [self stateMachineCount]) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoStateMachineFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No State Machine found at index %ld.", (long)index], @"name": @"NoStateMachineFound"}];
        return nil;
    }
    return [[RiveStateMachine alloc] initWithStateMachine: _artboardInstance->stateMachine(index)];
}

// Returns a state machine with the given name, or null if none exists
- (RiveStateMachine *)stateMachineFromName:(NSString *)name error:(NSError**)error {
    std::string stdName = std::string([name UTF8String]);
    rive::StateMachine *machine = _artboardInstance->stateMachine(stdName);
    if (machine == nullptr) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoStateMachineFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No State Machine found with name %@.", name], @"name": @"NoStateMachineFound"}];
        return nil;
    }
    return [[RiveStateMachine alloc] initWithStateMachine: machine];
}

- (NSArray *)stateMachineNames{
    NSMutableArray *stateMachineNames = [NSMutableArray array];
    for (NSUInteger i=0; i<[self stateMachineCount]; i++){
        [stateMachineNames addObject:[[self stateMachineFromIndex:i error:nil] name]];
    }
    return stateMachineNames;
}


- (void)advanceBy:(double)elapsedSeconds {
    _artboardInstance->advance(elapsedSeconds);
}

- (void)draw:(RiveRenderer *)renderer {
    _artboardInstance->draw([renderer renderer]);
}

- (NSString *)name {
    std::string str = _artboardInstance->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

- (CGRect)bounds {
    rive::AABB aabb = _artboardInstance->bounds();
    return CGRectMake(aabb.minX, aabb.minY, aabb.width(), aabb.height());
}

- (void)dealloc {
     delete _artboardInstance;
}

@end
