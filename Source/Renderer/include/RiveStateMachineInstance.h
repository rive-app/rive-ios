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

NS_ASSUME_NONNULL_BEGIN

@class RiveStateMachine;
@class RiveSMIInput;
@class RiveSMIBool;
@class RiveSMITrigger;
@class RiveSMINumber;
@class RiveLayerState;
@class RiveEvent;

/*
 * RiveStateMachineInstance
 */
@interface RiveStateMachineInstance : NSObject
- (NSString*)name;
- (bool)advanceBy:(double)elapsedSeconds;
- (const RiveSMIBool*)getBool:(NSString*)name;
- (const RiveSMITrigger*)getTrigger:(NSString*)name;
- (const RiveSMINumber*)getNumber:(NSString*)name;
- (NSArray<NSString*>*)inputNames;
- (NSInteger)inputCount;
- (NSInteger)layerCount;
- (RiveSMIInput* __nullable)inputFromIndex:(NSInteger)index error:(NSError**)error;
- (RiveSMIInput* __nullable)inputFromName:(NSString*)name error:(NSError**)error;
- (NSInteger)stateChangedCount;
- (RiveLayerState* __nullable)stateChangedFromIndex:(NSInteger)index error:(NSError**)error;
- (NSArray<NSString*>*)stateChanges;
/// Returns number of reported events on the state machine since the last frame
- (NSInteger)reportedEventCount;
/// Returns a RiveEvent from the list of reported events at the given index
- (const RiveEvent*)reportedEventAt:(NSInteger)index;

// MARK: Touch

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

// MARK: Debug

#if RIVE_ENABLE_REFERENCE_COUNTING
+ (int)instanceCount;
#endif // RIVE_ENABLE_REFERENCE_COUNTING

@end

NS_ASSUME_NONNULL_END

#endif /* rive_state_machine_instance_h */
