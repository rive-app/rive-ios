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
@class RiveDataBindingViewModelInstance;

/// A type mirroring rive::HitResult, but available in both ObjC and Swift.
typedef NS_ENUM(NSInteger, RiveHitResult) { none, hit, hitOpaque };

/*
 * RiveStateMachineInstance
 */
@interface RiveStateMachineInstance : NSObject

@property(nonatomic, nullable, readonly)
    RiveDataBindingViewModelInstance* viewModelInstance;

- (NSString*)name;
- (bool)advanceBy:(double)elapsedSeconds;
- (const RiveSMIBool*)getBool:(NSString*)name;
- (const RiveSMITrigger*)getTrigger:(NSString*)name;
- (const RiveSMINumber*)getNumber:(NSString*)name;
- (NSArray<NSString*>*)inputNames;
- (NSInteger)inputCount;
- (NSInteger)layerCount;
- (RiveSMIInput* __nullable)inputFromIndex:(NSInteger)index
                                     error:(NSError**)error;
- (RiveSMIInput* __nullable)inputFromName:(NSString*)name
                                    error:(NSError**)error;
- (NSInteger)stateChangedCount;
- (RiveLayerState* __nullable)stateChangedFromIndex:(NSInteger)index
                                              error:(NSError**)error;
- (NSArray<NSString*>*)stateChanges;
/// Returns number of reported events on the state machine since the last frame
- (NSInteger)reportedEventCount;
/// Returns a RiveEvent from the list of reported events at the given index
- (const RiveEvent*)reportedEventAt:(NSInteger)index;

// MARK: Touch

/// Tells this StateMachineInstance that a user began touching the artboard
/// @param touchLocation A CGPoint in the coordinate space of the animating
/// artboard
/// @return The RiveHitResult of a touch beginning at the provided location.
- (RiveHitResult)touchBeganAtLocation:(CGPoint)touchLocation;

/// Tells this StateMachineInstance that a touch moved on the artboard
/// @param touchLocation A CGPoint in the coordinate space of the animating
/// artboard
/// @return The RiveHitResult of a touch moving at the provided location.
- (RiveHitResult)touchMovedAtLocation:(CGPoint)touchLocation;

/// Tells this StateMachineInstance that a user finished touching the artboard
/// @param touchLocation A CGPoint in the coordinate space of the animating
/// artboard
/// @return The RiveHitResult of a touch ending at the provided location.
- (RiveHitResult)touchEndedAtLocation:(CGPoint)touchLocation;

/// Tells this StateMachineInstance that a user cancelled touching the artboard
/// @param touchLocation A CGPoint in the coordinate space of the animating
/// artboard
/// @return The RiveHitResult of a touch being cancelled at the provided
/// location.
- (RiveHitResult)touchCancelledAtLocation:(CGPoint)touchLocation;

// MARK: - Data Binding

/// Binds an instance of a view model to the state machine for updates.
///
/// A strong reference to the instance being bound must be made if you wish to
/// reuse instance properties, or for observability. By default, the instance
/// will also automatically be bound to the artboard containing the state
/// machine.
///
/// - Parameter instance: The instance of a view model to bind.
- (void)bindViewModelInstance:(RiveDataBindingViewModelInstance*)instance
    NS_SWIFT_NAME(bind(viewModelInstance:));

// MARK: Debug

#if RIVE_ENABLE_REFERENCE_COUNTING
+ (int)instanceCount;
#endif // RIVE_ENABLE_REFERENCE_COUNTING

@end

NS_ASSUME_NONNULL_END

#endif /* rive_state_machine_instance_h */
