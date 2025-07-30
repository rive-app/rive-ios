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
    RiveDataBindingViewModelInstancePropertyDataTypeArtboard,
} NS_SWIFT_NAME(RiveDataBindingViewModelInstancePropertyData.DataType);

NS_ASSUME_NONNULL_BEGIN

/// An object that represents the metadata of a view model instance property.
NS_SWIFT_NAME(RiveDataBindingViewModelInstanceProperty.Data)
@interface RiveDataBindingViewModelInstancePropertyData : NSObject

/// The type of property within the view model instance.
@property(nonatomic, readonly)
    RiveDataBindingViewModelInstancePropertyDataType type;

/// The name of the property within the view model instance.
@property(nonatomic, readonly) NSString* name;

@end

NS_ASSUME_NONNULL_END
