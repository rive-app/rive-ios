//
//  RiveUI.m
//  RiveRuntime
//
//  Created by David Skuza on 9/10/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import <RiveRuntime/RiveExperimental.h>
#import <Metal/Metal.h>
#import <CoreGraphics/CoreGraphics.h>

id<MTLDevice> MTLRiveDevice(void)
{
    static dispatch_once_t onceToken;
    static id<MTLDevice> device;
    dispatch_once(&onceToken, ^{
      device = MTLCreateSystemDefaultDevice();
    });
    return device;
}

CGSize CGSizeMaximum2DTextureSize(void)
{
    id<MTLDevice> device = MTLRiveDevice();
    CGSize size = CGSizeZero;
    // Fall back in reverse order of the table in the above linked document.
    // See Page 1 for additional details on GPUs in each family.
    if ([device supportsFamily:MTLGPUFamilyMac2])
    {
        size = CGSizeMake(16384, 16384);
    }
#if !TARGET_OS_VISION && !TARGET_OS_TV
    else if ([device supportsFamily:MTLGPUFamilyApple9])
    {
        size = CGSizeMake(16384, 16384);
    }
#endif
    else if ([device supportsFamily:MTLGPUFamilyApple8])
    {
        size = CGSizeMake(16384, 16384);
    }
    else if ([device supportsFamily:MTLGPUFamilyApple7])
    {
        size = CGSizeMake(16384, 16384);
    }
    else if ([device supportsFamily:MTLGPUFamilyApple6])
    {
        size = CGSizeMake(16384, 16384);
    }
    else if ([device supportsFamily:MTLGPUFamilyApple5])
    {
        size = CGSizeMake(16384, 16384);
    }
    else if ([device supportsFamily:MTLGPUFamilyApple4])
    {
        size = CGSizeMake(16384, 16384);
    }
    else if ([device supportsFamily:MTLGPUFamilyApple3])
    {
        size = CGSizeMake(16384, 16384);
    }
    else if ([device supportsFamily:MTLGPUFamilyApple2])
    {
        size = CGSizeMake(8192, 8192);
    }
    else
    {
        // Anything not noted in the linked table above, assume the lowest
        // Wayback Machine shows that MTLGPUFamilyApple1 was 8192x8192
        size = CGSizeMake(8192, 8192);
    }
    return size;
}

MTLPixelFormat MTLRiveColorPixelFormat(void)
{
    return MTLPixelFormatBGRA8Unorm;
}
