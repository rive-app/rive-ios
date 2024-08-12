/*
 * Copyright 2023 Rive
 */

#import <PlatformCGImage.h>
#include "rive/core/type_conversions.hpp"
#include "utils/auto_cf.hpp"

#include <TargetConditionals.h>

#if TARGET_OS_IPHONE
#include <CoreGraphics/CoreGraphics.h>
#include <ImageIO/ImageIO.h>
#elif TARGET_OS_MAC
#include <ApplicationServices/ApplicationServices.h>
#endif

bool PlatformCGImageDecode(const uint8_t* encodedBytes,
                           size_t encodedSizeInBytes,
                           PlatformCGImage* platformImage)
{
    AutoCF data = CFDataCreate(kCFAllocatorDefault, encodedBytes, encodedSizeInBytes);
    if (!data)
    {
        return false;
    }

    AutoCF source = CGImageSourceCreateWithData(data, nullptr);
    if (!source)
    {
        return false;
    }

    AutoCF image = CGImageSourceCreateImageAtIndex(source, 0, nullptr);
    if (!image)
    {
        return false;
    }

    bool isOpaque = false;
    switch (CGImageGetAlphaInfo(image.get()))
    {
        case kCGImageAlphaNone:
        case kCGImageAlphaNoneSkipFirst:
        case kCGImageAlphaNoneSkipLast:
            isOpaque = true;
            break;
        default:
            break;
    }

    CFDataRef dataRef = CGDataProviderCopyData(CGImageGetDataProvider(image));
    const UInt8* pixelData = CFDataGetBytePtr(dataRef);
    const size_t width = CGImageGetWidth(image);
    const size_t height = CGImageGetHeight(image);
    const size_t rowBytes = width * 4; // 4 bytes per pixel
    const size_t size = rowBytes * height;

    platformImage->width = rive::castTo<uint32_t>(width);
    platformImage->height = rive::castTo<uint32_t>(height);
    platformImage->opaque = isOpaque;
    platformImage->pixels = std::vector<uint8_t>(pixelData, pixelData + size);
    CFRelease(dataRef);
    return true;
}
