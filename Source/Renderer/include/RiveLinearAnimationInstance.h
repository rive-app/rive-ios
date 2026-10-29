//
//  RiveLinearAnimationInstance.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#ifndef rive_linear_animation_instance_h
#define rive_linear_animation_instance_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * RiveLinearAnimationInstance
 */
DEPRECATED_MSG_ATTRIBUTE("The legacy linear animation API is deprecated. Use a "
                         "state machine to control playback instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#linear-animations")
@interface RiveLinearAnimationInstance : NSObject

- (float)time;
- (void)setTime:(float)time;
- (float)endTime;
- (bool)advanceBy:(double)elapsedSeconds;
- (int)direction;
- (void)direction:(int)direction;
- (int)loop;
- (void)loop:(int)loopMode;
- (bool)didLoop;
- (NSString*)name;

- (NSInteger)fps;
- (NSInteger)workStart;
- (NSInteger)workEnd;
- (NSInteger)duration;
- (NSInteger)effectiveDuration;
- (float)effectiveDurationInSeconds;
- (bool)hasEnded;

// MARK: Debug

#if RIVE_ENABLE_REFERENCE_COUNTING
+ (int)instanceCount;
#endif // RIVE_ENABLE_REFERENCE_COUNTING

@end

NS_ASSUME_NONNULL_END

#endif /* rive_linear_animation_instance_h */
