//
//  RiveDataBindingViewModelInstanceStringProperty.h
//  RiveRuntime
//
//  Created by David Skuza on 1/13/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <AppKit/NSColor.h>
#define RiveDataBindingViewModelInstanceColor NSColor
#else
#import <UIKit/UIColor.h>
#define RiveDataBindingViewModelInstanceColor UIColor
#endif

NS_ASSUME_NONNULL_BEGIN

/// An object that represents a property of a view model instance.
NS_SWIFT_NAME(RiveDataBindingViewModelInstance.Property)
@interface RiveDataBindingViewModelInstanceProperty : NSObject

/// The name of the property.
@property(nonatomic, readonly) NSString* name;

/// Returns whether the property has changed, and the change will be reflected
/// on next advance.
@property(nonatomic, readonly) BOOL hasChanged;

- (instancetype)init NS_UNAVAILABLE;

/// Resets a property's changed status, resetting `hasChanged` to false.
- (void)clearChanges;

/// Removes a listener for the property.
///
/// - Parameter listener: The listener to remove. This value will be returned by
/// the matching call to `addListener`.
- (void)removeListener:(NSUUID*)listener;

@end

#pragma mark - String

typedef void (^RiveDataBindingViewModelInstanceStringPropertyListener)(
    NSString*)
    NS_SWIFT_NAME(RiveDataBindingViewModelInstanceStringProperty.Listener);

/// An object that represents a string property of a view model instance.
NS_SWIFT_NAME(RiveDataBindingViewModelInstance.StringProperty)
@interface RiveDataBindingViewModelInstanceStringProperty
    : RiveDataBindingViewModelInstanceProperty

/// The string value of the property.
@property(nonatomic, copy) NSString* value;

- (instancetype)init NS_UNAVAILABLE;

/// Adds a block as a listener, called with the latest value when value is
/// updated.
///
/// - Note: The value can be updated either explicitly by the developer,
///  or as a result of a change in a state machine.
///
/// - Parameter listener: The block that will be called when the property's
/// value changes.
///
/// - Returns: A UUID for the listener, used in conjunction with
/// `removeListener`.
- (NSUUID*)addListener:
    (RiveDataBindingViewModelInstanceStringPropertyListener)listener;

@end

#pragma mark - Number

typedef void (^RiveDataBindingViewModelInstanceNumberPropertyListener)(float)
    NS_SWIFT_NAME(RiveDataBindingViewModelInstanceNumberProperty.Listener);

/// An object that represents a number property of a view model instance.
NS_SWIFT_NAME(RiveDataBindingViewModelInstance.NumberProperty)
@interface RiveDataBindingViewModelInstanceNumberProperty
    : RiveDataBindingViewModelInstanceProperty

/// The number value of the property.
@property(nonatomic, assign) float value;

- (instancetype)init NS_UNAVAILABLE;

/// Adds a block as a listener, called with the latest value when value is
/// updated.
///
/// - Note: The value can be updated either explicitly by the developer,
///  or as a result of a change in a state machine.
///
/// - Parameter listener: The block that will be called when the property's
/// value changes.
///
/// - Returns: A UUID for the listener, used in conjunction with
/// `removeListener`.
- (NSUUID*)addListener:
    (RiveDataBindingViewModelInstanceNumberPropertyListener)listener;

@end

#pragma mark - Boolean

typedef void (^RiveDataBindingViewModelInstanceBooleanPropertyListener)(BOOL)
    NS_SWIFT_NAME(RiveDataBindingViewModelInstanceBooleanProperty.Listener);

/// An object that represents a boolean property of a view model instance.
NS_SWIFT_NAME(RiveDataBindingViewModelInstance.BooleanProperty)
@interface RiveDataBindingViewModelInstanceBooleanProperty
    : RiveDataBindingViewModelInstanceProperty

/// The boolean value of the property.
@property(nonatomic, assign) BOOL value;

- (instancetype)init NS_UNAVAILABLE;

/// Adds a block as a listener, called with the latest value when value is
/// updated.
///
/// - Note: The value can be updated either explicitly by the developer,
///  or as a result of a change in a state machine.
///
/// - Parameter listener: The block that will be called when the property's
/// value changes.
///
/// - Returns: A UUID for the listener, used in conjunction with
/// `removeListener`.
- (NSUUID*)addListener:
    (RiveDataBindingViewModelInstanceBooleanPropertyListener)listener;

@end

#pragma mark - Color

typedef void (^RiveDataBindingViewModelInstanceColorPropertyListener)(
    RiveDataBindingViewModelInstanceColor*)
    NS_SWIFT_NAME(RiveDataBindingViewModelInstanceColorProperty.Listener);

/// An object that represents a color property of a view model instance.
NS_SWIFT_NAME(RiveDataBindingViewModelInstance.ColorProperty)
@interface RiveDataBindingViewModelInstanceColorProperty
    : RiveDataBindingViewModelInstanceProperty

/// The color value of the property as an integer, as 0xAARRGGBB.
@property(nonatomic, copy) RiveDataBindingViewModelInstanceColor* value;

- (instancetype)init NS_UNAVAILABLE;

/// Sets a new color value based on RGB values, preserving its alpha value.
/// - Parameters:
///   - red: The red value of the color (0-255).
///   - green: The green value of the color (0-255)
///   - blue: The blue value of the color (0-255)
- (void)setRed:(CGFloat)red
         green:(CGFloat)green
          blue:(CGFloat)blue NS_SWIFT_NAME(set(red:green:blue:));

/// Sets a new color value based on alpha and RGB values.
/// - Parameters:
///   - red: The red value of the color (0-255).
///   - green: The green value of the color (0-255)
///   - blue: The blue value of the color (0-255)
///   - alpha: The alpha value of the color (0-255)
- (void)setRed:(CGFloat)red
         green:(CGFloat)green
          blue:(CGFloat)blue
         alpha:(CGFloat)alpha NS_SWIFT_NAME(set(red:green:blue:alpha:));

/// Sets a new alpha value, preserving the current color.
- (void)setAlpha:(CGFloat)alpha;

/// Adds a block as a listener, called with the latest value when value is
/// updated.
///
/// - Note: The value can be updated either explicitly by the developer,
///  or as a result of a change in a state machine.
///
/// - Parameter listener: The block that will be called when the property's
/// value changes.
///
/// - Returns: A UUID for the listener, used in conjunction with
/// `removeListener`.
- (NSUUID*)addListener:
    (RiveDataBindingViewModelInstanceColorPropertyListener)listener;

@end

#pragma mark - Enum

typedef void (^RiveDataBindingViewModelInstanceEnumPropertyListener)(NSString*)
    NS_SWIFT_NAME(RiveDataBindingViewModelInstanceEnumProperty.Listener);

/// An object that represents an enum property of a view model instance.
NS_SWIFT_NAME(RiveDataBindingViewModelInstance.EnumProperty)
@interface RiveDataBindingViewModelInstanceEnumProperty
    : RiveDataBindingViewModelInstanceProperty

/// The current string value of the enum property.
@property(nonatomic, copy) NSString* value;

/// An array of all possible values for the enum.
@property(nonatomic, readonly) NSArray<NSString*>* values;

/// The index of the current value in `values`. Setting a new index will also
/// update the `value` of this property.
///
/// - Note: If the new index is outside of the bounds of `values`, this will do
/// nothing, or return 0.
@property(nonatomic, assign) int valueIndex;

- (instancetype)init NS_UNAVAILABLE;

/// Adds a block as a listener, called with the latest value when value is
/// updated.
///
/// - Note: The value can be updated either explicitly by the developer,
///  or as a result of a change in a state machine.
///
/// - Parameter listener: The block that will be called when the property's
/// value changes.
///
/// - Returns: A UUID for the listener, used in conjunction with
/// `removeListener`.
- (NSUUID*)addListener:
    (RiveDataBindingViewModelInstanceEnumPropertyListener)listener;

@end

#pragma mark - Trigger

typedef void (^RiveDataBindingViewModelInstanceTriggerPropertyListener)(void)
    NS_SWIFT_NAME(RiveDataBindingViewModelInstanceTriggerProperty.Listener);

/// An object that represents a trigger property of a view model instance.
NS_SWIFT_NAME(RiveDataBindingViewModelInstance.TriggerProperty)
@interface RiveDataBindingViewModelInstanceTriggerProperty
    : RiveDataBindingViewModelInstanceProperty

- (instancetype)init NS_UNAVAILABLE;

/// Triggers a trigger property.
- (void)trigger;

/// Adds a block as a listener, called when the property is triggered.
///
/// - Note: The property can be triggered either explicitly by the developer,
///  or as a result of a change in a state machine.
///
/// - Parameter listener: The block that will be called when the property's
/// value changes.
///
/// - Returns: A UUID for the listener, used in conjunction with
/// `removeListener`.
- (NSUUID*)addListener:
    (RiveDataBindingViewModelInstanceTriggerPropertyListener)listener;

@end

NS_ASSUME_NONNULL_END
