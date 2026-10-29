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
typedef NS_ENUM(NSInteger, RiveHitResult) {
  none,
  hit,
  hitOpaque
} DEPRECATED_MSG_ATTRIBUTE("The legacy hit result API is deprecated. Use the "
                           "concurrency runtime instead. See "
                           "https://rive.app/docs/runtimes/apple/"
                           "migrating-from-legacy");

/*
 * RiveStateMachineInstance
 */
DEPRECATED_MSG_ATTRIBUTE(
    "The legacy API is deprecated. Use StateMachine from the concurrency "
    "runtime instead. See "
    "https://rive.app/docs/runtimes/apple/"
    "migrating-from-legacy#choosing-an-artboard-and-state-machine")
@interface RiveStateMachineInstance : NSObject

@property(nonatomic, nullable, readonly)
    RiveDataBindingViewModelInstance* viewModelInstance;

- (NSString*)name;
- (bool)advanceBy:(double)elapsedSeconds;
- (const RiveSMIBool*)getBool:(NSString*)name
    DEPRECATED_MSG_ATTRIBUTE(
        "The legacy state machine input API is deprecated. Use Data Binding "
        "properties instead. See "
        "https://rive.app/docs/runtimes/apple/"
        "migrating-from-legacy#state-machine-inputs");
- (const RiveSMITrigger*)getTrigger:(NSString*)name
    DEPRECATED_MSG_ATTRIBUTE(
        "The legacy state machine input API is deprecated. Use Data Binding "
        "properties instead. See "
        "https://rive.app/docs/runtimes/apple/"
        "migrating-from-legacy#state-machine-inputs");
- (const RiveSMINumber*)getNumber:(NSString*)name
    DEPRECATED_MSG_ATTRIBUTE(
        "The legacy state machine input API is deprecated. Use Data Binding "
        "properties instead. See "
        "https://rive.app/docs/runtimes/apple/"
        "migrating-from-legacy#state-machine-inputs");
- (NSArray<NSString*>*)inputNames DEPRECATED_MSG_ATTRIBUTE(
    "The legacy state machine input API is deprecated. Use Data Binding "
    "properties instead. See "
    "https://rive.app/docs/runtimes/apple/"
    "migrating-from-legacy#state-machine-inputs");
- (NSInteger)inputCount DEPRECATED_MSG_ATTRIBUTE(
    "The legacy state machine input API is deprecated. Use Data Binding "
    "properties instead. See "
    "https://rive.app/docs/runtimes/apple/"
    "migrating-from-legacy#state-machine-inputs");
- (NSInteger)layerCount;
- (RiveSMIInput* __nullable)inputFromIndex:(NSInteger)index
                                     error:(NSError**)error
    DEPRECATED_MSG_ATTRIBUTE(
        "The legacy state machine input API is deprecated. Use Data Binding "
        "properties instead. See "
        "https://rive.app/docs/runtimes/apple/"
        "migrating-from-legacy#state-machine-inputs");
- (RiveSMIInput* __nullable)inputFromName:(NSString*)name
                                    error:(NSError**)error
    DEPRECATED_MSG_ATTRIBUTE(
        "The legacy state machine input API is deprecated. Use Data Binding "
        "properties instead. See "
        "https://rive.app/docs/runtimes/apple/"
        "migrating-from-legacy#state-machine-inputs");
- (NSInteger)stateChangedCount DEPRECATED_MSG_ATTRIBUTE(
    "The legacy state observation API is deprecated. Use Data Binding "
    "properties instead. See "
    "https://rive.app/docs/runtimes/apple/"
    "migrating-from-legacy#observing-state-machine-state");
- (RiveLayerState* __nullable)stateChangedFromIndex:(NSInteger)index
                                              error:(NSError**)error
    DEPRECATED_MSG_ATTRIBUTE(
        "The legacy state observation API is deprecated. Use Data Binding "
        "properties instead. See "
        "https://rive.app/docs/runtimes/apple/"
        "migrating-from-legacy#observing-state-machine-state");
- (NSArray<NSString*>*)stateChanges DEPRECATED_MSG_ATTRIBUTE(
    "The legacy state observation API is deprecated. Use Data Binding "
    "properties instead. See "
    "https://rive.app/docs/runtimes/apple/"
    "migrating-from-legacy#observing-state-machine-state");
/// Returns number of reported events on the state machine since the last frame
- (NSInteger)reportedEventCount DEPRECATED_MSG_ATTRIBUTE(
    "The legacy Rive event API is deprecated. Use Data Binding instead. See "
    "https://rive.app/docs/runtimes/apple/migrating-from-legacy#events");
/// Returns a RiveEvent from the list of reported events at the given index
- (const RiveEvent*)reportedEventAt:(NSInteger)index
    DEPRECATED_MSG_ATTRIBUTE(
        "The legacy Rive event API is deprecated. Use Data Binding instead. "
        "See "
        "https://rive.app/docs/runtimes/apple/migrating-from-legacy#events");

// MARK: Touch

/// Tells this StateMachineInstance that a user began touching the artboard
/// @param touchLocation A CGPoint in the coordinate space of the animating
/// artboard
/// @return The RiveHitResult of a touch beginning at the provided location.
- (RiveHitResult)touchBeganAtLocation:(CGPoint)touchLocation;

/// Tells this StateMachineInstance that a user began touching the artboard with
/// a specific touch ID
/// @param touchLocation A CGPoint in the coordinate space of the animating
/// artboard
/// @param touchID A unique identifier for the touch event, used for multitouch
/// support
/// @return The RiveHitResult of a touch beginning at the provided location.
- (RiveHitResult)touchBeganAtLocation:(CGPoint)touchLocation
                              touchID:(int)touchID;

/// Tells this StateMachineInstance that a touch moved on the artboard
/// @param touchLocation A CGPoint in the coordinate space of the animating
/// artboard
/// @return The RiveHitResult of a touch moving at the provided location.
- (RiveHitResult)touchMovedAtLocation:(CGPoint)touchLocation;

/// Tells this StateMachineInstance that a touch moved on the artboard with a
/// specific touch ID
/// @param touchLocation A CGPoint in the coordinate space of the animating
/// artboard
/// @param touchID A unique identifier for the touch event, used for multitouch
/// support
/// @return The RiveHitResult of a touch moving at the provided location.
- (RiveHitResult)touchMovedAtLocation:(CGPoint)touchLocation
                              touchID:(int)touchID;

/// Tells this StateMachineInstance that a user finished touching the artboard
/// @param touchLocation A CGPoint in the coordinate space of the animating
/// artboard
/// @return The RiveHitResult of a touch ending at the provided location.
- (RiveHitResult)touchEndedAtLocation:(CGPoint)touchLocation;

/// Tells this StateMachineInstance that a user finished touching the artboard
/// with a specific touch ID
/// @param touchLocation A CGPoint in the coordinate space of the animating
/// artboard
/// @param touchID A unique identifier for the touch event, used for multitouch
/// support
/// @return The RiveHitResult of a touch ending at the provided location.
- (RiveHitResult)touchEndedAtLocation:(CGPoint)touchLocation
                              touchID:(int)touchID;

/// Tells this StateMachineInstance that a user cancelled touching the artboard
/// @param touchLocation A CGPoint in the coordinate space of the animating
/// artboard
/// @return The RiveHitResult of a touch being cancelled at the provided
/// location.
- (RiveHitResult)touchCancelledAtLocation:(CGPoint)touchLocation;

/// Tells this StateMachineInstance that a user cancelled touching the artboard
/// with a specific touch ID
/// @param touchLocation A CGPoint in the coordinate space of the animating
/// artboard
/// @param touchID A unique identifier for the touch event, used for multitouch
/// support
/// @return The RiveHitResult of a touch being cancelled at the provided
/// location.
- (RiveHitResult)touchCancelledAtLocation:(CGPoint)touchLocation
                                  touchID:(int)touchID;

/// Tells this StateMachineInstance that a touch exited the artboard
/// @param touchLocation A CGPoint in the coordinate space of the animating
/// artboard
/// @return The RiveHitResult of a touch exiting at the provided location.
- (RiveHitResult)touchExitedAtLocation:(CGPoint)touchLocation;

/// Tells this StateMachineInstance that a touch exited the artboard with a
/// specific touch ID
/// @param touchLocation A CGPoint in the coordinate space of the animating
/// artboard
/// @param touchID A unique identifier for the touch event, used for multitouch
/// support
/// @return The RiveHitResult of a touch exiting at the provided location.
- (RiveHitResult)touchExitedAtLocation:(CGPoint)touchLocation
                               touchID:(int)touchID;

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
