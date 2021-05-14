//
//  RiveArtboard.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//


#ifndef rive_artboard_h
#define rive_artboard_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RiveLinearAnimation;
@class RiveStateMachine;
@class RiveRenderer;

/*
 * RiveArtboard
 */
@interface RiveArtboard : NSObject

- (NSString *)name;
- (CGRect)bounds;

- (NSInteger)animationCount;
- (NSArray<NSString *> *)animationNames;
- (RiveLinearAnimation *)firstAnimation;
- (RiveLinearAnimation *)animationFromIndex:(NSInteger)index;
- (RiveLinearAnimation *)animationFromName:(NSString *)name;

- (NSInteger)stateMachineCount;
- (NSArray<NSString *> *)stateMachineNames;
- (RiveStateMachine *)firstStateMachine;
- (RiveStateMachine *)stateMachineFromIndex:(NSInteger)index;
- (RiveStateMachine *)stateMachineFromName:(NSString *)name;

- (void)advanceBy:(double)elapsedSeconds;
- (void)draw:(RiveRenderer *)renderer;

@end

NS_ASSUME_NONNULL_END

#endif /* rive_artboard_h */
