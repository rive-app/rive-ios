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
#import <RiveRuntime/RiveSMIInput.h>
#import <RiveRuntime/RiveLinearAnimationInstance.h>
#import <RiveRuntime/RiveStateMachineInstance.h>
#import <RiveRuntime/RiveTextValueRun.h>
#import <RiveRuntime/RiveEvent.h>
#import <RiveRuntime/LayerState.h>
#import <RiveRuntime/RenderContextManager.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * LoopMode
 */
typedef NS_ENUM(NSInteger, RiveLoop) { oneShot, loop, pingPong, autoLoop };

/*
 * Direction
 */
typedef NS_ENUM(NSInteger, RiveDirection) {
    backwards,
    forwards,
    autoDirection,
};

/*
 * Fits
 */
typedef NS_ENUM(NSInteger, RiveFit) { fill, contain, cover, fitHeight, fitWidth, scaleDown, noFit };

/*
 * Alignments
 */
typedef NS_ENUM(NSInteger, RiveAlignment) {
    topLeft,
    topCenter,
    topRight,
    centerLeft,
    center,
    centerRight,
    bottomLeft,
    bottomCenter,
    bottomRight
};

FOUNDATION_EXPORT NSString* const RiveErrorDomain;

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
- (void)alignWithRect:(CGRect)rect
      withContentRect:(CGRect)contentRect
        withAlignment:(RiveAlignment)alignment
              withFit:(RiveFit)fit;

@end

NS_ASSUME_NONNULL_END

#endif /* rive_h */
