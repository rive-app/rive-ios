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
#import "state_machine_input.hpp"
#import "state_machine_bool.hpp"
#import "state_machine_number.hpp"
#import "state_machine_trigger.hpp"
#import "state_machine_input_instance.hpp"

@implementation RiveException
@end

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
- (instancetype)initWithStateMachine:(const rive::StateMachine *)stateMachine;
@end

/*
 * RiveSMIInput interface
 */
@interface RiveSMIInput ()
- (instancetype)initWithSMIInput:(const rive::SMIInput *)riveSMIInput;
@end

/*
 * SMITrigger interface
 */
@interface RiveSMITrigger ()
@end

/*
 * SMINumber interface
 */
@interface RiveSMINumber ()
@end

/*
 * SMIBool interface
 */
@interface RiveSMIBool ()
@end


/*
 * RiveStateMachineInput interface
 */
@interface RiveStateMachineInput ()
- (instancetype)initWithStateMachineInput:(const rive::StateMachineInput *)riveStateMachineInput;
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
        else if(result == rive::ImportResult::unsupportedVersion){
            @throw [[RiveException alloc] initWithName:@"UnsupportedVersion" reason:@"Unsupported Rive File Version." userInfo:nil];
            
        }
        else if(result == rive::ImportResult::malformed){
            @throw [[RiveException alloc] initWithName:@"Malformed" reason:@"Malformed Rive File." userInfo:nil];
        }
        else {
            @throw [[RiveException alloc] initWithName:@"Unknown" reason:@"Unknown error loading file." userInfo:nil];
        }
    }
    return nil;
}

- (RiveArtboard *)artboard {
    rive::Artboard *artboard = riveFile->artboard();
    if (artboard == nullptr) {
        @throw [[RiveException alloc] initWithName:@"NoArtboardsFound" reason: @"No Artboards Found." userInfo:nil];
    }
    else {
        return [[RiveArtboard alloc] initWithArtboard: artboard];
    }
    
}

- (NSInteger)artboardCount {
    return riveFile->artboardCount();
}

- (RiveArtboard *)artboardFromIndex:(NSInteger)index {
    if (index >= [self artboardCount]) {
        @throw [[RiveException alloc] initWithName:@"NoArtboardFound" reason:[NSString stringWithFormat: @"No Artboard Found at index %ld.", index] userInfo:nil];
    }
    return [[RiveArtboard alloc]
            initWithArtboard: reinterpret_cast<rive::Artboard *>(riveFile->artboard(index))];
}

- (RiveArtboard *)artboardFromName:(NSString *)name {
    std::string stdName = std::string([name UTF8String]);
    rive::Artboard *artboard = riveFile->artboard(stdName);
    if (artboard == nullptr) {
        @throw [[RiveException alloc] initWithName:@"NoArtboardFound" reason:[NSString stringWithFormat: @"No Artboard Found with name %@.", name] userInfo:nil];
    } else {
        return [[RiveArtboard alloc] initWithArtboard: artboard];
    }
}

- (NSArray *)artboardNames {
    NSMutableArray *artboardNames = [NSMutableArray array];
    
    for (NSUInteger i=0; i<[self artboardCount]; i++) {
        NSString* name = [[self artboardFromIndex: i] name];
        [artboardNames addObject:name];
    }
    return artboardNames;
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
        @throw [[RiveException alloc] initWithName:@"NoAnimationFound" reason:[NSString stringWithFormat: @"No Animation found at index %ld.", index] userInfo:nil];
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
        @throw [[RiveException alloc] initWithName:@"NoStateMachineFound" reason:[NSString stringWithFormat: @"No State Machine found at index %ld.", index] userInfo:nil];
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

- (NSInteger)effectiveDuration {
    if (self.workStart == -1) {
        return animation->duration();
        
    }else {
        return self.workEnd - self.workStart;
    }
}

- (float)effectiveDurationInSeconds {
    return [self effectiveDuration] / [self fps];
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

- (bool)didLoop {
    return instance->didLoop();
}

- (NSString *)name {
    std::string str = instance->animation()->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}
@end

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
- (RiveStateMachineInstance *)instance {
    return [[RiveStateMachineInstance alloc] initWithStateMachine: stateMachine];
}

- (RiveStateMachineInput *)_convertInput:(const rive::StateMachineInput *)input{
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
        @throw [[RiveException alloc] initWithName:@"UnkownInput" reason: @"Unknown State Machine Input" userInfo:nil];
    }
}

// Creates a new instance of this state machine
- (RiveStateMachineInput *)inputFromIndex:(NSInteger)index {
    if (index >= [self inputCount]) {
        @throw [[RiveException alloc] initWithName:@"NoStateMachineInputFound" reason:[NSString stringWithFormat: @"No Input found at index %ld.", index] userInfo:nil];
    }
    return [self _convertInput: stateMachine->input(index) ];
}

// Creates a new instance of this state machine
- (RiveStateMachineInput *)inputFromName:(NSString*)name {
    
    std::string stdName = std::string([name UTF8String]);
    const rive::StateMachineInput *stateMachineInput = stateMachine->input(stdName);
    if (stateMachineInput == nullptr) {
        @throw [[RiveException alloc] initWithName:@"NoStateMachineInputFound" reason:[NSString stringWithFormat: @"No State Machine Input found with name %@.", name] userInfo:nil];
    } else {
        return [self _convertInput: stateMachineInput];
    }
}

- (NSArray *)inputNames{
    NSMutableArray *inputNames = [NSMutableArray array];
    
    for (NSUInteger i=0; i<[self inputCount]; i++){
        [inputNames addObject:[[self inputFromIndex: i] name]];
    }
    return inputNames;
}
@end

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


@end

/*
 * RiveSMIInput
 */
@implementation RiveSMIInput {
     const rive::SMIInput *instance;
}

- (const rive::SMIInput *)getInstance {
    return instance;
}

// Creates a new RiveSMINumber from a cpp SMINumber
- (instancetype)initWithSMIInput:(const rive::SMIInput *)stateMachineInput {
    if (self = [super init]) {
        instance = stateMachineInput;
        return self;
    } else {
        return nil;
    }
}

- (bool)isBoolean {
    return instance->input()->is<rive::StateMachineBool>();
}

- (bool)isTrigger {
    return instance->input()->is<rive::StateMachineTrigger>();
}

- (bool)isNumber {
    return instance->input()->is<rive::StateMachineNumber>();
};

- (NSString *)name {
    std::string str = ((const rive::SMIInput *)instance)->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

@end


/*
 * RiveSMITrigger
 */
@implementation RiveSMITrigger

- (void) fire {
    ((rive::SMITrigger *)[self getInstance])->fire();
}

@end

/*
 * RiveSMIBool
 */
@implementation RiveSMIBool

- (void) setValue:(bool)newValue {
    ((rive::SMIBool *)[self getInstance])->value(newValue);
}

- (bool) value{
    return ((rive::SMIBool *)[self getInstance])->value();
}

@end

/*
 * RiveSMINumber
 */
@implementation RiveSMINumber

- (void) setValue:(float)newValue {
    ((rive::SMINumber *)[self getInstance])->value(newValue);
}
- (float) value {
    return ((rive::SMINumber *)[self getInstance])->value();
}

@end


/*
 * RiveStateMachineInput
 */
@implementation RiveStateMachineInput {
     const rive::StateMachineInput *instance;
}

- (const rive::StateMachineInput *)getInstance {
    return instance;
}

// Creates a new RiveSMINumber from a cpp SMINumber
- (instancetype)initWithStateMachineInput:(const rive::StateMachineInput *)stateMachineInput {
    if (self = [super init]) {
        instance = stateMachineInput;
        return self;
    } else {
        return nil;
    }
}

- (bool)isBoolean {
    return instance->is<rive::StateMachineBool>();
}

- (bool)isTrigger{
    return instance->is<rive::StateMachineTrigger>();
}

- (bool)isNumber{
    return instance->is<rive::StateMachineNumber>();
};

- (NSString *)name{
    std::string str = ((const rive::StateMachineInput *)instance)->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

@end

/*
 * RiveStateMachineInput
 */
@implementation RiveStateMachineBoolInput

- (bool)value {
    return ((const rive::StateMachineBool *)[self getInstance])->value();
}

@end
 
/*
 * RiveStateMachineInput
 */
@implementation RiveStateMachineTriggerInput

@end
 
/*
 * RiveStateMachineInput
 */
@implementation RiveStateMachineNumberInput

- (float)value {
    return ((const rive::StateMachineNumber*)[self getInstance])->value();
}

@end
