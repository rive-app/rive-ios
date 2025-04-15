//
//  RiveDataBindingViewModelInstance.h
//  RiveRuntime
//
//  Created by David Skuza on 1/13/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RiveDataBindingViewModelInstanceProperty;
@class RiveDataBindingViewModelInstanceStringProperty;
@class RiveDataBindingViewModelInstanceNumberProperty;
@class RiveDataBindingViewModelInstanceBooleanProperty;
@class RiveDataBindingViewModelInstanceColorProperty;
@class RiveDataBindingViewModelInstanceEnumProperty;
@class RiveDataBindingViewModelInstanceTriggerProperty;
@class RiveDataBindingViewModelInstancePropertyData;

/// An object that represents an instance of a view model, used to update
/// bindings at runtime.
///
/// - Note: A strong reference to this instance must be maintained if it is
/// being bound to a state machine or artboard, or for observability. If a
/// property is fetched from an instance different to that bound to an artboard
/// or state machine, its value or trigger will not be updated.
NS_SWIFT_NAME(RiveDataBindingViewModel.Instance)
@interface RiveDataBindingViewModelInstance : NSObject

/// The name of the view model instance.
@property(nonatomic, readonly) NSString* name;

/// The number of all properties in the view model instance.
@property(nonatomic, readonly) NSUInteger propertyCount;

/// An array of property data of all properties in the view model instance.
@property(nonatomic, readonly)
    NSArray<RiveDataBindingViewModelInstancePropertyData*>* properties;

/// Gets a property from the view model instance. This property is the
/// superclass of all other property types.
///
/// - Note: Unlike a `RiveViewModel.Instance`, a strong reference to this type
/// does not have to be made. If the property exists, the underlying property
/// will be cached, and calling this function again with the same path is
/// guaranteed to return the same object.
///
/// - Parameter path: The path to the property.
///
/// - Returns: The property if it exists at the supplied path, otherwise nil.
- (nullable RiveDataBindingViewModelInstanceProperty*)propertyFromPath:
    (NSString*)path;

/// Gets a string property in the view model instance.
///
/// - Note: Unlike a `RiveViewModel.Instance`, a strong reference to this type
/// does not have to be made. If the property exists, the underlying property
/// will be cached, and calling this function again with the same path is
/// guaranteed to return the same object.
///
/// - Parameter path: The path to the string property.
///
/// - Returns: The property if it exists at the supplied path, otherwise nil.
- (nullable RiveDataBindingViewModelInstanceStringProperty*)
    stringPropertyFromPath:(NSString*)path;

/// Gets a number property in the view model instance.
///
/// - Note: Unlike a `RiveViewModel.Instance`, a strong reference to this type
/// does not have to be made. If the property exists, the underlying property
/// will be cached, and calling this function again with the same path is
/// guaranteed to return the same object.
///
/// - Parameter path: The path to the number property.
///
/// - Returns: The property if it exists at the supplied path, otherwise nil.
- (nullable RiveDataBindingViewModelInstanceNumberProperty*)
    numberPropertyFromPath:(NSString*)path;

/// Gets a boolean property in the view model instance.
///
/// - Note: Unlike a `RiveViewModel.Instance`, a strong reference to this type
/// does not have to be made. If the property exists, the underlying property
/// will be cached, and calling this function again with the same path is
/// guaranteed to return the same object.
///
/// - Parameter path: The path to the number property.
///
/// - Returns: The property if it exists at the supplied path, otherwise nil.
- (nullable RiveDataBindingViewModelInstanceBooleanProperty*)
    booleanPropertyFromPath:(NSString*)path;

/// Gets a color property in the view model instance.
///
/// - Note: Unlike a `RiveViewModel.Instance`, a strong reference to this type
/// does not have to be made. If the property exists, the underlying property
/// will be cached, and calling this function again with the same path is
/// guaranteed to return the same object.
///
/// - Parameter path: The path to the number property.
///
/// - Returns: The property if it exists at the supplied path, otherwise nil.
- (nullable RiveDataBindingViewModelInstanceColorProperty*)
    colorPropertyFromPath:(NSString*)path;

/// Gets a enum property in the view model instance.
///
/// - Note: Unlike a `RiveViewModel.Instance`, a strong reference to this type
/// does not have to be made. If the property exists, the underlying property
/// will be cached, and calling this function again with the same path is
/// guaranteed to return the same object.
///
/// - Parameter path: The path to the number property.
///
/// - Returns: The property if it exists at the supplied path, otherwise nil.
- (nullable RiveDataBindingViewModelInstanceEnumProperty*)enumPropertyFromPath:
    (NSString*)path;

/// Gets a view model property in the view model instance.
///
/// - Note: Unlike a `RiveViewModel.Instance`, a strong reference to this type
/// does not have to be made. If the property exists, the underlying property
/// will be cached, and calling this function again with the same path is
/// guaranteed to return the same object.
///
/// - Parameter path: The path to the number property.
///
/// - Returns: The property if it exists at the supplied path, otherwise nil.
- (nullable RiveDataBindingViewModelInstance*)viewModelInstancePropertyFromPath:
    (NSString*)path;

/// Returns a trigger property in the view model instance.
///
/// - Note: Unlike a `RiveViewModel.Instance`, a strong reference to this type
/// does not have to be made. If the property exists, the underlying property
/// will be cached, and calling this function again with the same path is
/// guaranteed to return the same object.
///
/// - Parameter path: The path to the number property.
///
/// - Returns: The property if it exists at the supplied path, otherwise nil.
- (nullable RiveDataBindingViewModelInstanceTriggerProperty*)
    triggerPropertyFromPath:(NSString*)path;

/// Calls all registered property listeners for the properties of the view model
/// instance.
- (void)updateListeners;

@end

NS_ASSUME_NONNULL_END
