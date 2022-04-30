//
//  RiveFile.h
//  RiveRuntime
//
//  Created by Matt Sullivan on 8/30/20.
//  Copyright © 2020 Rive. All rights reserved.
//


#ifndef rive_h
#define rive_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>


#import <RiveRuntime/RiveFile.h>
#import <RiveRuntime/RiveArtboard.h>
#import <RiveRuntime/RiveLinearAnimation.h>
#import <RiveRuntime/RiveSMIInput.h>
#import <RiveRuntime/RiveStateMachine.h>
#import <RiveRuntime/RiveStateMachineInput.h>
#import <RiveRuntime/RiveLinearAnimationInstance.h>
#import <RiveRuntime/RiveStateMachineInstance.h>
#import <RiveRuntime/LayerState.h>


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
    fitFill,
    fitContain,
    fitCover,
    fitFitHeight,
    fitFitWidth,
    fitScaleDown,
    fitNone
};

/*
 * Alignments
 */
typedef NS_ENUM(NSInteger, Alignment) {
    alignmentTopLeft,
    alignmentTopCenter,
    alignmentTopRight,
    alignmentCenterLeft,
    alignmentCenter,
    alignmentCenterRight,
    alignmentBottomLeft,
    alignmentBottomCenter,
    alignmentBottomRight
};

FOUNDATION_EXPORT NSString *const RiveErrorDomain;

typedef NS_ENUM(NSInteger, RiveErrorCode) {
    RiveNoArtboardsFound = 100,
    RiveNoArtboardFound = 101,
    RiveNoAnimations = 200,
    RiveNoAnimationFound = 201,
    RiveNoStateMachines = 300,
    RiveNoStateMachineFound = 301,
    RiveNoStateMachineInputFound = 400,
    RiveUnknownStateMachineInput = 401,
    RiveNoStateChangeFound = 402,
    RiveUnsupportedVersion = 500,
    RiveMalformedFile = 600,
    RiveUnknownError = 700,
};

/*
 * RiveRenderer
 */
@interface RiveRenderer : NSObject

- (instancetype)initWithContext:(nonnull CGContextRef)context;
- (void)alignWithRect:(CGRect)rect withContentRect:(CGRect)contentRect withAlignment:(Alignment)alignment withFit:(Fit)fit;

@end

NS_ASSUME_NONNULL_END

#endif /* rive_h */
