//
//  RiveArtboard.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>

// MARK: - Globals

static int artInstanceCount = 0;

// MARK: - RiveArtboard

@implementation RiveArtboard

// MARK: LifeCycle

- (instancetype)initWithArtboard:(rive::ArtboardInstance *)riveArtboard {
    if (self = [super init]) {
        
#if RIVE_ENABLE_REFERENCE_COUNTING
        [RiveArtboard raiseInstanceCount];
#endif // RIVE_ENABLE_REFERENCE_COUNTING
        
        _artboardInstance = riveArtboard;
        return self;
    } else {
        return NULL;
    }
}

- (void)dealloc {
#if RIVE_ENABLE_REFERENCE_COUNTING
    [RiveArtboard reduceInstanceCount];
#endif // RIVE_ENABLE_REFERENCE_COUNTING
    
     delete _artboardInstance;
}

// MARK: Reference Counting

+ (int)instanceCount {
    return artInstanceCount;
}

+ (void)raiseInstanceCount {
    artInstanceCount++;
    NSLog(@"+ Artboard: %d", artInstanceCount);
}

+ (void)reduceInstanceCount {
    artInstanceCount--;
    NSLog(@"- Artboard: %d", artInstanceCount);
}

// MARK: C++ Bindings

- (NSInteger)animationCount {
    return _artboardInstance->animationCount();
}

- (RiveLinearAnimationInstance *)animationFromIndex:(NSInteger)index error:(NSError**) error {
    if (index < 0 || index >= [self animationCount]) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoAnimationFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No Animation found at index %ld.", (long)index], @"name": @"NoAnimationFound"}];
        return nil;
    }
    return [[RiveLinearAnimationInstance alloc] initWithAnimation: _artboardInstance->animationAt(index).release()];
}

- (RiveLinearAnimationInstance *)animationFromName:(NSString *)name error:(NSError**) error {
    std::string stdName = std::string([name UTF8String]);
    rive::LinearAnimationInstance *animation = _artboardInstance->animationNamed(stdName).release();
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
    return _artboardInstance->stateMachineCount();
}

/// Returns a state machine at the given index, or null if the index is invalid
- (RiveStateMachineInstance *)stateMachineFromIndex:(NSInteger)index error:(NSError**)error {
    if (index < 0 || index >= [self stateMachineCount]) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoStateMachineFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No State Machine found at index %ld.", (long)index], @"name": @"NoStateMachineFound"}];
        return nil;
    }
    return [[RiveStateMachineInstance alloc] initWithStateMachine: _artboardInstance->stateMachineAt(index).release()];
}

/// Returns a state machine with the given name, or null if none exists
- (RiveStateMachineInstance *)stateMachineFromName:(NSString *)name error:(NSError**)error {
    std::string stdName = std::string([name UTF8String]);
    rive::StateMachineInstance *machine = _artboardInstance->stateMachineNamed(stdName).release();
    if (machine == nullptr) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoStateMachineFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No State Machine found with name %@.", name], @"name": @"NoStateMachineFound"}];
        return nil;
    }
    return [[RiveStateMachineInstance alloc] initWithStateMachine: machine];
}

- (RiveStateMachineInstance *)defaultStateMachine {
    rive::StateMachineInstance *machine = _artboardInstance->defaultStateMachine().release();
    if (machine == nullptr) {
//        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoStateMachineFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No default State Machine found."], @"name": @"NoStateMachineFound"}];
        return nil;
    }
    return [[RiveStateMachineInstance alloc] initWithStateMachine:machine];
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

@end
