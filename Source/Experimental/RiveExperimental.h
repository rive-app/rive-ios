//
//  RiveUI.h
//  RiveRuntime
//
//  Created by David Skuza on 9/8/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#ifndef RiveUI_h
#define RiveUI_h

#import <CoreGraphics/CoreGraphics.h>
#import <MetalKit/MetalKit.h>

@protocol MTLDevice;

#ifdef __cplusplus
extern "C"
{
#endif

    /**
     * Returns the maximum 2D texture size supported by the current Metal
     * device.
     *
     * This function queries the Metal device's GPU family to determine the
     * maximum texture dimensions. The returned size can be used to validate
     * texture dimensions before creating Metal textures for rendering.
     *
     * @return The maximum texture size as a CGSize (width and height are equal)
     * @note The size is determined based on the GPU family. Most modern Apple
     *       GPUs support 16384x16384, while older GPUs support 8192x8192.
     */
    extern CGSize CGSizeMaximum2DTextureSize(id<MTLDevice>);

    /**
     * Returns the pixel format used for Rive color textures.
     *
     * This function returns the Metal pixel format that should be used when
     * creating textures for Rive rendering. The format is consistent across
     * all Rive rendering operations.
     *
     * @return The Metal pixel format (MTLPixelFormatBGRA8Unorm)
     * @note This format uses 8 bits per channel in BGRA order with normalized
     *       values (0.0 to 1.0). Use this format when creating Metal textures
     *       for the Renderer's drawConfiguration:toTexture: method.
     */
    extern MTLPixelFormat MTLRiveColorPixelFormat(void);

#ifdef __cplusplus
}
#endif

// Import all the header files (not implementation files) to make them available
#import <RiveRuntime/RiveEnums.h>
#import <RiveRuntime/RiveCommandQueue.h>
#import <RiveRuntime/RiveCommandServer.h>
#import <RiveRuntime/RiveFileListener.h>
#import <RiveRuntime/RiveArtboardListener.h>
#import <RiveRuntime/RiveRenderImageListener.h>
#import <RiveRuntime/RiveFontListener.h>
#import <RiveRuntime/RiveAudioListener.h>
#import <RiveRuntime/Renderer.h>
#import <RiveRuntime/RiveViewModelInstanceListener.h>
#import <RiveRuntime/RiveViewModelInstanceData.h>
#import <RiveRuntime/RiveRenderContext.h>

#endif /* RiveUI_h */
