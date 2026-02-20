//
//  RiveCommandQueue.mm
//  RiveRuntime
//
//  Created by David Skuza on 8/4/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <rive/command_queue.hpp>
#import <rive/command_server.hpp>
#import <QuartzCore/CoreAnimation.h>
#import "RiveArtboardListener.h"
#import "RiveRenderImageListener.h"
#import "RiveFontListener.h"
#import "RiveAudioListener.h"
#import "RivePrivateHeaders.h"
#import "RiveExperimental_Private.hh"

#if TARGET_OS_OSX && !RIVE_MAC_CATALYST
#define RIVE_USE_CVDISPLAYLINK 1
#else
#define RIVE_USE_CVDISPLAYLINK 0
#endif

NS_ASSUME_NONNULL_BEGIN

rive::DataType RiveViewModelInstanceDataTypeToCppType(
    RiveViewModelInstanceDataType type)
{
    switch (type)
    {
        case RiveViewModelInstanceDataTypeNone:
            return rive::DataType::none;
        case RiveViewModelInstanceDataTypeString:
            return rive::DataType::string;
        case RiveViewModelInstanceDataTypeNumber:
            return rive::DataType::number;
        case RiveViewModelInstanceDataTypeBoolean:
            return rive::DataType::boolean;
        case RiveViewModelInstanceDataTypeColor:
            return rive::DataType::color;
        case RiveViewModelInstanceDataTypeList:
            return rive::DataType::list;
        case RiveViewModelInstanceDataTypeEnum:
            return rive::DataType::enumType;
        case RiveViewModelInstanceDataTypeTrigger:
            return rive::DataType::trigger;
        case RiveViewModelInstanceDataTypeViewModel:
            return rive::DataType::viewModel;
        case RiveViewModelInstanceDataTypeInteger:
            return rive::DataType::integer;
        case RiveViewModelInstanceDataTypeSymbolListIndex:
            return rive::DataType::symbolListIndex;
        case RiveViewModelInstanceDataTypeAssetImage:
            return rive::DataType::assetImage;
        case RiveViewModelInstanceDataTypeArtboard:
            return rive::DataType::artboard;
        case RiveViewModelInstanceDataTypeInput:
            return rive::DataType::input;
        case RiveViewModelInstanceDataTypeAny:
            return rive::DataType::any;
    }
}

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

static rive::Fit RiveConfigurationFitCppValue(RiveConfigurationFit fit)
{
    switch (fit)
    {
        case RiveConfigurationFitFill:
            return rive::Fit::fill;
        case RiveConfigurationFitContain:
            return rive::Fit::contain;
        case RiveConfigurationFitCover:
            return rive::Fit::cover;
        case RiveConfigurationFitFitWidth:
            return rive::Fit::fitWidth;
        case RiveConfigurationFitFitHeight:
            return rive::Fit::fitHeight;
        case RiveConfigurationFitNone:
            return rive::Fit::none;
        case RiveConfigurationFitScaleDown:
            return rive::Fit::scaleDown;
        case RiveConfigurationFitLayout:
            return rive::Fit::layout;
    }
}

static rive::Alignment RiveConfigurationAlignmentCppValue(
    RiveConfigurationAlignment alignment)
{
    switch (alignment)
    {
        case RiveConfigurationAlignmentTopLeft:
            return rive::Alignment::topLeft;
        case RiveConfigurationAlignmentTopCenter:
            return rive::Alignment::topCenter;
        case RiveConfigurationAlignmentTopRight:
            return rive::Alignment::topRight;
        case RiveConfigurationAlignmentCenterLeft:
            return rive::Alignment::centerLeft;
        case RiveConfigurationAlignmentCenter:
            return rive::Alignment::center;
        case RiveConfigurationAlignmentCenterRight:
            return rive::Alignment::centerRight;
        case RiveConfigurationAlignmentBottomLeft:
            return rive::Alignment::bottomLeft;
        case RiveConfigurationAlignmentBottomCenter:
            return rive::Alignment::bottomCenter;
        case RiveConfigurationAlignmentBottomRight:
            return rive::Alignment::bottomRight;
    }
}

static rive::CommandQueue::PointerEvent RivePointerEventToCpp(
    CGPoint position,
    CGSize screenBounds,
    RiveConfigurationFit fit,
    RiveConfigurationAlignment alignment,
    float scaleFactor)
{
    rive::CommandQueue::PointerEvent cppEvent;
    cppEvent.fit = RiveConfigurationFitCppValue(fit);
    cppEvent.alignment = RiveConfigurationAlignmentCppValue(alignment);
    cppEvent.screenBounds =
        rive::Vec2D(screenBounds.width, screenBounds.height);
    cppEvent.position = rive::Vec2D(position.x, position.y);
    cppEvent.scaleFactor = scaleFactor;
    return cppEvent;
}

// MARK: - Internal Artboard Listener Implementation

namespace
{
/**
 * @class _ArtboardListener
 *
 * Internal C++ implementation of the Rive artboard listener that bridges
 * between the C++ command queue system and a single Objective-C observer.
 *
 * This class implements the rive::CommandQueue::ArtboardListener interface
 * and forwards events to a single Objective-C observer.
 */
class _ArtboardListener : public rive::CommandQueue::ArtboardListener
{
public:
    /**
     * Constructs a new artboard listener with the specified observer.
     *
     * @param observer The Objective-C observer that will receive artboard
     * events. The observer is held as a weak reference to avoid retain cycles.
     */
    _ArtboardListener(id<RiveArtboardListener> observer)
    {
        _observer = observer;
    }

    /**
     * Called when an artboard encounters an error during operations.
     *
     * This method is invoked by the C++ command queue when an artboard
     * operation fails. It converts the C++ error data to Objective-C objects
     * and forwards the event to the registered observer.
     *
     * @param handle The artboard handle that encountered the error.
     * @param requestId The unique identifier for the request that failed.
     * @param error A string describing the error that occurred.
     */
    virtual void onArtboardError(const rive::ArtboardHandle handle,
                                 uint64_t requestId,
                                 std::string error) override;

    virtual void onArtboardDeleted(const rive::ArtboardHandle handle,
                                   uint64_t requestId) override;

    /**
     * Called when state machine names are listed for an artboard.
     *
     * This method is invoked by the C++ command queue when a state machine
     * names request completes. It converts the C++ data to Objective-C objects
     * and forwards the event to the registered observer.
     *
     * @param handle The artboard handle that was queried.
     * @param requestId The unique identifier for the request that completed.
     * @param stateMachineNames Vector of state machine names from the C++
     * runtime.
     */
    virtual void onStateMachinesListed(
        const rive::ArtboardHandle handle,
        uint64_t requestId,
        std::vector<std::string> stateMachineNames) override;

    /**
     * Called when default view model information is received for an artboard.
     *
     * This method is invoked by the C++ command queue when a default view model
     * info request completes. It converts the C++ data to Objective-C objects
     * and forwards the event to the registered observer.
     *
     * @param handle The artboard handle that was queried.
     * @param requestId The unique identifier for the request that completed.
     * @param viewModelName The name of the default view model from the C++
     * runtime.
     * @param instanceName The name of the default view model instance from the
     * C++ runtime.
     */
    virtual void onDefaultViewModelInfoReceived(
        const rive::ArtboardHandle handle,
        uint64_t requestId,
        std::string viewModelName,
        std::string instanceName) override;

private:
    __weak id<RiveArtboardListener> _observer;
};
} // namespace

void _ArtboardListener::onArtboardError(const rive::ArtboardHandle handle,
                                        uint64_t requestId,
                                        std::string error)
{
    if (_observer)
    {
        [_observer
            onArtboardError:reinterpret_cast<uint64_t>(handle)
                  requestID:requestId
                    message:[NSString stringWithUTF8String:error.c_str()]];
    }
}

void _ArtboardListener::onArtboardDeleted(const rive::ArtboardHandle handle,
                                          uint64_t requestId)
{
    if (_observer)
    {
        [_observer onArtboardDeleted:reinterpret_cast<uint64_t>(handle)
                           requestID:requestId];
    }
}

void _ArtboardListener::onStateMachinesListed(
    const rive::ArtboardHandle handle,
    uint64_t requestId,
    std::vector<std::string> stateMachineNames)
{
    if (_observer)
    {
        NSMutableArray<NSString*>* names =
            [NSMutableArray arrayWithCapacity:stateMachineNames.size()];
        for (const auto& name : stateMachineNames)
        {
            [names addObject:[NSString stringWithUTF8String:name.c_str()]];
        }
        [_observer onStateMachineNamesListed:reinterpret_cast<uint64_t>(handle)
                                       names:names
                                   requestID:requestId];
    }
}

void _ArtboardListener::onDefaultViewModelInfoReceived(
    const rive::ArtboardHandle handle,
    uint64_t requestId,
    std::string viewModelName,
    std::string instanceName)
{
    if (_observer)
    {
        NSString* viewModelNameObjC =
            [NSString stringWithUTF8String:viewModelName.c_str()];
        NSString* instanceNameObjC =
            [NSString stringWithUTF8String:instanceName.c_str()];
        [_observer
            onDefaultViewModelInfoReceived:reinterpret_cast<uint64_t>(handle)
                                 requestID:requestId
                             viewModelName:viewModelNameObjC
                              instanceName:instanceNameObjC];
    }
}

// MARK: - Internal File Listener Implementation

namespace
{
/**
 * @class _FileListener
 *
 * Internal C++ implementation of the Rive file listener that bridges
 * between the C++ command queue system and a single Objective-C observer.
 *
 * This class implements the rive::CommandQueue::FileListener interface
 * and forwards events to a single Objective-C observer.
 */
class _FileListener : public rive::CommandQueue::FileListener
{
public:
    /**
     * Constructs a new file listener with the specified observer.
     *
     * @param observer The Objective-C observer that will receive file events.
     *                 The observer is held as a weak reference to avoid retain
     *                 cycles.
     */
    _FileListener(id<RiveFileListener> observer) { _observer = observer; }

    /**
     * Called when a file loading operation encounters an error.
     *
     * @param handle The file handle that was being loaded
     * @param requestId The identifier of the failed request
     * @param error A string describing the error that occurred
     */
    virtual void onFileError(const rive::FileHandle handle,
                             uint64_t requestId,
                             std::string error) override;

    /**
     * Called when a file is successfully loaded by the command server.
     *
     * @param handle The unique identifier of the loaded file
     * @param requestId The identifier of the loading request
     */
    virtual void onFileLoaded(const rive::FileHandle handle,
                              uint64_t requestId) override;

    /**
     * Called when a file is deleted from the command server.
     *
     * @param handle The unique identifier of the deleted file
     * @param requestId The identifier of the deletion request
     */
    virtual void onFileDeleted(const rive::FileHandle handle,
                               uint64_t requestId) override;

    /**
     * Called when artboard names are listed for a file.
     *
     * @param handle The unique identifier of the file
     * @param requestId The identifier of the listing request
     * @param artboardNames Vector of artboard names in the file
     */
    virtual void onArtboardsListed(
        const rive::FileHandle handle,
        uint64_t requestId,
        std::vector<std::string> artboardNames) override;

    /**
     * Called when view model names are listed for a file.
     *
     * @param handle The unique identifier of the file
     * @param requestId The identifier of the listing request
     * @param viewModelNames Vector of view model names in the file
     */
    virtual void onViewModelsListed(
        const rive::FileHandle handle,
        uint64_t requestId,
        std::vector<std::string> viewModelNames) override;

    /**
     * Called when view model instance names are listed for a file.
     *
     * @param handle The unique identifier of the file
     * @param requestId The identifier of the listing request
     * @param viewModelName The name of the view model
     * @param instanceNames Vector of view model instance names
     */
    virtual void onViewModelInstanceNamesListed(
        const rive::FileHandle handle,
        uint64_t requestId,
        std::string viewModelName,
        std::vector<std::string> instanceNames) override;

    /**
     * Called when view model properties are listed for a file.
     *
     * @param handle The unique identifier of the file
     * @param requestId The identifier of the listing request
     * @param viewModelName The name of the view model
     * @param properties Vector of view model property data
     */
    virtual void onViewModelPropertiesListed(
        const rive::FileHandle handle,
        uint64_t requestId,
        std::string viewModelName,
        std::vector<rive::CommandQueue::FileListener::ViewModelPropertyData>
            properties) override;

    /**
     * Called when view model enums are listed for a file.
     *
     * @param handle The unique identifier of the file
     * @param requestId The identifier of the listing request
     * @param enums Vector of view model enum data
     */
    virtual void onViewModelEnumsListed(
        const rive::FileHandle handle,
        uint64_t requestId,
        std::vector<rive::ViewModelEnum> enums) override;

private:
    __weak id<RiveFileListener> _observer;
};
} // namespace

void _FileListener::onFileError(const rive::FileHandle handle,
                                uint64_t requestId,
                                std::string error)
{
    if (_observer)
    {
        [_observer onFileError:reinterpret_cast<uint64_t>(handle)
                     requestID:requestId
                       message:[NSString stringWithUTF8String:error.c_str()]];
    }
}

void _FileListener::onFileLoaded(const rive::FileHandle handle,
                                 uint64_t requestId)
{
    if (_observer)
    {
        [_observer onFileLoaded:reinterpret_cast<uint64_t>(handle)
                      requestID:reinterpret_cast<uint64_t>(requestId)];
    }
}

void _FileListener::onFileDeleted(const rive::FileHandle handle,
                                  uint64_t requestId)
{
    if (_observer)
    {
        [_observer onFileDeleted:reinterpret_cast<uint64_t>(handle)
                       requestID:reinterpret_cast<uint64_t>(requestId)];
    }
}

void _FileListener::onArtboardsListed(const rive::FileHandle handle,
                                      uint64_t requestId,
                                      std::vector<std::string> artboardNames)
{
    if (_observer)
    {
        NSMutableArray<NSString*>* names =
            [NSMutableArray arrayWithCapacity:artboardNames.size()];
        for (const auto& name : artboardNames)
        {
            [names addObject:[NSString stringWithUTF8String:name.c_str()]];
        }

        [_observer onArtboardsListed:reinterpret_cast<uint64_t>(handle)
                           requestID:requestId
                               names:names];
    }
}

void _FileListener::onViewModelsListed(const rive::FileHandle handle,
                                       uint64_t requestId,
                                       std::vector<std::string> viewModelNames)
{
    if (_observer)
    {
        NSMutableArray<NSString*>* names =
            [NSMutableArray arrayWithCapacity:viewModelNames.size()];
        for (const auto& name : viewModelNames)
        {
            [names addObject:[NSString stringWithUTF8String:name.c_str()]];
        }

        [_observer onViewModelsListed:reinterpret_cast<uint64_t>(handle)
                            requestID:requestId
                                names:names];
    }
}

void _FileListener::onViewModelInstanceNamesListed(
    const rive::FileHandle handle,
    uint64_t requestId,
    std::string viewModelName,
    std::vector<std::string> instanceNames)
{
    if (_observer)
    {
        NSMutableArray<NSString*>* names =
            [NSMutableArray arrayWithCapacity:instanceNames.size()];
        for (const auto& name : instanceNames)
        {
            [names addObject:[NSString stringWithUTF8String:name.c_str()]];
        }

        NSString* nsViewModelName =
            [NSString stringWithUTF8String:viewModelName.c_str()];
        [_observer
            onViewModelInstanceNamesListed:reinterpret_cast<uint64_t>(handle)
                                 requestID:requestId
                             viewModelName:nsViewModelName
                                     names:names];
    }
}

void _FileListener::onViewModelPropertiesListed(
    const rive::FileHandle handle,
    uint64_t requestId,
    std::string viewModelName,
    std::vector<rive::CommandQueue::FileListener::ViewModelPropertyData>
        properties)
{
    if (_observer)
    {
        NSMutableArray<NSDictionary<NSString*, id>*>* propertyArray =
            [NSMutableArray arrayWithCapacity:properties.size()];

        for (const auto& prop : properties)
        {
            NSMutableDictionary<NSString*, id>* propertyDict =
                [NSMutableDictionary dictionary];

            // Convert type
            RiveViewModelInstanceDataType type =
                RiveViewModelInstanceDataTypeFromCpp(prop.type);
            propertyDict[@"type"] = @(type);

            // Convert name
            propertyDict[@"name"] =
                [NSString stringWithUTF8String:prop.name.c_str()];

            // Convert metaData (may be empty)
            propertyDict[@"metaData"] =
                [NSString stringWithUTF8String:prop.metaData.c_str()];

            [propertyArray addObject:propertyDict];
        }

        NSString* nsViewModelName =
            [NSString stringWithUTF8String:viewModelName.c_str()];
        [_observer
            onViewModelPropertiesListed:reinterpret_cast<uint64_t>(handle)
                              requestID:requestId
                          viewModelName:nsViewModelName
                             properties:propertyArray];
    }
}

void _FileListener::onViewModelEnumsListed(
    const rive::FileHandle handle,
    uint64_t requestId,
    std::vector<rive::ViewModelEnum> enums)
{
    if (_observer)
    {
        NSMutableArray<NSDictionary<NSString*, id>*>* enumArray =
            [NSMutableArray arrayWithCapacity:enums.size()];

        for (const auto& enumData : enums)
        {
            NSMutableDictionary<NSString*, id>* enumDict =
                [NSMutableDictionary dictionary];

            // Convert name
            enumDict[@"name"] =
                [NSString stringWithUTF8String:enumData.name.c_str()];

            // Convert enumerants
            NSMutableArray<NSString*>* values =
                [NSMutableArray arrayWithCapacity:enumData.enumerants.size()];
            for (const auto& enumerant : enumData.enumerants)
            {
                [values addObject:[NSString
                                      stringWithUTF8String:enumerant.c_str()]];
            }
            enumDict[@"values"] = values;

            [enumArray addObject:enumDict];
        }

        [_observer onViewModelEnumsListed:reinterpret_cast<uint64_t>(handle)
                                requestID:requestId
                                    enums:enumArray];
    }
}

namespace
{
/**
 * @class _ViewModelInstanceListener
 *
 * Internal C++ implementation of the Rive view model instance listener that
 * bridges between the C++ command queue system and a single Objective-C
 * observer.
 *
 * This class implements the rive::CommandQueue::ViewModelInstanceListener
 * interface and forwards events to a single Objective-C observer.
 */
class _ViewModelInstanceListener
    : public rive::CommandQueue::ViewModelInstanceListener
{
public:
    /**
     * Constructs a new view model instance listener with the specified
     * observer.
     *
     * @param observer The Objective-C observer that will receive view model
     *                 instance events. The observer is held as a weak reference
     *                 to avoid retain cycles.
     */
    _ViewModelInstanceListener(id<RiveViewModelInstanceListener> observer)
    {
        _observer = observer;
    }

    /**
     * Called when a view model instance operation encounters an error.
     *
     * @param handle The view model instance handle that encountered the error
     * @param requestId The identifier of the failed request
     * @param error A string describing the error that occurred
     */
    virtual void onViewModelInstanceError(
        const rive::ViewModelInstanceHandle handle,
        uint64_t requestId,
        std::string error) override;

    /**
     * Called when a view model instance is deleted from the command server.
     *
     * @param handle The unique identifier of the deleted view model instance
     * @param requestId The identifier of the deletion request
     */
    virtual void onViewModelDeleted(const rive::ViewModelInstanceHandle handle,
                                    uint64_t requestId) override;

    /**
     * Called when view model instance data is received.
     *
     * @param handle The unique identifier of the view model instance
     * @param requestId The identifier of the data request
     * @param data The view model instance data that was received
     */
    virtual void onViewModelDataReceived(
        const rive::ViewModelInstanceHandle handle,
        uint64_t requestId,
        rive::CommandQueue::ViewModelInstanceData data) override;

    /**
     * Called when a view model instance list size is received.
     *
     * @param handle The unique identifier of the view model instance
     * @param requestId The identifier of the list size request
     * @param path The path to the list property
     * @param size The size of the list
     */
    virtual void onViewModelListSizeReceived(
        const rive::ViewModelInstanceHandle handle,
        uint64_t requestId,
        std::string path,
        size_t size) override;

private:
    __weak id<RiveViewModelInstanceListener> _observer;
};
} // namespace

void _ViewModelInstanceListener::onViewModelInstanceError(
    const rive::ViewModelInstanceHandle handle,
    uint64_t requestId,
    std::string error)
{}

void _ViewModelInstanceListener::onViewModelDeleted(
    const rive::ViewModelInstanceHandle handle, uint64_t requestId)
{
    if (_observer)
    {
        [_observer onViewModelDeleted:reinterpret_cast<uint64_t>(handle)
                            requestID:requestId];
    }
}

void _ViewModelInstanceListener::onViewModelDataReceived(
    const rive::ViewModelInstanceHandle handle,
    uint64_t requestId,
    rive::CommandQueue::ViewModelInstanceData data)
{
    if (_observer)
    {
        NSMutableDictionary<NSString*, id>* dataDict =
            [NSMutableDictionary dictionary];
        RiveViewModelInstanceDataType type =
            RiveViewModelInstanceDataTypeFromCpp(data.metaData.type);
        dataDict[@"type"] = @(type);
        dataDict[@"name"] =
            [NSString stringWithUTF8String:data.metaData.name.c_str()];

        switch (data.metaData.type)
        {
            case rive::DataType::boolean:
                dataDict[@"booleanValue"] = @(data.boolValue);
                break;
            case rive::DataType::number:
                dataDict[@"numberValue"] = @(data.numberValue);
                break;
            case rive::DataType::color:
                dataDict[@"colorValue"] = @(data.colorValue);
                break;
            case rive::DataType::string:
            case rive::DataType::enumType:
                dataDict[@"stringValue"] =
                    [NSString stringWithUTF8String:data.stringValue.c_str()];
                break;
            default:
                if (!data.stringValue.empty())
                {
                    dataDict[@"stringValue"] = [NSString
                        stringWithUTF8String:data.stringValue.c_str()];
                }
                break;
        }

        [_observer onViewModelDataReceived:reinterpret_cast<uint64_t>(handle)
                                 requestID:requestId
                                      data:dataDict];
    }
}

void _ViewModelInstanceListener::onViewModelListSizeReceived(
    const rive::ViewModelInstanceHandle handle,
    uint64_t requestId,
    std::string path,
    size_t size)
{
    if (_observer)
    {
        NSString* nsPath = [NSString stringWithUTF8String:path.c_str()];
        [_observer
            onViewModelListSizeReceived:reinterpret_cast<uint64_t>(handle)
                              requestID:requestId
                                   path:nsPath
                                   size:static_cast<NSInteger>(size)];
    }
}

namespace
{
class _RenderImageListener : public rive::CommandQueue::RenderImageListener
{
public:
    _RenderImageListener(id<RiveRenderImageListener> observer)
    {
        _observer = observer;
    }

    virtual void onRenderImageDecoded(const rive::RenderImageHandle handle,
                                      uint64_t requestId) override;

    virtual void onRenderImageError(const rive::RenderImageHandle handle,
                                    uint64_t requestId,
                                    std::string error) override;

    virtual void onRenderImageDeleted(const rive::RenderImageHandle handle,
                                      uint64_t requestId) override;

private:
    __weak id<RiveRenderImageListener> _observer;
};
} // namespace

void _RenderImageListener::onRenderImageDecoded(
    const rive::RenderImageHandle handle, uint64_t requestId)
{
    if (_observer)
    {
        [_observer onRenderImageDecoded:reinterpret_cast<uint64_t>(handle)
                              requestID:requestId];
    }
}

void _RenderImageListener::onRenderImageError(
    const rive::RenderImageHandle handle, uint64_t requestId, std::string error)
{
    if (_observer)
    {
        [_observer
            onRenderImageError:reinterpret_cast<uint64_t>(handle)
                     requestID:requestId
                       message:[NSString stringWithUTF8String:error.c_str()]];
    }
}

void _RenderImageListener::onRenderImageDeleted(
    const rive::RenderImageHandle handle, uint64_t requestId)
{
    if (_observer)
    {
        [_observer onRenderImageDeleted:reinterpret_cast<uint64_t>(handle)
                              requestID:requestId];
    }
}

namespace
{
class _FontListener : public rive::CommandQueue::FontListener
{
public:
    _FontListener(id<RiveFontListener> observer) { _observer = observer; }

    virtual void onFontDecoded(const rive::FontHandle handle,
                               uint64_t requestId) override;

    virtual void onFontError(const rive::FontHandle handle,
                             uint64_t requestId,
                             std::string error) override;

    virtual void onFontDeleted(const rive::FontHandle handle,
                               uint64_t requestId) override;

private:
    __weak id<RiveFontListener> _observer;
};
} // namespace

void _FontListener::onFontDecoded(const rive::FontHandle handle,
                                  uint64_t requestId)
{
    if (_observer)
    {
        [_observer onFontDecoded:reinterpret_cast<uint64_t>(handle)
                       requestID:requestId];
    }
}

void _FontListener::onFontError(const rive::FontHandle handle,
                                uint64_t requestId,
                                std::string error)
{
    if (_observer)
    {
        [_observer onFontError:reinterpret_cast<uint64_t>(handle)
                     requestID:requestId
                       message:[NSString stringWithUTF8String:error.c_str()]];
    }
}

void _FontListener::onFontDeleted(const rive::FontHandle handle,
                                  uint64_t requestId)
{
    if (_observer)
    {
        [_observer onFontDeleted:reinterpret_cast<uint64_t>(handle)
                       requestID:requestId];
    }
}

namespace
{
class _AudioListener : public rive::CommandQueue::AudioSourceListener
{
public:
    _AudioListener(id<RiveAudioListener> observer) { _observer = observer; }

    virtual void onAudioSourceDecoded(const rive::AudioSourceHandle handle,
                                      uint64_t requestId) override;

    virtual void onAudioSourceError(const rive::AudioSourceHandle handle,
                                    uint64_t requestId,
                                    std::string error) override;

    virtual void onAudioSourceDeleted(const rive::AudioSourceHandle handle,
                                      uint64_t requestId) override;

private:
    __weak id<RiveAudioListener> _observer;
};
} // namespace

void _AudioListener::onAudioSourceDecoded(const rive::AudioSourceHandle handle,
                                          uint64_t requestId)
{
    if (_observer)
    {
        [_observer onAudioSourceDecoded:reinterpret_cast<uint64_t>(handle)
                              requestID:requestId];
    }
}

void _AudioListener::onAudioSourceError(const rive::AudioSourceHandle handle,
                                        uint64_t requestId,
                                        std::string error)
{
    if (_observer)
    {
        [_observer
            onAudioSourceError:reinterpret_cast<uint64_t>(handle)
                     requestID:requestId
                       message:[NSString stringWithUTF8String:error.c_str()]];
    }
}

void _AudioListener::onAudioSourceDeleted(const rive::AudioSourceHandle handle,
                                          uint64_t requestId)
{
    if (_observer)
    {
        [_observer onAudioSourceDeleted:reinterpret_cast<uint64_t>(handle)
                              requestID:requestId];
    }
}

/**
 * A concrete implementation of RiveCommandQueueProtocol that bridges with the
 * C++ command queue.
 */
@implementation RiveCommandQueue
{
    /** The underlying C++ command queue that handles Rive operations */
    rive::rcp<rive::CommandQueue> _commandQueue;
    /** Dictionary mapping file handles to their listeners for proper cleanup */
    NSMutableDictionary<NSNumber*, NSValue*>* _fileListeners;
    /** Dictionary mapping artboard handles to their listeners for proper
     * cleanup */
    NSMutableDictionary<NSNumber*, NSValue*>* _artboardListeners;
    /** Dictionary mapping view model instance handles to their listeners for
     * proper cleanup */
    NSMutableDictionary<NSNumber*, NSValue*>* _viewModelInstanceListeners;
    /** Dictionary mapping render image handles to their listeners for proper
     * cleanup */
    NSMutableDictionary<NSNumber*, NSValue*>* _renderImageListeners;
    /** Dictionary mapping font handles to their listeners for proper cleanup */
    NSMutableDictionary<NSNumber*, NSValue*>* _fontListeners;
    /** Dictionary mapping audio handles to their listeners for proper cleanup
     */
    NSMutableDictionary<NSNumber*, NSValue*>* _audioListeners;
    /** The next request ID to use when making a request via command queue */
    uint64_t _nextRequestID;
    /** The display link used for processing messages synchronized with display
     * refresh */
#if RIVE_USE_CVDISPLAYLINK
    CVDisplayLinkRef _processDisplayLink;
#else
    CADisplayLink* _processDisplayLink;
#endif
}

/**
 * Initializes a new RiveCommandQueue instance.
 *
 * This initializer sets up the command queue with a new C++ command queue
 * instance and a file listener for handling file-related events. The
 * initialization must occur on the main thread to ensure proper UI integration.
 *
 * @return An initialized RiveCommandQueue instance
 * @note This method must be called on the main thread
 */
- (instancetype)init
{
    assert([NSThread isMainThread]);
    if (self = [super init])
    {
        _commandQueue = rive::make_rcp<rive::CommandQueue>();
        _fileListeners = [[NSMutableDictionary alloc] init];
        _artboardListeners = [[NSMutableDictionary alloc] init];
        _viewModelInstanceListeners = [[NSMutableDictionary alloc] init];
        _renderImageListeners = [[NSMutableDictionary alloc] init];
        _fontListeners = [[NSMutableDictionary alloc] init];
        _audioListeners = [[NSMutableDictionary alloc] init];
        _nextRequestID = 0;
    }
    return self;
}

/**
 * Cleans up resources when the command queue is deallocated.
 */
- (void)dealloc
{
#if RIVE_USE_CVDISPLAYLINK
    CVDisplayLinkStop(_processDisplayLink);
#else
    [_processDisplayLink invalidate];
#endif

    // Clean up all file listeners
    for (NSValue* listenerValue in _fileListeners.allValues)
    {
        _FileListener* listener =
            static_cast<_FileListener*>(listenerValue.pointerValue);
        delete listener;
    }

    // Clean up all artboard listeners
    for (NSValue* listenerValue in _artboardListeners.allValues)
    {
        _ArtboardListener* listener =
            static_cast<_ArtboardListener*>(listenerValue.pointerValue);
        delete listener;
    }

    // Clean up all view model instance listeners
    for (NSValue* listenerValue in _viewModelInstanceListeners.allValues)
    {
        _ViewModelInstanceListener* listener =
            static_cast<_ViewModelInstanceListener*>(
                listenerValue.pointerValue);
        delete listener;
    }

    // Clean up all render image listeners
    for (NSValue* listenerValue in _renderImageListeners.allValues)
    {
        _RenderImageListener* listener =
            static_cast<_RenderImageListener*>(listenerValue.pointerValue);
        delete listener;
    }

    // Clean up all render image listeners
    for (NSValue* listenerValue in _fontListeners.allValues)
    {
        _FontListener* listener =
            static_cast<_FontListener*>(listenerValue.pointerValue);
        delete listener;
    }

    // Clean up all render image listeners
    for (NSValue* listenerValue in _audioListeners.allValues)
    {
        _AudioListener* listener =
            static_cast<_AudioListener*>(listenerValue.pointerValue);
        delete listener;
    }

    _commandQueue = nullptr;
    _fileListeners = nil;
    _artboardListeners = nil;
    _viewModelInstanceListeners = nil;
    _renderImageListeners = nil;
    _fontListeners = nil;
    _audioListeners = nil;
    _processDisplayLink = nil;
}

- (uint64_t)nextRequestID
{
    assert([NSThread isMainThread]);
    return _nextRequestID++;
}

#pragma mark - Server

/**
 * Disconnects from the command server and stops processing messages.
 *
 * This method signals the command queue to stop processing messages and
 * disconnects from the underlying C++ command queue. It must be called
 * on the main thread to ensure proper cleanup.
 *
 * @note This method must be called on the main thread
 */
- (void)disconnect
{
    assert([NSThread isMainThread]);
    _commandQueue->disconnect();
}

- (void)start
{
    assert([NSThread isMainThread]);

#if RIVE_USE_CVDISPLAYLINK
    // Only start if not already running
    if (_processDisplayLink == nil)
    {
        CVDisplayLinkRef displayLink = nil;
        CVReturn result = CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
        if (result == kCVReturnSuccess && displayLink != nil)
        {
            __weak RiveCommandQueue* weakSelf = self;
            CVDisplayLinkSetOutputHandler(
                displayLink,
                ^CVReturn(CVDisplayLinkRef displayLink,
                          const CVTimeStamp* inNow,
                          const CVTimeStamp* inOutputTime,
                          CVOptionFlags flagsIn,
                          CVOptionFlags* flagsOut) {
                  __strong RiveCommandQueue* strongSelf = weakSelf;
                  if (strongSelf)
                  {
                      dispatch_async(dispatch_get_main_queue(), ^{
                        [strongSelf processMessages];
                      });
                  }
                  return kCVReturnSuccess;
                });
            _processDisplayLink = displayLink;
            CVDisplayLinkStart(_processDisplayLink);
        }
    }
#else
    // Only start if not already running
    if (_processDisplayLink == nil)
    {
        _processDisplayLink =
            [CADisplayLink displayLinkWithTarget:self
                                        selector:@selector(processMessages)];
        [_processDisplayLink addToRunLoop:[NSRunLoop mainRunLoop]
                                  forMode:NSRunLoopCommonModes];
    }
#endif
}

- (void)stop
{
    assert([NSThread isMainThread]);

    // Stop the display link
    if (_processDisplayLink)
    {
#if RIVE_USE_CVDISPLAYLINK
        CVDisplayLinkStop(_processDisplayLink);
#else
        [_processDisplayLink invalidate];
#endif
        _processDisplayLink = nil;
    }
}

#pragma mark - File

/**
 * Loads a Rive file into the command queue.
 *
 * This method loads the provided Rive file data into the command queue and
 * registers the specified observer to receive file-related events. The loading
 * process is asynchronous and the observer will be notified when the file
 * is successfully loaded or if an error occurs.
 *
 * @param data The binary data of the Rive file to load
 * @param observer The observer that will receive file-related event
 * notifications
 * @param requestID A unique identifier for this loading request
 * @return A unique file handle identifier that can be used for subsequent
 * operations
 * @note This method must be called on the main thread
 */
- (uint64_t)loadFile:(nonnull NSData*)data
            observer:(nonnull id<RiveFileListener>)observer
           requestID:(uint64_t)requestID
{
    return [self executeCommandWithReturn:^uint64_t {
      // Create a new listener for this specific observer
      auto listener = std::make_unique<_FileListener>(observer);

      const uint8_t* bytes = static_cast<const uint8_t*>(data.bytes);
      size_t length = data.length;

      auto handle = self->_commandQueue->loadFile(
          std::vector<uint8_t>(bytes, bytes + length),
          listener.get(),
          requestID);

      // Store the listener so it doesn't get deallocated
      uint64_t fileHandleUInt = reinterpret_cast<uint64_t>(handle);
      self->_fileListeners[@(fileHandleUInt)] =
          [NSValue valueWithPointer:listener.release()];

      return fileHandleUInt;
    }];
}

/**
 * Deletes a previously loaded Rive file from the command queue.
 *
 * This method removes the specified file from the command queue and releases
 * all associated resources. Any artboards instantiated from this file will
 * also be deleted.
 *
 * @param file The file handle of the file to delete
 * @note This method must be called on the main thread
 */
- (void)deleteFile:(uint64_t)file requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::FileHandle>(file);
      self->_commandQueue->deleteFile(handle, requestID);
    }];
}

- (void)deleteFileListener:(uint64_t)file
{
    [self executeCommand:^{
      NSValue* listenerValue = self->_fileListeners[@(file)];
      if (listenerValue)
      {
          _FileListener* listener =
              static_cast<_FileListener*>(listenerValue.pointerValue);
          delete listener;
          [self->_fileListeners removeObjectForKey:@(file)];
      }
    }];
}

- (void)requestArtboardNames:(uint64_t)fileHandle requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::FileHandle>(fileHandle);
      self->_commandQueue->requestArtboardNames(handle, requestID);
    }];
}

- (void)requestViewModelNames:(uint64_t)fileHandle requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::FileHandle>(fileHandle);
      self->_commandQueue->requestViewModelNames(handle, requestID);
    }];
}

- (void)requestViewModelEnums:(uint64_t)fileHandle requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::FileHandle>(fileHandle);
      self->_commandQueue->requestViewModelEnums(handle, requestID);
    }];
}

- (void)requestViewModelInstanceNames:(uint64_t)fileHandle
                        viewModelName:(NSString*)viewModelName
                            requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::FileHandle>(fileHandle);
      auto stdName = std::string([viewModelName UTF8String]);
      self->_commandQueue->requestViewModelInstanceNames(
          handle, stdName, requestID);
    }];
}

- (void)requestViewModelPropertyDefinitions:(uint64_t)fileHandle
                              viewModelName:(NSString*)viewModelName
                                  requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::FileHandle>(fileHandle);
      auto stdName = std::string([viewModelName UTF8String]);
      self->_commandQueue->requestViewModelPropertyDefinitions(
          handle, stdName, requestID);
    }];
}

- (uint64_t)createDefaultArtboardFromFile:(uint64_t)fileHandle
                                 observer:(id<RiveArtboardListener>)observer
                                requestID:(uint64_t)requestID
{
    return [self executeCommandWithReturn:^uint64_t {
      // Create a new listener for this specific observer
      auto listener = std::make_unique<_ArtboardListener>(observer);

      auto handle = reinterpret_cast<rive::FileHandle>(fileHandle);
      rive::ArtboardHandle artboardHandle =
          self->_commandQueue->instantiateDefaultArtboard(
              handle, listener.get(), requestID);

      // Store the listener so it doesn't get deallocated
      uint64_t artboardHandleUInt = reinterpret_cast<uint64_t>(artboardHandle);
      self->_artboardListeners[@(artboardHandleUInt)] =
          [NSValue valueWithPointer:listener.release()];

      return artboardHandleUInt;
    }];
}

- (uint64_t)createArtboardNamed:(NSString*)name
                       fromFile:(uint64_t)fileHandle
                       observer:(id<RiveArtboardListener>)observer
                      requestID:(uint64_t)requestID
{
    return [self executeCommandWithReturn:^uint64_t {
      // Create a new listener for this specific observer
      auto listener = std::make_unique<_ArtboardListener>(observer);

      auto handle = reinterpret_cast<rive::FileHandle>(fileHandle);
      auto stdName = std::string([name UTF8String]);
      rive::ArtboardHandle artboardHandle =
          self->_commandQueue->instantiateArtboardNamed(
              handle, stdName, listener.get(), requestID);

      // Store the listener so it doesn't get deallocated
      uint64_t artboardHandleUInt = reinterpret_cast<uint64_t>(artboardHandle);
      self->_artboardListeners[@(artboardHandleUInt)] =
          [NSValue valueWithPointer:listener.release()];

      return artboardHandleUInt;
    }];
}

#pragma mark - Artboard

- (void)deleteArtboard:(uint64_t)artboard requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ArtboardHandle>(artboard);
      self->_commandQueue->deleteArtboard(handle, requestID);
    }];
}

- (void)deleteArtboardListener:(uint64_t)artboard
{
    [self executeCommand:^{
      NSValue* listenerValue = self->_artboardListeners[@(artboard)];
      if (listenerValue)
      {
          _ArtboardListener* listener =
              static_cast<_ArtboardListener*>(listenerValue.pointerValue);
          delete listener;
          [self->_artboardListeners removeObjectForKey:@(artboard)];
      }
    }];
}

- (void)setArtboardSize:(uint64_t)artboardHandle
                  width:(float)width
                 height:(float)height
                  scale:(float)scale
              requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ArtboardHandle>(artboardHandle);
      self->_commandQueue->setArtboardSize(
          handle, width, height, scale, requestID);
    }];
}

- (void)resetArtboardSize:(uint64_t)artboardHandle requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ArtboardHandle>(artboardHandle);
      self->_commandQueue->resetArtboardSize(handle, requestID);
    }];
}

- (void)requestStateMachineNames:(uint64_t)artboardHandle
                       requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ArtboardHandle>(artboardHandle);
      self->_commandQueue->requestStateMachineNames(handle, requestID);
    }];
}

- (void)requestDefaultViewModelInfo:(uint64_t)artboardHandle
                           fromFile:(uint64_t)fileHandle
                          requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto artboard = reinterpret_cast<rive::ArtboardHandle>(artboardHandle);
      auto file = reinterpret_cast<rive::FileHandle>(fileHandle);
      self->_commandQueue->requestDefaultViewModelInfo(
          artboard, file, requestID);
    }];
}

- (uint64_t)createDefaultStateMachineFromArtboard:(uint64_t)artboardHandle
                                        requestID:(uint64_t)requestID
{
    return [self executeCommandWithReturn:^uint64_t {
      auto handle = reinterpret_cast<rive::ArtboardHandle>(artboardHandle);
      rive::StateMachineHandle stateMachineHandle =
          self->_commandQueue->instantiateDefaultStateMachine(
              handle, nullptr, requestID);
      return reinterpret_cast<uint64_t>(stateMachineHandle);
    }];
}

#pragma mark - State Machine

- (uint64_t)createStateMachineNamed:(NSString*)name
                       fromArtboard:(uint64_t)artboardHandle
                          requestID:(uint64_t)requestID
{
    return [self executeCommandWithReturn:^uint64_t {
      auto handle = reinterpret_cast<rive::ArtboardHandle>(artboardHandle);
      auto stdName = std::string([name UTF8String]);
      rive::StateMachineHandle stateMachineHandle =
          self->_commandQueue->instantiateStateMachineNamed(
              handle, stdName, nullptr, requestID);
      return reinterpret_cast<uint64_t>(stateMachineHandle);
    }];
}

- (void)advanceStateMachine:(uint64_t)stateMachineHandle
                         by:(NSTimeInterval)time
                  requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle =
          reinterpret_cast<rive::StateMachineHandle>(stateMachineHandle);
      self->_commandQueue->advanceStateMachine(handle, float(time));
    }];
}

- (void)deleteStateMachine:(uint64_t)stateMachineHandle
                 requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle =
          reinterpret_cast<rive::StateMachineHandle>(stateMachineHandle);
      self->_commandQueue->deleteStateMachine(handle, requestID);
    }];
}

- (void)pointerMove:(uint64_t)stateMachineHandle
           position:(CGPoint)position
       screenBounds:(CGSize)screenBounds
                fit:(RiveConfigurationFit)fit
          alignment:(RiveConfigurationAlignment)alignment
        scaleFactor:(float)scaleFactor
          requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle =
          reinterpret_cast<rive::StateMachineHandle>(stateMachineHandle);
      rive::CommandQueue::PointerEvent cppEvent = RivePointerEventToCpp(
          position, screenBounds, fit, alignment, scaleFactor);
      self->_commandQueue->pointerMove(handle, cppEvent, requestID);
    }];
}

- (void)pointerDown:(uint64_t)stateMachineHandle
           position:(CGPoint)position
       screenBounds:(CGSize)screenBounds
                fit:(RiveConfigurationFit)fit
          alignment:(RiveConfigurationAlignment)alignment
        scaleFactor:(float)scaleFactor
          requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle =
          reinterpret_cast<rive::StateMachineHandle>(stateMachineHandle);
      rive::CommandQueue::PointerEvent cppEvent = RivePointerEventToCpp(
          position, screenBounds, fit, alignment, scaleFactor);
      self->_commandQueue->pointerDown(handle, cppEvent, requestID);
    }];
}

- (void)pointerUp:(uint64_t)stateMachineHandle
         position:(CGPoint)position
     screenBounds:(CGSize)screenBounds
              fit:(RiveConfigurationFit)fit
        alignment:(RiveConfigurationAlignment)alignment
      scaleFactor:(float)scaleFactor
        requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle =
          reinterpret_cast<rive::StateMachineHandle>(stateMachineHandle);
      rive::CommandQueue::PointerEvent cppEvent = RivePointerEventToCpp(
          position, screenBounds, fit, alignment, scaleFactor);
      self->_commandQueue->pointerUp(handle, cppEvent, requestID);
    }];
}

- (void)pointerExit:(uint64_t)stateMachineHandle
           position:(CGPoint)position
       screenBounds:(CGSize)screenBounds
                fit:(RiveConfigurationFit)fit
          alignment:(RiveConfigurationAlignment)alignment
        scaleFactor:(float)scaleFactor
          requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle =
          reinterpret_cast<rive::StateMachineHandle>(stateMachineHandle);
      rive::CommandQueue::PointerEvent cppEvent = RivePointerEventToCpp(
          position, screenBounds, fit, alignment, scaleFactor);
      self->_commandQueue->pointerExit(handle, cppEvent, requestID);
    }];
}

- (void)bindViewModelInstance:(uint64_t)stateMachineHandle
          toViewModelInstance:(uint64_t)viewModelInstanceHandle
                    requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto smHandle =
          reinterpret_cast<rive::StateMachineHandle>(stateMachineHandle);
      auto vmiHandle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      self->_commandQueue->bindViewModelInstance(
          smHandle, vmiHandle, requestID);
    }];
}

#pragma mark - Drawing

- (uint64_t)createDrawKey
{
    return [self executeCommandWithReturn:^uint64_t {
      auto key = self->_commandQueue->createDrawKey();
      return reinterpret_cast<uint64_t>(key);
    }];
}

- (void)draw:(uint64_t)drawKey callback:(void (^)(void*))callback
{
    [self executeCommand:^{
      auto key = reinterpret_cast<rive::DrawKey>(drawKey);
      void (^blockCopy)(void*) = [callback copy];
      self->_commandQueue->draw(
          key,
          [key, blockCopy](rive::DrawKey drawKey,
                           rive::CommandServer* commandServer) {
              blockCopy(static_cast<void*>(commandServer));
          });
    }];
}

#pragma mark - Data Binding

- (uint64_t)
    createBlankViewModelInstanceForArtboard:(uint64_t)artboardHandle
                                   fromFile:(uint64_t)fileHandle
                                   observer:
                                       (nonnull
                                            id<RiveViewModelInstanceListener>)
                                           observer
                                  requestID:(uint64_t)requestID
{
    return [self executeCommandWithReturn:^uint64_t {
      // Create a new listener for this specific observer
      auto listener = std::make_unique<_ViewModelInstanceListener>(observer);

      rive::ViewModelInstanceHandle handle =
          self->_commandQueue->instantiateBlankViewModelInstance(
              reinterpret_cast<rive::FileHandle>(fileHandle),
              reinterpret_cast<rive::ArtboardHandle>(artboardHandle),
              listener.get(),
              requestID);

      // Store the listener so it doesn't get deallocated
      uint64_t vmiHandle = reinterpret_cast<uint64_t>(handle);
      self->_viewModelInstanceListeners[@(vmiHandle)] =
          [NSValue valueWithPointer:listener.release()];

      return vmiHandle;
    }];
}

- (uint64_t)
    createBlankViewModelInstanceNamed:(NSString*)viewModelName
                             fromFile:(uint64_t)fileHandle
                             observer:
                                 (nonnull id<RiveViewModelInstanceListener>)
                                     observer
                            requestID:(uint64_t)requestID
{
    return [self executeCommandWithReturn:^uint64_t {
      // Create a new listener for this specific observer
      auto listener = std::make_unique<_ViewModelInstanceListener>(observer);

      auto stdName = std::string([viewModelName UTF8String]);
      rive::ViewModelInstanceHandle handle =
          self->_commandQueue->instantiateBlankViewModelInstance(
              reinterpret_cast<rive::FileHandle>(fileHandle),
              stdName,
              listener.get(),
              requestID);

      // Store the listener so it doesn't get deallocated
      uint64_t vmiHandle = reinterpret_cast<uint64_t>(handle);
      self->_viewModelInstanceListeners[@(vmiHandle)] =
          [NSValue valueWithPointer:listener.release()];

      return vmiHandle;
    }];
}

- (uint64_t)
    createDefaultViewModelInstanceForArtboard:(uint64_t)artboardHandle
                                     fromFile:(uint64_t)fileHandle
                                     observer:
                                         (nonnull
                                              id<RiveViewModelInstanceListener>)
                                             observer
                                    requestID:(uint64_t)requestID
{
    return [self executeCommandWithReturn:^uint64_t {
      // Create a new listener for this specific observer
      auto listener = std::make_unique<_ViewModelInstanceListener>(observer);

      rive::ViewModelInstanceHandle handle =
          self->_commandQueue->instantiateDefaultViewModelInstance(
              reinterpret_cast<rive::FileHandle>(fileHandle),
              reinterpret_cast<rive::ArtboardHandle>(artboardHandle),
              listener.get(),
              requestID);

      // Store the listener so it doesn't get deallocated
      uint64_t vmiHandle = reinterpret_cast<uint64_t>(handle);
      self->_viewModelInstanceListeners[@(vmiHandle)] =
          [NSValue valueWithPointer:listener.release()];

      return vmiHandle;
    }];
}

- (uint64_t)
    createDefaultViewModelInstanceNamed:(NSString*)viewModelName
                               fromFile:(uint64_t)fileHandle
                               observer:
                                   (nonnull id<RiveViewModelInstanceListener>)
                                       observer
                              requestID:(uint64_t)requestID
{
    return [self executeCommandWithReturn:^uint64_t {
      // Create a new listener for this specific observer
      auto listener = std::make_unique<_ViewModelInstanceListener>(observer);

      auto stdName = std::string([viewModelName UTF8String]);
      rive::ViewModelInstanceHandle handle =
          self->_commandQueue->instantiateDefaultViewModelInstance(
              reinterpret_cast<rive::FileHandle>(fileHandle),
              stdName,
              listener.get(),
              requestID);

      // Store the listener so it doesn't get deallocated
      uint64_t vmiHandle = reinterpret_cast<uint64_t>(handle);
      self->_viewModelInstanceListeners[@(vmiHandle)] =
          [NSValue valueWithPointer:listener.release()];

      return vmiHandle;
    }];
}

- (uint64_t)createViewModelInstanceNamed:(NSString*)instanceName
                             forArtboard:(uint64_t)artboardHandle
                                fromFile:(uint64_t)fileHandle
                                observer:
                                    (nonnull id<RiveViewModelInstanceListener>)
                                        observer
                               requestID:(uint64_t)requestID
{
    return [self executeCommandWithReturn:^uint64_t {
      auto listener = std::make_unique<_ViewModelInstanceListener>(observer);

      auto stdInstanceName = std::string([instanceName UTF8String]);
      rive::ViewModelInstanceHandle handle =
          self->_commandQueue->instantiateViewModelInstanceNamed(
              reinterpret_cast<rive::FileHandle>(fileHandle),
              reinterpret_cast<rive::ArtboardHandle>(artboardHandle),
              stdInstanceName,
              listener.get(),
              requestID);

      uint64_t vmiHandle = reinterpret_cast<uint64_t>(handle);
      self->_viewModelInstanceListeners[@(vmiHandle)] =
          [NSValue valueWithPointer:listener.release()];

      return vmiHandle;
    }];
}

- (uint64_t)createViewModelInstanceNamed:(NSString*)instanceName
                           viewModelName:(NSString*)viewModelName
                                fromFile:(uint64_t)fileHandle
                                observer:
                                    (nonnull id<RiveViewModelInstanceListener>)
                                        observer
                               requestID:(uint64_t)requestID
{
    return [self executeCommandWithReturn:^uint64_t {
      auto listener = std::make_unique<_ViewModelInstanceListener>(observer);

      auto stdViewModelName = std::string([viewModelName UTF8String]);
      auto stdInstanceName = std::string([instanceName UTF8String]);
      rive::ViewModelInstanceHandle handle =
          self->_commandQueue->instantiateViewModelInstanceNamed(
              reinterpret_cast<rive::FileHandle>(fileHandle),
              stdViewModelName,
              stdInstanceName,
              listener.get(),
              requestID);

      uint64_t vmiHandle = reinterpret_cast<uint64_t>(handle);
      self->_viewModelInstanceListeners[@(vmiHandle)] =
          [NSValue valueWithPointer:listener.release()];

      return vmiHandle;
    }];
}

- (void)requestViewModelInstanceString:(uint64_t)viewModelInstanceHandle
                                  path:(NSString*)path
                             requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      self->_commandQueue->requestViewModelInstanceString(
          handle, stdPath, requestID);
    }];
}

- (void)requestViewModelInstanceNumber:(uint64_t)viewModelInstanceHandle
                                  path:(NSString*)path
                             requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      self->_commandQueue->requestViewModelInstanceNumber(
          handle, stdPath, requestID);
    }];
}

- (void)requestViewModelInstanceBool:(uint64_t)viewModelInstanceHandle
                                path:(NSString*)path
                           requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      self->_commandQueue->requestViewModelInstanceBool(
          handle, stdPath, requestID);
    }];
}

- (void)requestViewModelInstanceColor:(uint64_t)viewModelInstanceHandle
                                 path:(NSString*)path
                            requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      self->_commandQueue->requestViewModelInstanceColor(
          handle, stdPath, requestID);
    }];
}

- (void)requestViewModelInstanceEnum:(uint64_t)viewModelInstanceHandle
                                path:(NSString*)path
                           requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      self->_commandQueue->requestViewModelInstanceEnum(
          handle, stdPath, requestID);
    }];
}

- (void)requestViewModelInstanceListSize:(uint64_t)viewModelInstanceHandle
                                    path:(NSString*)path
                               requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      self->_commandQueue->requestViewModelInstanceListSize(
          handle, stdPath, requestID);
    }];
}

- (void)setViewModelInstanceString:(uint64_t)viewModelInstanceHandle
                              path:(NSString*)path
                             value:(NSString*)value
                         requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      auto stdValue = std::string([value UTF8String]);
      self->_commandQueue->setViewModelInstanceString(
          handle, stdPath, stdValue, requestID);
    }];
}

- (void)setViewModelInstanceNumber:(uint64_t)viewModelInstanceHandle
                              path:(NSString*)path
                             value:(float)value
                         requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      self->_commandQueue->setViewModelInstanceNumber(
          handle, stdPath, value, requestID);
    }];
}

- (void)setViewModelInstanceBool:(uint64_t)viewModelInstanceHandle
                            path:(NSString*)path
                           value:(BOOL)value
                       requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      self->_commandQueue->setViewModelInstanceBool(
          handle, stdPath, value, requestID);
    }];
}

- (void)setViewModelInstanceColor:(uint64_t)viewModelInstanceHandle
                             path:(NSString*)path
                            value:(uint32_t)value
                        requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      rive::ColorInt colorValue = static_cast<rive::ColorInt>(value);
      self->_commandQueue->setViewModelInstanceColor(
          handle, stdPath, colorValue, requestID);
    }];
}

- (void)setViewModelInstanceEnum:(uint64_t)viewModelInstanceHandle
                            path:(NSString*)path
                           value:(NSString*)value
                       requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      auto stdValue = std::string([value UTF8String]);
      self->_commandQueue->setViewModelInstanceEnum(
          handle, stdPath, stdValue, requestID);
    }];
}

- (void)setViewModelInstanceImage:(uint64_t)viewModelInstanceHandle
                             path:(NSString*)path
                            value:(uint64_t)value
                        requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      auto renderImageHandle = reinterpret_cast<rive::RenderImageHandle>(value);
      self->_commandQueue->setViewModelInstanceImage(
          handle, stdPath, renderImageHandle, requestID);
    }];
}

- (void)setViewModelInstanceArtboard:(uint64_t)viewModelInstanceHandle
                                path:(NSString*)path
                               value:(uint64_t)value
                           requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      auto artboardHandle = reinterpret_cast<rive::ArtboardHandle>(value);
      self->_commandQueue->setViewModelInstanceArtboard(
          handle, stdPath, artboardHandle, requestID);
    }];
}

- (void)setViewModelInstanceNestedViewModel:(uint64_t)viewModelInstanceHandle
                                       path:(NSString*)path
                                      value:(uint64_t)value
                                  requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      auto valueHandle = reinterpret_cast<rive::ViewModelInstanceHandle>(value);
      self->_commandQueue->setViewModelInstanceNestedViewModel(
          handle, stdPath, valueHandle, requestID);
    }];
}

- (void)fireViewModelTrigger:(uint64_t)viewModelInstanceHandle
                        path:(NSString*)path
                   requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      self->_commandQueue->fireViewModelTrigger(handle, stdPath, requestID);
    }];
}

- (void)deleteViewModelInstance:(uint64_t)viewModelInstance
                      requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle =
          reinterpret_cast<rive::ViewModelInstanceHandle>(viewModelInstance);
      self->_commandQueue->deleteViewModelInstance(handle, requestID);
    }];
}

- (void)deleteViewModelInstanceListener:(uint64_t)viewModelInstance
{
    [self executeCommand:^{
      NSValue* listenerValue =
          self->_viewModelInstanceListeners[@(viewModelInstance)];
      if (listenerValue)
      {
          _ViewModelInstanceListener* listener =
              static_cast<_ViewModelInstanceListener*>(
                  listenerValue.pointerValue);
          delete listener;
          [self->_viewModelInstanceListeners
              removeObjectForKey:@(viewModelInstance)];
      }
    }];
}

- (void)subscribeToViewModelProperty:(uint64_t)viewModelInstance
                                path:(NSString*)path
                                type:(RiveViewModelInstanceDataType)type
                           requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle =
          reinterpret_cast<rive::ViewModelInstanceHandle>(viewModelInstance);
      auto stdPath = std::string([path UTF8String]);
      self->_commandQueue->subscribeToViewModelProperty(
          handle,
          stdPath,
          RiveViewModelInstanceDataTypeToCppType(type),
          requestID);
    }];
}

- (void)unsubscribeToViewModelProperty:(uint64_t)viewModelInstance
                                  path:(NSString*)path
                                  type:(RiveViewModelInstanceDataType)type
                             requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle =
          reinterpret_cast<rive::ViewModelInstanceHandle>(viewModelInstance);
      auto stdPath = std::string([path UTF8String]);
      self->_commandQueue->unsubscribeToViewModelProperty(
          handle,
          stdPath,
          RiveViewModelInstanceDataTypeToCppType(type),
          requestID);
    }];
}

#pragma mark - RenderImage

- (uint64_t)decodeImage:(NSData*)data
               listener:(id<RiveRenderImageListener>)listener
              requestID:(uint64_t)requestID
{
    return [self executeCommandWithReturn:^uint64_t {
      auto renderImageListener =
          std::make_unique<_RenderImageListener>(listener);

      const uint8_t* bytes = static_cast<const uint8_t*>(data.bytes);
      size_t length = data.length;

      auto handle = self->_commandQueue->decodeImage(
          std::vector<uint8_t>(bytes, bytes + length),
          renderImageListener.get(),
          requestID);

      uint64_t renderImageHandleUInt = reinterpret_cast<uint64_t>(handle);
      self->_renderImageListeners[@(renderImageHandleUInt)] =
          [NSValue valueWithPointer:renderImageListener.release()];

      return renderImageHandleUInt;
    }];
}

- (void)deleteImage:(uint64_t)renderImage requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::RenderImageHandle>(renderImage);
      self->_commandQueue->deleteImage(handle, requestID);
    }];
}

- (void)deleteImageListener:(uint64_t)renderImage
{
    [self executeCommand:^{
      NSValue* listenerValue = self->_renderImageListeners[@(renderImage)];
      if (listenerValue)
      {
          _RenderImageListener* listener =
              static_cast<_RenderImageListener*>(listenerValue.pointerValue);
          delete listener;
          [self->_renderImageListeners removeObjectForKey:@(renderImage)];
      }
    }];
}

- (void)addGlobalImageAsset:(NSString*)name
                imageHandle:(uint64_t)imageHandle
                  requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto stdName = std::string([name UTF8String]);
      auto handle = reinterpret_cast<rive::RenderImageHandle>(imageHandle);
      self->_commandQueue->addGlobalImageAsset(stdName, handle, requestID);
    }];
}

- (void)removeGlobalImageAsset:(NSString*)name requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto stdName = std::string([name UTF8String]);
      self->_commandQueue->removeGlobalImageAsset(stdName, requestID);
    }];
}

#pragma mark - Font

- (uint64_t)decodeFont:(NSData*)data
              listener:(id<RiveFontListener>)listener
             requestID:(uint64_t)requestID
{
    return [self executeCommandWithReturn:^uint64_t {
      auto fontListener = std::make_unique<_FontListener>(listener);

      const uint8_t* bytes = static_cast<const uint8_t*>(data.bytes);
      size_t length = data.length;

      auto handle = self->_commandQueue->decodeFont(
          std::vector<uint8_t>(bytes, bytes + length),
          fontListener.get(),
          requestID);

      uint64_t fontHandleUInt = reinterpret_cast<uint64_t>(handle);
      self->_fontListeners[@(fontHandleUInt)] =
          [NSValue valueWithPointer:fontListener.release()];

      return fontHandleUInt;
    }];
}

- (void)deleteFont:(uint64_t)font requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::FontHandle>(font);
      self->_commandQueue->deleteFont(handle, requestID);
    }];
}

- (void)deleteFontListener:(uint64_t)font
{
    [self executeCommand:^{
      NSValue* listenerValue = self->_fontListeners[@(font)];
      if (listenerValue)
      {
          _FontListener* listener =
              static_cast<_FontListener*>(listenerValue.pointerValue);
          delete listener;
          [self->_fontListeners removeObjectForKey:@(font)];
      }
    }];
}

- (void)addGlobalFontAsset:(NSString*)name
                fontHandle:(uint64_t)fontHandle
                 requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto stdName = std::string([name UTF8String]);
      auto handle = reinterpret_cast<rive::FontHandle>(fontHandle);
      self->_commandQueue->addGlobalFontAsset(stdName, handle, requestID);
    }];
}

- (void)removeGlobalFontAsset:(NSString*)name requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto stdName = std::string([name UTF8String]);
      self->_commandQueue->removeGlobalFontAsset(stdName, requestID);
    }];
}

#pragma mark - Audio

- (uint64_t)decodeAudio:(NSData*)data
               listener:(id<RiveAudioListener>)listener
              requestID:(uint64_t)requestID
{
    return [self executeCommandWithReturn:^uint64_t {
      auto audioListener = std::make_unique<_AudioListener>(listener);

      const uint8_t* bytes = static_cast<const uint8_t*>(data.bytes);
      size_t length = data.length;

      auto handle = self->_commandQueue->decodeAudio(
          std::vector<uint8_t>(bytes, bytes + length),
          audioListener.get(),
          requestID);

      uint64_t audioHandleUInt = reinterpret_cast<uint64_t>(handle);
      self->_audioListeners[@(audioHandleUInt)] =
          [NSValue valueWithPointer:audioListener.release()];

      return audioHandleUInt;
    }];
}

- (void)deleteAudio:(uint64_t)audio requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::AudioSourceHandle>(audio);
      self->_commandQueue->deleteAudio(handle, requestID);
    }];
}

- (void)deleteAudioListener:(uint64_t)audio
{
    [self executeCommand:^{
      NSValue* listenerValue = self->_audioListeners[@(audio)];
      if (listenerValue)
      {
          _AudioListener* listener =
              static_cast<_AudioListener*>(listenerValue.pointerValue);
          delete listener;
          [self->_audioListeners removeObjectForKey:@(audio)];
      }
    }];
}

- (void)addGlobalAudioAsset:(NSString*)name
                audioHandle:(uint64_t)audioHandle
                  requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto stdName = std::string([name UTF8String]);
      auto handle = reinterpret_cast<rive::AudioSourceHandle>(audioHandle);
      self->_commandQueue->addGlobalAudioAsset(stdName, handle, requestID);
    }];
}

- (void)removeGlobalAudioAsset:(NSString*)name requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto stdName = std::string([name UTF8String]);
      self->_commandQueue->removeGlobalAudioAsset(stdName, requestID);
    }];
}

- (uint64_t)
    referenceNestedViewModelInstance:(uint64_t)viewModelInstanceHandle
                                path:(NSString*)path
                            observer:(id<RiveViewModelInstanceListener>)observer
                           requestID:(uint64_t)requestID
{
    return [self executeCommandWithReturn:^uint64_t {
      // Create a new listener for this specific observer
      auto listener = std::make_unique<_ViewModelInstanceListener>(observer);

      auto stdPath = std::string([path UTF8String]);
      auto vmiHandle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      rive::ViewModelInstanceHandle handle =
          self->_commandQueue->referenceNestedViewModelInstance(
              vmiHandle, stdPath, listener.get(), requestID);

      // Store the listener so it doesn't get deallocated
      uint64_t returnHandle = reinterpret_cast<uint64_t>(handle);
      self->_viewModelInstanceListeners[@(returnHandle)] =
          [NSValue valueWithPointer:listener.release()];

      return returnHandle;
    }];
}

- (uint64_t)
    referenceListViewModelInstance:(uint64_t)viewModelInstanceHandle
                              path:(NSString*)path
                             index:(int)index
                          observer:(id<RiveViewModelInstanceListener>)observer
                         requestID:(uint64_t)requestID
{
    return [self executeCommandWithReturn:^uint64_t {
      auto listener = std::make_unique<_ViewModelInstanceListener>(observer);

      auto stdPath = std::string([path UTF8String]);
      auto vmiHandle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      rive::ViewModelInstanceHandle handle =
          self->_commandQueue->referenceListViewModelInstance(
              vmiHandle, stdPath, index, listener.get(), requestID);

      uint64_t returnHandle = reinterpret_cast<uint64_t>(handle);
      self->_viewModelInstanceListeners[@(returnHandle)] =
          [NSValue valueWithPointer:listener.release()];

      return returnHandle;
    }];
}

- (void)appendViewModelInstanceListViewModel:(uint64_t)viewModelInstanceHandle
                                        path:(NSString*)path
                                       value:(uint64_t)value
                                   requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      auto valueHandle = reinterpret_cast<rive::ViewModelInstanceHandle>(value);
      self->_commandQueue->appendViewModelInstanceListViewModel(
          handle, stdPath, valueHandle, requestID);
    }];
}

- (void)insertViewModelInstanceListViewModel:(uint64_t)viewModelInstanceHandle
                                        path:(NSString*)path
                                       value:(uint64_t)value
                                       index:(int)index
                                   requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      auto valueHandle = reinterpret_cast<rive::ViewModelInstanceHandle>(value);
      self->_commandQueue->insertViewModelInstanceListViewModel(
          handle, stdPath, valueHandle, index, requestID);
    }];
}

- (void)removeViewModelInstanceListViewModelAtIndex:
            (uint64_t)viewModelInstanceHandle
                                               path:(NSString*)path
                                              index:(int)index
                                              value:(uint64_t)value
                                          requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      auto valueHandle = reinterpret_cast<rive::ViewModelInstanceHandle>(value);
      self->_commandQueue->removeViewModelInstanceListViewModel(
          handle, stdPath, index, valueHandle, requestID);
    }];
}

- (void)removeViewModelInstanceListViewModelByValue:
            (uint64_t)viewModelInstanceHandle
                                               path:(NSString*)path
                                              value:(uint64_t)value
                                          requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      auto valueHandle = reinterpret_cast<rive::ViewModelInstanceHandle>(value);
      self->_commandQueue->removeViewModelInstanceListViewModel(
          handle, stdPath, valueHandle, requestID);
    }];
}

- (void)swapViewModelInstanceListValues:(uint64_t)viewModelInstanceHandle
                                   path:(NSString*)path
                                atIndex:(int)atIndex
                              withIndex:(int)withIndex
                              requestID:(uint64_t)requestID
{
    [self executeCommand:^{
      auto handle = reinterpret_cast<rive::ViewModelInstanceHandle>(
          viewModelInstanceHandle);
      auto stdPath = std::string([path UTF8String]);
      self->_commandQueue->swapViewModelInstanceListValues(
          handle, stdPath, atIndex, withIndex, requestID);
    }];
}

#pragma mark - Private

/**
 * Returns the underlying C++ command queue instance.
 *
 * This method provides access to the C++ command queue for internal operations
 * and integration with other C++ components.
 *
 * @return A shared pointer to the C++ command queue
 */
- (rive::rcp<rive::CommandQueue>)commandQueue
{
    return _commandQueue;
}

/**
 * Executes a command block with proper setup and teardown.
 *
 * This helper method ensures that all commands follow the same pattern:
 * - Assert main thread execution
 * - Start processing
 * - Execute the command block
 *
 * @param commandBlock The block containing the command logic to execute
 */
- (void)executeCommand:(void (^)(void))commandBlock
{
    assert([NSThread isMainThread]);

    commandBlock();
}

/**
 * Executes a command block with proper setup and teardown, returning a value.
 *
 * This helper method ensures that all commands follow the same pattern:
 * - Assert main thread execution
 * - Start processing
 * - Execute the command block
 * - Return the result
 *
 * @param commandBlock The block containing the command logic to execute
 * @return The result from the command block
 */
- (uint64_t)executeCommandWithReturn:(uint64_t (^)(void))commandBlock
{
    assert([NSThread isMainThread]);

    uint64_t result = commandBlock();

    return result;
}

/**
 * Processes pending messages in the command queue.
 *
 * This method is called periodically to process any pending commands in the
 * C++ command queue. It ensures that file loading, artboard instantiation,
 * and other operations are completed in a timely manner.
 *
 * The method dispatches the processing to the main queue to ensure thread
 * safety and proper integration with the UI system.
 */
- (void)processMessages
{
    // Process messages directly since we're already on the main queue
    _commandQueue->processMessages();
}

@end

NS_ASSUME_NONNULL_END
