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
    LoopOneShot,
    LoopLoop,
    LoopPingPong,
    LoopAuto,
    wat
};

/*
 * Direction
 */
typedef NS_ENUM(NSInteger, Direction) {
    DirectionBackwards,
    DirectionForwards,
    DirectionAuto,
    huh
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

@class RiveArtboard;
@class RiveLinearAnimation;
@class RiveStateMachine;
@class RiveSMIBool;
@class RiveSMITrigger;
@class RiveSMINumber;

/*
 * RiveStateMachineInstance
 */
@interface RiveStateMachineInstance : NSObject

- (void)applyTo:(RiveArtboard*)artboard;
- (bool)advanceBy:(double)elapsedSeconds;
- (const RiveStateMachine *)stateMachine;
- (const RiveSMIBool *)getBool:(NSString*)name;
- (const RiveSMITrigger *)getTrigger:(NSString*)name;
- (const RiveSMINumber *)getNumber:(NSString*)name;

@end

/*
 * RiveStateMachine
 */
@interface RiveStateMachine : NSObject
- (NSString *)name;
- (NSInteger)layerCount;
- (NSInteger)inputCount;
- (RiveStateMachineInstance *)instance;
@end

/*
 * SMITrigger
 */
@interface RiveSMITrigger : NSObject
- (void)fire;
@end

/*
 * SMIBool
 */
@interface RiveSMIBool : NSObject
- (void)setValue:(bool)newValue;
@end

/*
 * SMINumber
 */
@interface RiveSMINumber : NSObject
- (void)setValue:(float)newValue;
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
- (float)endTime;
- (NSInteger)fps;
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
- (RiveLinearAnimation *)firstAnimation;
- (RiveLinearAnimation *)animationFromIndex:(NSInteger)index;
- (RiveLinearAnimation *)animationFromName:(NSString *)name;

- (NSInteger)stateMachineCount;
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
- (RiveArtboard *)artboardFromIndex:(NSInteger) index;

// Returns the artboard by its name
- (RiveArtboard *)artboardFromName:(NSString *) name;

@end

NS_ASSUME_NONNULL_END
