//
//  RiveFile.m
//  RiveRuntime
//
//  Created by Matt Sullivan on 8/30/20.
//  Copyright © 2020 Rive. All rights reserved.
//

#import "Rive.h"
#import "RiveRenderer.hpp"

#import "file.hpp"
#import "artboard.hpp"
#import "animation.hpp"
#import "linear_animation.hpp"
#import "linear_animation_instance.hpp"
#import "state_machine.hpp"
#import "state_machine_instance.hpp"

/*
 * RiveStateMachineInstance interface
 */
@interface RiveStateMachineInstance ()
- (instancetype)initWithStateMachine:(const rive::StateMachine *)stateMachine;
@end

/*
 * RiveStateMachine interface
 */
@interface RiveStateMachine ()
- (instancetype)initWithStateMachine:(const rive::StateMachine *)riveStateMachine;
@end

/*
 * RiveLinearAnimationInstance interface
 */
@interface RiveLinearAnimationInstance ()
- (instancetype)initWithAnimation:(const rive::LinearAnimation *)riveAnimation;
@end

/*
 * RiveLinearAnimation interface
 */
@interface RiveLinearAnimation ()
- (instancetype) initWithAnimation:(const rive::LinearAnimation *)riveAnimation;
@end

/*
 * RiveArtboard interface
 */
@interface RiveArtboard ()
@property (nonatomic, readonly) rive::Artboard* artboard;
-(instancetype) initWithArtboard:(rive::Artboard *) riveArtboard;
@end

/*
 * RiveRenderer interface
 */
@interface RiveRenderer ()
@property (nonatomic, readonly) rive::Renderer* renderer;
-(rive::Renderer *) renderer;
@end

/*
 * RiveRenderer
 */
@implementation RiveRenderer {
    CGContextRef ctx;
}

-(instancetype) initWithContext:(CGContextRef) context {
    if (self = [super init]) {
        ctx = context;
        _renderer = new rive::RiveRenderer(context);
        return self;
    } else {
        return nil;
    }
}

-(void) dealloc {
    delete _renderer;
}

-(void) alignWithRect:(CGRect)rect withContentRect:(CGRect)contentRect withAlignment:(Alignment)alignment withFit:(Fit)fit {
//    NSLog(@"Rect in align %@", NSStringFromCGRect(rect));
    
    // Calculate the AABBs
    rive::AABB frame = rive::AABB(rect.origin.x, rect.origin.y, rect.size.width + rect.origin.x, rect.size.height + rect.origin.y);
    rive::AABB content = rive::AABB(contentRect.origin.x, contentRect.origin.y, contentRect.size.width + contentRect.origin.x, contentRect.size.height + contentRect.origin.y);

    // Work out the fit
    rive::Fit riveFit;
    switch(fit) {
        case Fill:
            riveFit = rive::Fit::fill;
            break;
        case Contain:
            riveFit = rive::Fit::contain;
            break;
        case Cover:
            riveFit = rive::Fit::cover;
            break;
        case FitHeight:
            riveFit = rive::Fit::fitHeight;
            break;
        case FitWidth:
            riveFit = rive::Fit::fitWidth;
            break;
        case ScaleDown:
            riveFit = rive::Fit::scaleDown;
            break;
        case None:
            riveFit = rive::Fit::none;
            break;
    }

    // Work out the alignment
    rive::Alignment riveAlignment = rive::Alignment::center;
    switch(alignment) {
        case TopLeft:
            riveAlignment = rive::Alignment::topLeft;
            break;
        case TopCenter:
            riveAlignment = rive::Alignment::topCenter;
            break;
        case TopRight:
            riveAlignment = rive::Alignment::topRight;
            break;
        case CenterLeft:
            riveAlignment = rive::Alignment::centerLeft;
            break;
        case Center:
            riveAlignment = rive::Alignment::center;
            break;
        case CenterRight:
            riveAlignment = rive::Alignment::centerRight;
            break;
        case BottomLeft:
            riveAlignment = rive::Alignment::bottomLeft;
            break;
        case BottomCenter:
            riveAlignment = rive::Alignment::bottomCenter;
            break;
        case BottomRight:
            riveAlignment = rive::Alignment::bottomRight;
            break;
    }
    
    _renderer->align(riveFit, riveAlignment, frame, content);
}

@end

/*
 * RiveFile
 */
@implementation RiveFile {
    rive::File* riveFile;
}

+ (uint)majorVersion { return UInt8(rive::File::majorVersion); }
+ (uint)minorVersion { return UInt8(rive::File::minorVersion); }

- (nullable instancetype)initWithBytes:(UInt8 *)bytes byteLength:(UInt64)length {
    if (self = [super init]) {
        rive::BinaryReader reader = rive::BinaryReader(bytes, length);
        rive::ImportResult result = rive::File::import(reader, &riveFile);
        if (result == rive::ImportResult::success) {
            return self;
        }
    }
    return nil;
}

- (RiveArtboard *)artboard {
    return [[RiveArtboard alloc] initWithArtboard: riveFile->artboard()];
}

- (NSInteger)artboardCount {
    return riveFile->artboardCount();
}

- (RiveArtboard *)artboardFromIndex:(NSInteger) index {
    if (index >= [self artboardCount]) {
        return NULL;
    }
    return [[RiveArtboard alloc]
            initWithArtboard: reinterpret_cast<rive::Artboard *>(riveFile->artboard(index))];
}

- (RiveArtboard *)artboardFromName:(NSString *) name {
    std::string stdName = std::string([name UTF8String]);
    rive::Artboard *artboard = riveFile->artboard(stdName);
    if (artboard == nullptr) {
        return NULL;
    } else {
        return [[RiveArtboard alloc] initWithArtboard: artboard];
    }
}

@end

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
    return [[RiveLinearAnimation alloc] initWithAnimation:_artboard->firstAnimation()];
}

- (RiveLinearAnimation *)animationFromIndex:(NSInteger)index {
    if (index < 0 || index >= [self animationCount]) {
        return NULL;
    }
    return [[RiveLinearAnimation alloc] initWithAnimation: _artboard->animation(index)];
}

- (RiveLinearAnimation *)animationFromName:(NSString *)name {
    std::string stdName = std::string([name UTF8String]);
    rive::LinearAnimation *animation = _artboard->animation(stdName);
    if (animation == nullptr) {
        return NULL;
    }
    return [[RiveLinearAnimation alloc] initWithAnimation: animation];
}

// Returns the number of state machines in the artboard
- (NSInteger)stateMachineCount {
    return _artboard->stateMachineCount();
}

- (RiveStateMachine *)firstStateMachine {
    return [[RiveStateMachine alloc] initWithStateMachine:_artboard->firstStateMachine()];
}

// Returns a state machine at the given index, or null if the index is invalid
- (RiveStateMachine *)stateMachineFromIndex:(NSInteger)index {
    if (index < 0 || index >= [self stateMachineCount]) {
        return NULL;
    }
    return [[RiveStateMachine alloc] initWithStateMachine: _artboard->stateMachine(index)];
}

// Returns a state machine with the given name, or null if none exists
- (RiveStateMachine *)stateMachineFromName:(NSString *)name {
    std::string stdName = std::string([name UTF8String]);
    rive::StateMachine *machine = _artboard->stateMachine(stdName);
    if (machine == nullptr) {
        return NULL;
    }
    return [[RiveStateMachine alloc] initWithStateMachine: machine];
}


- (void)advanceBy:(double)elapsedSeconds {
    _artboard->advance(elapsedSeconds);
}

- (void)draw:(RiveRenderer *)renderer {
    _artboard->draw([renderer renderer]);
}

- (NSString *)name {
    return [NSString stringWithUTF8String:_artboard->name().c_str()];
}

- (CGRect)bounds {
    rive::AABB aabb = _artboard->bounds();
    return CGRectMake(aabb.minX, aabb.minY, aabb.width(), aabb.height());
}

@end

/*
 * RiveLinearAnimation
 */
@implementation RiveLinearAnimation {
    const rive::LinearAnimation *animation;
}

- (instancetype)initWithAnimation:(const rive::LinearAnimation *) riveAnimation {
    if (self = [super init]) {
        animation = riveAnimation;
        return self;
    } else {
        return nil;
    }
}

- (NSString *)name {
    std::string str = animation->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

- (RiveLinearAnimationInstance *)instance {
    return [[RiveLinearAnimationInstance alloc] initWithAnimation: animation];
}

- (NSInteger)workStart {
    return animation->workStart();
}

- (NSInteger)workEnd {
    return animation->workEnd();
}

- (NSInteger)duration {
    return animation->duration();
}

- (float)endTime {
    if (animation->enableWorkArea()){
        return animation->workEnd()/animation->fps();
    }
    return animation->duration()/animation->fps();
}

- (NSInteger)fps {
    return animation->fps();
}

- (void)apply:(float)time to:(RiveArtboard *)artboard {
    animation->apply(artboard.artboard, time);
}

- (int)loop {
    return animation->loopValue();
}

@end

/*
 * RiveLinearAnimationInstance
 */
@implementation RiveLinearAnimationInstance {
    rive::LinearAnimationInstance *instance;
}

- (instancetype)initWithAnimation:(const rive::LinearAnimation *)riveAnimation {
    if (self = [super init]) {
        instance = new rive::LinearAnimationInstance(riveAnimation);
        return self;
    } else {
        return nil;
    }
}

- (RiveLinearAnimation *)animation {
    const rive::LinearAnimation *linearAnimation = instance->animation();
    return [[RiveLinearAnimation alloc] initWithAnimation: linearAnimation];
}

- (float)time {
    return instance->time();
}

- (void)setTime:(float) time {
    instance->time(time);
}

- (void)applyTo:(RiveArtboard*) artboard {
    instance->apply(artboard.artboard);
}

- (bool)advanceBy:(double)elapsedSeconds {
    return instance->advance(elapsedSeconds);
}
- (void)direction:(int)direction {
    instance->direction(direction);
}
- (int)direction {
    return instance->direction();
}

- (int)loop {
    return instance->loopValue();
}

- (void)loop:(int)loopType {
    instance->loopValue(loopType);
}

@end

/*
 * RiveStateMachine
 */
@implementation RiveStateMachine {
    const rive::StateMachine *stateMachine;
}

// Creates a new RiveStateMachine from a cpp StateMachine
- (instancetype)initWithStateMachine:(const rive::StateMachine *)riveStateMachine {
    if (self = [super init]) {
        stateMachine = riveStateMachine;
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

@end

/*
 * RiveStateMachineInstance
 */
@implementation RiveStateMachineInstance {
    rive::StateMachineInstance *instance;
}

// Creates a new RiveStateMachineInstance from a cpp StateMachine
- (instancetype)initWithStateMachine:(const rive::StateMachine *)stateMachine {
    if (self = [super init]) {
        instance = new rive::StateMachineInstance(stateMachine);
        return self;
    } else {
        return nil;
    }
}


-(void) applyTo:(RiveArtboard*) artboard {
    instance->apply(artboard.artboard);
}

-(bool) advanceBy:(double)elapsedSeconds {
    return instance->advance(elapsedSeconds);
}

@end
