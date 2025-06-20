//
//  RivePropertyData.m
//  RiveRuntime
//
//  Created by David Skuza on 2/4/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>

RiveDataBindingViewModelInstancePropertyDataType
RiveDataBindingViewModelInstancePropertyDataTypeFromRuntime(rive::DataType type)
{
    switch (type)
    {
        case rive::DataType::none:
            return RiveDataBindingViewModelInstancePropertyDataTypeNone;
        case rive::DataType::string:
            return RiveDataBindingViewModelInstancePropertyDataTypeString;
        case rive::DataType::number:
            return RiveDataBindingViewModelInstancePropertyDataTypeNumber;
        case rive::DataType::boolean:
            return RiveDataBindingViewModelInstancePropertyDataTypeBoolean;
        case rive::DataType::color:
            return RiveDataBindingViewModelInstancePropertyDataTypeColor;
        case rive::DataType::list:
            return RiveDataBindingViewModelInstancePropertyDataTypeList;
        case rive::DataType::enumType:
            return RiveDataBindingViewModelInstancePropertyDataTypeEnum;
        case rive::DataType::trigger:
            return RiveDataBindingViewModelInstancePropertyDataTypeTrigger;
        case rive::DataType::viewModel:
            return RiveDataBindingViewModelInstancePropertyDataTypeViewModel;
        case rive::DataType::integer:
            return RiveDataBindingViewModelInstancePropertyDataTypeInteger;
        case rive::DataType::symbolListIndex:
            return RiveDataBindingViewModelInstancePropertyDataTypeSymbolListIndex;
        case rive::DataType::assetImage:
            return RiveDataBindingViewModelInstancePropertyDataTypeAssetImage;
        case rive::DataType::artboard:
            return RiveDataBindingViewModelInstancePropertyDataTypeNone;
    }
}

@implementation RiveDataBindingViewModelInstancePropertyData

- (instancetype)initWithData:(rive::PropertyData)data
{
    if (self = [super init])
    {
        _type = RiveDataBindingViewModelInstancePropertyDataTypeFromRuntime(
            data.type);
        _name = [NSString stringWithCString:data.name.c_str()
                                   encoding:NSUTF8StringEncoding];
    }
    return self;
}

@end
