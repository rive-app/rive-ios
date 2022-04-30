//
//  RiveLinearAnimation.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#ifndef rive_linear_animation_h
#define rive_linear_animation_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RiveLinearAnimationInstance;

/*
 * RiveLinearAnimation
 */
@interface RiveLinearAnimation : NSObject
- (NSString *)name;
- (RiveLinearAnimationInstance *)instanceWithArtboard:(RiveArtboard *)artboard;
- (NSInteger)workStart;
- (NSInteger)workEnd;
- (NSInteger)duration;
- (NSInteger)effectiveDuration;
- (float)effectiveDurationInSeconds;
- (float)endTime;
- (NSInteger)fps;
- (int)loop;
- (void)apply:(float)time to:(RiveArtboard *)artboard;

@end

NS_ASSUME_NONNULL_END

#endif /* rive_linear_animation_h */
