/*
 * Copyright 2023 Rive
 */

#import <PlatformCGImage.h>
#include "rive/core/type_conversions.hpp"

#if defined(RIVE_BUILD_FOR_OSX)
#include <ApplicationServices/ApplicationServices.h>
#elif defined(RIVE_BUILD_FOR_IOS)
#include <CoreGraphics/CoreGraphics.h>
#include <ImageIO/ImageIO.h>
#endif

// Helper that remembers to call CFRelease when an object goes out of scope.
template <typename T> class AutoCF
{
    T m_Obj;

public:
    AutoCF(T obj) : m_Obj(obj) {}
    ~AutoCF()
    {
        if (m_Obj)
            CFRelease(m_Obj);
    }

    operator T() const { return m_Obj; }
    operator bool() const { return m_Obj != nullptr; }
    T get() const { return m_Obj; }
};

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

    // Now create a drawing context to produce RGBA pixels

    const size_t bitsPerComponent = 8;
    CGBitmapInfo cgInfo = kCGBitmapByteOrder32Big; // rgba
    if (isOpaque)
    {
        cgInfo |= kCGImageAlphaNoneSkipLast;
    }
    else
    {
        cgInfo |= kCGImageAlphaPremultipliedLast; // premul
    }
    const size_t width = CGImageGetWidth(image);
    const size_t height = CGImageGetHeight(image);
    const size_t rowBytes = width * 4; // 4 bytes per pixel
    const size_t size = rowBytes * height;

    std::vector<uint8_t> pixels;
    pixels.resize(size);

    AutoCF cs = CGColorSpaceCreateDeviceRGB();
    AutoCF cg =
        CGBitmapContextCreate(pixels.data(), width, height, bitsPerComponent, rowBytes, cs, cgInfo);
    if (!cg)
    {
        return false;
    }

    CGContextSetBlendMode(cg, kCGBlendModeCopy);
    CGContextDrawImage(cg, CGRectMake(0, 0, width, height), image);

    platformImage->width = rive::castTo<uint32_t>(width);
    platformImage->height = rive::castTo<uint32_t>(height);
    platformImage->opaque = isOpaque;
    platformImage->pixels = std::move(pixels);
    return true;
}
