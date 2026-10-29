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
@class RiveSMIBool;
@class RiveSMITrigger;
@class RiveSMINumber;
@class RiveStateMachineInstance;
@class RiveRenderer;
@class RiveTextValueRun;
@class RiveDataBindingViewModelInstance;

// MARK: - RiveArtboard
//
DEPRECATED_MSG_ATTRIBUTE(
    "The legacy API is deprecated. Use Artboard from the concurrency runtime "
    "instead. See "
    "https://rive.app/docs/runtimes/apple/"
    "migrating-from-legacy#choosing-an-artboard-and-state-machine")
@interface RiveArtboard : NSObject

@property(nonatomic, assign) float volume NS_REFINED_FOR_SWIFT;
@property(nonatomic, readonly) BOOL didChange;

- (NSString*)name;
- (CGRect)bounds;

- (double)width;
- (double)height;
- (void)setWidth:(double)value;
- (void)setHeight:(double)value;
- (void)resetArtboardSize;

- (const RiveSMIBool*)getBool:(NSString*)name
                         path:(NSString*)path
    DEPRECATED_MSG_ATTRIBUTE(
        "The legacy state machine input API is deprecated. Use Data Binding "
        "properties instead. See "
        "https://rive.app/docs/runtimes/apple/"
        "migrating-from-legacy#state-machine-inputs");
- (const RiveSMITrigger*)getTrigger:(NSString*)name
                               path:(NSString*)path
    DEPRECATED_MSG_ATTRIBUTE(
        "The legacy state machine input API is deprecated. Use Data Binding "
        "properties instead. See "
        "https://rive.app/docs/runtimes/apple/"
        "migrating-from-legacy#state-machine-inputs");
- (const RiveSMINumber*)getNumber:(NSString*)name
                             path:(NSString*)path
    DEPRECATED_MSG_ATTRIBUTE(
        "The legacy state machine input API is deprecated. Use Data Binding "
        "properties instead. See "
        "https://rive.app/docs/runtimes/apple/"
        "migrating-from-legacy#state-machine-inputs");

- (NSInteger)animationCount DEPRECATED_MSG_ATTRIBUTE(
    "The legacy linear animation API is deprecated. Use a state machine to "
    "control playback instead. See "
    "https://rive.app/docs/runtimes/apple/"
    "migrating-from-legacy#linear-animations");
- (NSArray<NSString*>*)animationNames DEPRECATED_MSG_ATTRIBUTE(
    "The legacy linear animation API is deprecated. Use a state machine to "
    "control playback instead. See "
    "https://rive.app/docs/runtimes/apple/"
    "migrating-from-legacy#linear-animations");
- (RiveLinearAnimationInstance* __nullable)animationFromIndex:(NSInteger)index
                                                        error:(NSError**)error
    DEPRECATED_MSG_ATTRIBUTE(
        "The legacy linear animation API is deprecated. Use a state machine to "
        "control playback instead. See "
        "https://rive.app/docs/runtimes/apple/"
        "migrating-from-legacy#linear-animations");
- (RiveLinearAnimationInstance* __nullable)animationFromName:(NSString*)name
                                                       error:(NSError**)error
    DEPRECATED_MSG_ATTRIBUTE(
        "The legacy linear animation API is deprecated. Use a state machine to "
        "control playback instead. See "
        "https://rive.app/docs/runtimes/apple/"
        "migrating-from-legacy#linear-animations");

- (NSInteger)stateMachineCount;
- (NSArray<NSString*>*)stateMachineNames;
- (RiveStateMachineInstance* __nullable)stateMachineFromIndex:(NSInteger)index
                                                        error:(NSError**)error;
- (RiveStateMachineInstance* __nullable)stateMachineFromName:(NSString*)name
                                                       error:(NSError**)error;
- (RiveStateMachineInstance* __nullable)defaultStateMachine;

- (RiveTextValueRun* __nullable)textRun:(NSString*)name
    DEPRECATED_MSG_ATTRIBUTE(
        "The legacy text run API is deprecated. Use Data Binding string "
        "properties instead. See "
        "https://rive.app/docs/runtimes/apple/"
        "migrating-from-legacy#view-model-instance-properties");
- (RiveTextValueRun* __nullable)textRun:(NSString*)name
                                   path:(NSString*)path
    DEPRECATED_MSG_ATTRIBUTE(
        "The legacy text run API is deprecated. Use Data Binding string "
        "properties instead. See "
        "https://rive.app/docs/runtimes/apple/"
        "migrating-from-legacy#view-model-instance-properties");

- (void)advanceBy:(double)elapsedSeconds;
- (void)draw:(RiveRenderer*)renderer;

// MARK: - Data Binding

/// Binds an instance of a view model to the artboard for updates.
///
/// A strong reference to the instance being bound must be made if you wish to
/// reuse instance properties, or for observability.
///
/// The same instance must also be bound to a state machine, if one exists.
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
