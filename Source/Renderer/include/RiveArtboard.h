//
//  RiveArtboard.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//
#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RiveLinearAnimation;
@class RiveStateMachine;
@class RiveRenderer;

// MARK: - RiveArtboard
//
@interface RiveArtboard : NSObject



- (NSString *)name;
- (CGRect)bounds;

- (NSInteger)animationCount;
- (NSArray<NSString *> *)animationNames;
- (RiveLinearAnimation * __nullable)firstAnimation:(NSError **)error;
- (RiveLinearAnimation * __nullable)animationFromIndex:(NSInteger)index error:(NSError **)error;
- (RiveLinearAnimation * __nullable)animationFromName:(NSString *)name error:(NSError **)error;

- (NSInteger)stateMachineCount;
- (NSArray<NSString *> *)stateMachineNames;
- (RiveStateMachine * __nullable)firstStateMachine:(NSError **)error;
- (RiveStateMachine * __nullable)stateMachineFromIndex:(NSInteger)index error:(NSError **)error;
- (RiveStateMachine * __nullable)stateMachineFromName:(NSString *)name error:(NSError **)error;

- (void)advanceBy:(double)elapsedSeconds;
- (void)touchedAt: (CGPoint)location info:(int)hitInfo;
- (void)draw:(RiveRenderer *)renderer;

@end

// MARK: - RiveArtboard Delegate
//
@protocol RArtboardDelegate

- (void)artboard:(RiveArtboard *)artboard didTriggerEvent:(NSString *)event;

@end

NS_ASSUME_NONNULL_END
