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

@class RiveLinearAnimationInstance;
@class RiveStateMachineInstance;
@class RiveRenderer;
@class RiveTextValueRun;

// MARK: - RiveArtboard
//
@interface RiveArtboard : NSObject

- (NSString*)name;
- (CGRect)bounds;

- (NSInteger)animationCount;
- (NSArray<NSString*>*)animationNames;
- (RiveLinearAnimationInstance* __nullable)animationFromIndex:(NSInteger)index
                                                        error:(NSError**)error;
- (RiveLinearAnimationInstance* __nullable)animationFromName:(NSString*)name error:(NSError**)error;

- (NSInteger)stateMachineCount;
- (NSArray<NSString*>*)stateMachineNames;
- (RiveStateMachineInstance* __nullable)stateMachineFromIndex:(NSInteger)index
                                                        error:(NSError**)error;
- (RiveStateMachineInstance* __nullable)stateMachineFromName:(NSString*)name error:(NSError**)error;
- (RiveStateMachineInstance* __nullable)defaultStateMachine;

- (RiveTextValueRun* __nullable)textRun:(NSString*)name;

- (void)advanceBy:(double)elapsedSeconds;
- (void)draw:(RiveRenderer*)renderer;

// MARK: Debug

#if RIVE_ENABLE_REFERENCE_COUNTING
+ (int)instanceCount;
#endif // RIVE_ENABLE_REFERENCE_COUNTING

@end

NS_ASSUME_NONNULL_END
