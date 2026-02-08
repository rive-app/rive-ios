//
//  RiveViewModelInstanceData.mm
//  RiveRuntime
//
//  Created by David Skuza on 11/19/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <rive/command_queue.hpp>
#import "RiveViewModelInstanceData.h"

namespace
{
/**
 * Converts a C++ rive::DataType enum value to the corresponding
 * Objective-C RiveViewModelInstanceDataType enum value.
 */
RiveViewModelInstanceDataType RiveViewModelInstanceDataTypeFromCpp(
    rive::DataType type)
{
    switch (type)
    {
        case rive::DataType::none:
            return RiveViewModelInstanceDataTypeNone;
        case rive::DataType::string:
            return RiveViewModelInstanceDataTypeString;
        case rive::DataType::number:
            return RiveViewModelInstanceDataTypeNumber;
        case rive::DataType::boolean:
            return RiveViewModelInstanceDataTypeBoolean;
        case rive::DataType::color:
            return RiveViewModelInstanceDataTypeColor;
        case rive::DataType::list:
            return RiveViewModelInstanceDataTypeList;
        case rive::DataType::enumType:
            return RiveViewModelInstanceDataTypeEnum;
        case rive::DataType::trigger:
            return RiveViewModelInstanceDataTypeTrigger;
        case rive::DataType::viewModel:
            return RiveViewModelInstanceDataTypeViewModel;
        case rive::DataType::integer:
            return RiveViewModelInstanceDataTypeInteger;
        case rive::DataType::symbolListIndex:
            return RiveViewModelInstanceDataTypeSymbolListIndex;
        case rive::DataType::assetImage:
            return RiveViewModelInstanceDataTypeAssetImage;
        case rive::DataType::artboard:
            return RiveViewModelInstanceDataTypeArtboard;
        case rive::DataType::input:
            return RiveViewModelInstanceDataTypeInput;
        case rive::DataType::any:
            return RiveViewModelInstanceDataTypeAny;
    }
}
} // namespace

@implementation RiveViewModelInstanceData
{
    RiveViewModelInstanceDataType _type;
    NSString* _name;
    NSNumber* _boolValue;
    NSNumber* _numberValue;
    NSString* _stringValue;
    NSNumber* _colorValue;
}

- (instancetype)initWithData:(rive::CommandQueue::ViewModelInstanceData)data
{
    if (self = [super init])
    {
        _type = RiveViewModelInstanceDataTypeFromCpp(data.metaData.type);
        _name = [NSString stringWithUTF8String:data.metaData.name.c_str()];

        // Extract the appropriate value based on the type
        switch (data.metaData.type)
        {
            case rive::DataType::boolean:
                _boolValue = @(data.boolValue);
                break;
            case rive::DataType::number:
                _numberValue = @(data.numberValue);
                break;
            case rive::DataType::color:
                _colorValue = @(data.colorValue);
                break;
            case rive::DataType::string:
            case rive::DataType::enumType:
                _stringValue = [NSString
                    stringWithUTF8String:data.stringValue.c_str()];
                break;
            default:
                // For other types, try stringValue if it's not empty
                if (!data.stringValue.empty())
                {
                    _stringValue = [NSString
                        stringWithUTF8String:data.stringValue.c_str()];
                }
                break;
        }
    }
    return self;
}

- (RiveViewModelInstanceDataType)type
{
    return _type;
}

- (NSString*)name
{
    return _name;
}

- (NSNumber*)boolValue
{
    return _boolValue;
}

- (NSNumber*)numberValue
{
    return _numberValue;
}

- (NSString*)stringValue
{
    return _stringValue;
}

- (NSNumber*)colorValue
{
    return _colorValue;
}

@end
