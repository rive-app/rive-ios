//
//  RiveFile.h
//  RiveRuntime
//
//  Created by Matt Sullivan on 8/30/20.
//  Copyright © 2020 Rive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * LoopMode
 */
typedef NS_ENUM(NSInteger, Loop) {
    loopOneShot,
    loopLoop,
    loopPingPong,
    loopAuto
};

/*
 * Direction
 */
typedef NS_ENUM(NSInteger, Direction) {
    directionBackwards,
    directionForwards,
    directionAuto,
};

/*
 * Fits
 */
typedef NS_ENUM(NSInteger, Fit) {
    Fill,
    Contain,
    Cover,
    FitHeight,
    FitWidth,
    ScaleDown,
    None
};

/*
 * Alignments
 */
typedef NS_ENUM(NSInteger, Alignment) {
    TopLeft,
    TopCenter,
    TopRight,
    CenterLeft,
    Center,
    CenterRight,
    BottomLeft,
    BottomCenter,
    BottomRight
};

@interface RiveException : NSException
@end

@class RiveArtboard;
@class RiveLinearAnimation;
@class RiveStateMachine;
@class RiveSMIInput;
@class RiveSMIBool;
@class RiveSMITrigger;
@class RiveSMINumber;
@class RiveStateMachineInput;

/*
 * RiveStateMachineInstance
 */
@interface RiveStateMachineInstance : NSObject
- (NSString* )name;
- (void)applyTo:(RiveArtboard*)artboard;
- (bool)advanceBy:(double)elapsedSeconds;
- (const RiveStateMachine *)stateMachine;
- (const RiveSMIBool *)getBool:(NSString*)name;
- (const RiveSMITrigger *)getTrigger:(NSString*)name;
- (const RiveSMINumber *)getNumber:(NSString*)name;
- (NSArray *)inputNames;
- (NSInteger)inputCount;
- (RiveSMIInput *)inputFromIndex:(NSInteger)index;
- (RiveSMIInput *)inputFromName:(NSString*)name;

@end

/*
 * RiveStateMachine
 */
@interface RiveStateMachine : NSObject
- (NSString *)name;
- (NSInteger)layerCount;
- (NSInteger)inputCount;
- (RiveStateMachineInstance *)instance;
- (NSArray *)inputNames;
- (RiveStateMachineInput *)inputFromIndex:(NSInteger)index;
- (RiveStateMachineInput *)inputFromName:(NSString*)name;
@end

/*
 * SMITrigger
 */
@interface RiveSMIInput : NSObject
- (NSString *)name;
- (bool)isBoolean;
- (bool)isTrigger;
- (bool)isNumber;
@end

/*
 * SMITrigger
 */
@interface RiveSMITrigger : RiveSMIInput
- (void)fire;
@end

/*
 * SMIBool
 */
@interface RiveSMIBool : RiveSMIInput
- (bool)value;
- (void)setValue:(bool)newValue;
@end

/*
 * SMINumber
 */
@interface RiveSMINumber : RiveSMIInput
- (float)value;
- (void)setValue:(float)newValue;
@end

/*
 * RiveStateMachineInput
 */
@interface RiveStateMachineInput : NSObject
- (bool)isBoolean;
- (bool)isTrigger;
- (bool)isNumber;
- (NSString *)name;
@end

/*
 * RiveStateMachineBoolInput
 */
@interface RiveStateMachineBoolInput : RiveStateMachineInput
- (bool)value;
@end

/*
 * RiveStateMachineTriggerInput
 */
@interface RiveStateMachineTriggerInput : RiveStateMachineInput
@end

/*
 * RiveStateMachineNumberInput
 */
@interface RiveStateMachineNumberInput : RiveStateMachineInput
- (float)value;
@end



/*
 * RiveLinearAnimationInstance
 */
@interface RiveLinearAnimationInstance : NSObject

- (float)time;
- (void)setTime:(float) time;
- (const RiveLinearAnimation *)animation;
- (void)applyTo:(RiveArtboard*)artboard;
- (bool)advanceBy:(double)elapsedSeconds;
- (int)direction;
- (void)direction:(int)direction;
- (int)loop;
- (void)loop:(int)loopMode;
- (bool)didLoop;
- (NSString *)name;

@end

/*
 * RiveLinearAnimation
 */
@interface RiveLinearAnimation : NSObject

- (NSString *)name;
- (RiveLinearAnimationInstance *)instance;
- (NSInteger)workStart;
- (NSInteger)workEnd;
- (NSInteger)duration;
- (NSInteger)effectiveDuration;
- (float)endTime;
- (NSInteger)fps;
- (int)loop;
- (void)apply:(float)time to:(RiveArtboard *)artboard;

@end

/*
 * RiveRenderer
 */
@interface RiveRenderer : NSObject

- (instancetype)initWithContext:(nonnull CGContextRef)context;
- (void)alignWithRect:(CGRect)rect withContentRect:(CGRect)contentRect withAlignment:(Alignment)alignment withFit:(Fit)fit;

@end

/*
 * RiveArtboard
 */
@interface RiveArtboard : NSObject

- (NSString *)name;
- (CGRect)bounds;

- (NSInteger)animationCount;
- (NSArray *)animationNames;
- (RiveLinearAnimation *)firstAnimation;
- (RiveLinearAnimation *)animationFromIndex:(NSInteger)index;
- (RiveLinearAnimation *)animationFromName:(NSString *)name;

- (NSInteger)stateMachineCount;
- (NSArray *)stateMachineNames;
- (RiveStateMachine *)firstStateMachine;
- (RiveStateMachine *)stateMachineFromIndex:(NSInteger)index;
- (RiveStateMachine *)stateMachineFromName:(NSString *)name;

- (void)advanceBy:(double)elapsedSeconds;
- (void)draw:(RiveRenderer *)renderer;

@end

/*
 * RiveFile
 */
@interface RiveFile : NSObject

@property (class, readonly) uint majorVersion;
@property (class, readonly) uint minorVersion;

- (nullable instancetype)initWithBytes:(UInt8 *)bytes byteLength:(UInt64)length;

// Returns a reference to the default artboard
- (RiveArtboard *)artboard;

// Returns the number of artboards in the file
- (NSInteger)artboardCount;

// Returns the artboard by its index
- (RiveArtboard *)artboardFromIndex:(NSInteger)index;

// Returns the artboard by its name
- (RiveArtboard *)artboardFromName:(NSString *)name;

// Returns the names of all artboards in the file.
- (NSArray *)artboardNames;

@end

NS_ASSUME_NONNULL_END
