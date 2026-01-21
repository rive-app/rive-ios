//
//  RiveViewModelInstanceData.h
//  RiveRuntime
//
//  Created by David Skuza on 11/19/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RiveRuntime/RiveEnums.h>

NS_ASSUME_NONNULL_BEGIN

/// An object that represents view model instance data received from the command
/// queue.
///
/// This class bridges the C++ ViewModelInstanceData structure (which uses a
/// union to store different value types) into Objective-C. Since Objective-C
/// doesn't support unions directly, this class exposes separate properties for
/// each possible value type.
///
/// Usage pattern:
/// 1. Check the `type` property to determine which value property is valid
/// 2. Access the corresponding value property (boolValue, numberValue, etc.)
/// 3. Other value properties will be nil for the given type
///
/// For example, if type is RiveViewModelInstanceDataTypeBoolean, only
/// boolValue will be non-nil. If type is RiveViewModelInstanceDataTypeString,
/// only stringValue will be non-nil.
///
/// @note This is a read-only data container. Values are set by the command
///       queue when delivering property updates via listener callbacks.
@interface RiveViewModelInstanceData : NSObject

/// The type of the property data.
@property(nonatomic, readonly) RiveViewModelInstanceDataType type;

/// The name/path of the property.
@property(nonatomic, readonly) NSString* name;

/// The boolean value (valid when type is boolean).
@property(nonatomic, readonly, nullable) NSNumber* boolValue;

/// The number value (valid when type is number).
@property(nonatomic, readonly, nullable) NSNumber* numberValue;

/// The string value (valid when type is string or enumType).
@property(nonatomic, readonly, nullable) NSString* stringValue;

/// The color value as a 32-bit ARGB integer (valid when type is color).
@property(nonatomic, readonly, nullable) NSNumber* colorValue;

@end

NS_ASSUME_NONNULL_END
