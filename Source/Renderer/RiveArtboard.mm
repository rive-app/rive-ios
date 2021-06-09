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
- (RiveLinearAnimation *)firstAnimation {
    rive::LinearAnimation *animation = _artboard->firstAnimation();
    if (animation == nullptr) {
        @throw [[RiveException alloc] initWithName:@"NoAnimations" reason:@"No Animations found." userInfo:nil];
    }
    else {
        return [[RiveLinearAnimation alloc] initWithAnimation:animation];
    }
    
}

- (RiveLinearAnimation *)animationFromIndex:(NSInteger)index {
    if (index < 0 || index >= [self animationCount]) {
        @throw [[RiveException alloc] initWithName:@"NoAnimationFound" reason:[NSString stringWithFormat: @"No Animation found at index %ld.", (long)index] userInfo:nil];
    }
    return [[RiveLinearAnimation alloc] initWithAnimation: _artboard->animation(index)];
}

- (RiveLinearAnimation *)animationFromName:(NSString *)name {
    std::string stdName = std::string([name UTF8String]);
    rive::LinearAnimation *animation = _artboard->animation(stdName);
    if (animation == nullptr) {
        @throw [[RiveException alloc] initWithName:@"NoAnimationFound" reason:[NSString stringWithFormat: @"No Animation found with name %@.", name] userInfo:nil];
    }
    return [[RiveLinearAnimation alloc] initWithAnimation: animation];
}

- (NSArray *)animationNames{
    NSMutableArray *animationNames = [NSMutableArray array];
    
    for (NSUInteger i=0; i<[self animationCount]; i++){
        [animationNames addObject:[[self animationFromIndex: i] name]];
    }
    return animationNames;
}

// Returns the number of state machines in the artboard
- (NSInteger)stateMachineCount {
    return _artboard->stateMachineCount();
}

- (RiveStateMachine *)firstStateMachine {
    rive::StateMachine *stateMachine = _artboard->firstStateMachine();
    if (stateMachine == nullptr) {
        @throw [[RiveException alloc] initWithName:@"NoStateMachines" reason:@"No State Machines found." userInfo:nil];
    }
    else {
        return [[RiveStateMachine alloc] initWithStateMachine:stateMachine];
    }
}

// Returns a state machine at the given index, or null if the index is invalid
- (RiveStateMachine *)stateMachineFromIndex:(NSInteger)index {
    if (index < 0 || index >= [self stateMachineCount]) {
        @throw [[RiveException alloc] initWithName:@"NoStateMachineFound" reason:[NSString stringWithFormat: @"No State Machine found at index %ld.", (long)index] userInfo:nil];
    }
    return [[RiveStateMachine alloc] initWithStateMachine: _artboard->stateMachine(index)];
}

// Returns a state machine with the given name, or null if none exists
- (RiveStateMachine *)stateMachineFromName:(NSString *)name {
    std::string stdName = std::string([name UTF8String]);
    rive::StateMachine *machine = _artboard->stateMachine(stdName);
    if (machine == nullptr) {
        @throw [[RiveException alloc] initWithName:@"NoStateMachineFound" reason:[NSString stringWithFormat: @"No State Machine found with name %@.", name] userInfo:nil];
    }
    return [[RiveStateMachine alloc] initWithStateMachine: machine];
}

- (NSArray *)stateMachineNames{
    NSMutableArray *stateMachineNames = [NSMutableArray array];
    
    for (NSUInteger i=0; i<[self stateMachineCount]; i++){
        [stateMachineNames addObject:[[self stateMachineFromIndex: i] name]];
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
