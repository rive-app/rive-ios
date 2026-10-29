//
//  RivePropertyData.h
//  RiveRuntime
//
//  Created by David Skuza on 2/4/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, RiveDataBindingViewModelInstancePropertyDataType) {
  RiveDataBindingViewModelInstancePropertyDataTypeNone = 0,
  RiveDataBindingViewModelInstancePropertyDataTypeString,
  RiveDataBindingViewModelInstancePropertyDataTypeNumber,
  RiveDataBindingViewModelInstancePropertyDataTypeBoolean,
  RiveDataBindingViewModelInstancePropertyDataTypeColor,
  RiveDataBindingViewModelInstancePropertyDataTypeList,
  RiveDataBindingViewModelInstancePropertyDataTypeEnum,
  RiveDataBindingViewModelInstancePropertyDataTypeTrigger,
  RiveDataBindingViewModelInstancePropertyDataTypeViewModel,
  RiveDataBindingViewModelInstancePropertyDataTypeInteger,
  RiveDataBindingViewModelInstancePropertyDataTypeSymbolListIndex,
  RiveDataBindingViewModelInstancePropertyDataTypeAssetImage,
  RiveDataBindingViewModelInstancePropertyDataTypeAssetFont,
  RiveDataBindingViewModelInstancePropertyDataTypeAssetBlob,
  RiveDataBindingViewModelInstancePropertyDataTypeArtboard,
  RiveDataBindingViewModelInstancePropertyDataTypeInput,
  RiveDataBindingViewModelInstancePropertyDataTypeAny,
} NS_SWIFT_NAME(RiveDataBindingViewModelInstancePropertyData.DataType)
                    DEPRECATED_MSG_ATTRIBUTE(
                        "The legacy Data Binding property type API is "
                        "deprecated. Use ViewModelProperty.DataType from the "
                        "concurrency runtime instead. See "
                        "https://rive.app/docs/runtimes/apple/"
                        "migrating-from-legacy#view-model-instance-properties");

NS_ASSUME_NONNULL_BEGIN

/// An object that represents the metadata of a view model instance property.
NS_SWIFT_NAME(RiveDataBindingViewModelInstanceProperty.Data)
DEPRECATED_MSG_ATTRIBUTE(
    "The legacy Data Binding property metadata API is deprecated. Use "
    "ViewModelProperty from the concurrency runtime instead. See "
    "https://rive.app/docs/runtimes/apple/"
    "migrating-from-legacy#view-model-instance-properties")
@interface RiveDataBindingViewModelInstancePropertyData : NSObject

/// The type of property within the view model instance.
@property(nonatomic, readonly)
    RiveDataBindingViewModelInstancePropertyDataType type;

/// The name of the property within the view model instance.
@property(nonatomic, readonly) NSString* name;

@end

NS_ASSUME_NONNULL_END
