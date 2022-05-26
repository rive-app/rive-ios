//
//  RiveStateMachineInstance.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//


#ifndef rive_state_machine_instance_h
#define rive_state_machine_instance_h

#import <Foundation/Foundation.h>
#import <RiveScene.h>

NS_ASSUME_NONNULL_BEGIN

@class RiveSMIInput;
@class RiveSMIBool;
@class RiveSMITrigger;
@class RiveSMINumber;
@class RiveLayerState;

/*
 * RiveStateMachineInstance
 */
@interface RiveStateMachineInstance : RiveScene
- (bool)advanceBy: (double)elapsedSeconds;
- (const RiveSMIBool *)getBool:(NSString*)name;
- (const RiveSMITrigger *)getTrigger:(NSString*)name;
- (const RiveSMINumber *)getNumber:(NSString*)name;
- (NSArray<NSString *> *)inputNames;
- (NSInteger)inputCount;
- (NSInteger)layerCount;
- (RiveSMIInput * __nullable)inputFromIndex:(NSInteger)index error:(NSError**)error;
- (RiveSMIInput * __nullable)inputFromName:(NSString*)name error:(NSError**)error;
- (NSInteger)stateChangedCount;
- (RiveLayerState * __nullable)stateChangedFromIndex:(NSInteger)index error:(NSError**)error;
- (NSArray<NSString *> *)stateChanges;

/// Tells this StateMachineInstance that a user began touching the artboard
/// @param touchLocation A CGPoint in the coordinate space of the animating artboard
- (void)touchBeganAtLocation:(CGPoint)touchLocation;

/// Tells this StateMachineInstance that a touch moved on the artboard
/// @param touchLocation A CGPoint in the coordinate space of the animating artboard
- (void)touchMovedAtLocation:(CGPoint)touchLocation;

/// Tells this StateMachineInstance that a user finished touching the artboard
/// @param touchLocation A CGPoint in the coordinate space of the animating artboard
- (void)touchEndedAtLocation:(CGPoint)touchLocation;

/// Tells this StateMachineInstance that a user cancelled touching the artboard
/// @param touchLocation A CGPoint in the coordinate space of the animating artboard
- (void)touchCancelledAtLocation:(CGPoint)touchLocation;

@end

NS_ASSUME_NONNULL_END

#endif /* rive_state_machine_instance_h */
