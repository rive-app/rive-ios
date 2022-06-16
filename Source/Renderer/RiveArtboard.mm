//
//  RiveArtboard.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>


// MARK: - RiveArtboard
@implementation RiveArtboard

- (instancetype)initWithArtboard:(rive::ArtboardInstance *)riveArtboard {
    if (self = [super init]) {
        _instance = riveArtboard;
        return self;
    } else {
        return NULL;
    }
}

- (RiveScene *)defaultScene:(NSError **)error {
    auto scene = _instance->defaultScene();
    if (scene == nullptr) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoStateMachineFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No default Scene found."], @"name": @"NoSceneFound"}];
        return nil;
    }
    return [[RiveScene alloc] initWithScene:scene.release()];
}

- (NSInteger)animationCount {
    return _instance->animationCount();
}

- (RiveLinearAnimationInstance *)animationFromIndex:(NSInteger)index error:(NSError**) error {
    if (index < 0 || index >= [self animationCount]) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoAnimationFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No Animation found at index %ld.", (long)index], @"name": @"NoAnimationFound"}];
        return nil;
    }
    return [[RiveLinearAnimationInstance alloc] initWithAnimation: _instance->animationAt(index).release()];
}

- (RiveLinearAnimationInstance *)animationFromName:(NSString *)name error:(NSError**) error {
    std::string stdName = std::string([name UTF8String]);
    rive::LinearAnimationInstance *animation = _instance->animationNamed(stdName).release();
    if (animation == nullptr) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoAnimationFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No Animation found with name %@.", name], @"name": @"NoAnimationFound"}];
        return nil;
    }
    return [[RiveLinearAnimationInstance alloc] initWithAnimation: animation];
}

- (NSArray *)animationNames{
    NSMutableArray *animationNames = [NSMutableArray array];
    for (NSUInteger i=0; i<[self animationCount]; i++){
        [animationNames addObject:[[self animationFromIndex:i error:nil] name]];
    }
    return animationNames;
}

/// Returns the number of state machines in the artboard
- (NSInteger)stateMachineCount {
    return _instance->stateMachineCount();
}

- (RiveStateMachineInstance *)defaultStateMachine:(NSError **)error {
    rive::StateMachineInstance *machine = _instance->defaultStateMachine().release();
    if (machine == nullptr) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoStateMachineFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No default State Machine found."], @"name": @"NoStateMachineFound"}];
        return nil;
    }
    return [[RiveStateMachineInstance alloc] initWithStateMachine:machine];
}

/// Returns a state machine at the given index, or null if the index is invalid
- (RiveStateMachineInstance *)stateMachineFromIndex:(NSInteger)index error:(NSError**)error {
    if (index < 0 || index >= [self stateMachineCount]) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoStateMachineFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No State Machine found at index %ld.", (long)index], @"name": @"NoStateMachineFound"}];
        return nil;
    }
    return [[RiveStateMachineInstance alloc] initWithStateMachine: _instance->stateMachineAt(index).release()];
}

/// Returns a state machine with the given name, or null if none exists
- (RiveStateMachineInstance *)stateMachineFromName:(NSString *)name error:(NSError**)error {
    std::string stdName = std::string([name UTF8String]);
    rive::StateMachineInstance *machine = _instance->stateMachineNamed(stdName).release();
    if (machine == nullptr) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoStateMachineFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No State Machine found with name %@.", name], @"name": @"NoStateMachineFound"}];
        return nil;
    }
    return [[RiveStateMachineInstance alloc] initWithStateMachine: machine];
}

- (NSArray *)stateMachineNames{
    NSMutableArray *stateMachineNames = [NSMutableArray array];
    for (NSUInteger i=0; i<[self stateMachineCount]; i++){
        [stateMachineNames addObject:[[self stateMachineFromIndex:i error:nil] name]];
    }
    return stateMachineNames;
}


- (void)advanceBy:(double)elapsedSeconds {
    _instance->advance(elapsedSeconds);
}

// This isn't used. RiveRendererView gets the Artboard's instance property and calls
// instance->draw(_renderer) itself. It's because we're not using RiveRenderer; we're
// using SkiaRenderer.
- (void)draw:(RiveRenderer *)renderer {
    _instance->draw([renderer renderer]);
}

- (NSString *)name {
    std::string str = _instance->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

- (CGRect)bounds {
    rive::AABB aabb = _instance->bounds();
    return CGRectMake(aabb.minX, aabb.minY, aabb.width(), aabb.height());
}

- (void)dealloc {
     delete _instance;
}

@end
