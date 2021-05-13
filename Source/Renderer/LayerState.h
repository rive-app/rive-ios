//
//  RiveFile.h
//  RiveRuntime
//
//  Created by Matt Sullivan on 8/30/20.
//  Copyright © 2020 Rive. All rights reserved.
//


#ifndef layer_state_h
#define layer_state_h

#import <Foundation/Foundation.h>

@class RiveLinearAnimation;

/*
 * RiveLayerState
 */
@interface RiveLayerState : NSObject

- (RiveLinearAnimation *)animation;
- (bool)isEntryState;
- (bool)isExitState;
- (bool)isAnyState;
- (bool)isAnimationState;
- (NSString *)name;

@end

/*
 * RiveExitState
 */
@interface RiveExitState : RiveLayerState
- (NSString *)name;
@end

/*
 * RiveEntryState
 */
@interface RiveEntryState : RiveLayerState
- (NSString *)name;
@end

/*
 * RiveAnyState
 */
@interface RiveAnyState : RiveLayerState
- (NSString *)name;
@end

/*
 * RiveAnimationState
 */
@interface RiveAnimationState : RiveLayerState
- (NSString *)name;
@end

#endif /* layer_state_h */
