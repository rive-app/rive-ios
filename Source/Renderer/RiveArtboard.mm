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

- (instancetype)initWithArtboard:(rive::Artboard *)riveArtboard {
    if (self = [super init]) {
        _artboard = riveArtboard;
        return self;
    } else {
        return NULL;
    }
}

- (NSInteger)animationCount {
    return _artboard->animationCount();
}

// Returns the first animation in the artboard, or null if it has none
- (RiveLinearAnimation *)firstAnimation:(NSError**) error {
    rive::LinearAnimation *animation = _artboard->firstAnimation();
    if (animation == nullptr) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoAnimations userInfo:@{NSLocalizedDescriptionKey: @"No Animations found.", @"name": @"NoAnimations"}];
        return nil;
    }
    else {
        return [[RiveLinearAnimation alloc] initWithAnimation:animation];
    }
    
}

- (RiveLinearAnimation *)animationFromIndex:(NSInteger)index error:(NSError**) error {
    if (index < 0 || index >= [self animationCount]) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoAnimationFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No Animation found at index %ld.", (long)index], @"name": @"NoAnimationFound"}];
        return nil;
    }
    return [[RiveLinearAnimation alloc] initWithAnimation: _artboard->animation(index)];
}

- (RiveLinearAnimation *)animationFromName:(NSString *)name error:(NSError**) error {
    std::string stdName = std::string([name UTF8String]);
    rive::LinearAnimation *animation = _artboard->animation(stdName);
    if (animation == nullptr) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoAnimationFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No Animation found with name %@.", name], @"name": @"NoAnimationFound"}];
        return nil;
    }
    return [[RiveLinearAnimation alloc] initWithAnimation: animation];
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
    return _artboard->stateMachineCount();
}

- (RiveStateMachine *)firstStateMachine:(NSError**)error {
    rive::StateMachine *stateMachine = _artboard->firstStateMachine();
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
    return [[RiveStateMachine alloc] initWithStateMachine: _artboard->stateMachine(index)];
}

// Returns a state machine with the given name, or null if none exists
- (RiveStateMachine *)stateMachineFromName:(NSString *)name error:(NSError**)error {
    std::string stdName = std::string([name UTF8String]);
    rive::StateMachine *machine = _artboard->stateMachine(stdName);
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
    _artboard->advance(elapsedSeconds);
}

- (void)draw:(RiveRenderer *)renderer {
    _artboard->draw([renderer renderer]);
}

- (NSString *)name {
    std::string str = _artboard->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

- (CGRect)bounds {
    rive::AABB aabb = _artboard->bounds();
    return CGRectMake(aabb.minX, aabb.minY, aabb.width(), aabb.height());
}

// Creates an instance of the artboard
- (RiveArtboard *)instance {
    rive::Artboard *instance = _artboard->instance();
    return [[RiveArtboard alloc] initWithArtboard: instance];
}

- (void)dealloc {
     if (_artboard->isInstance()) {
       delete _artboard;
     }
}

@end
