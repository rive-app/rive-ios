/*
 * Copyright 2023 Rive
 */

#pragma once

#ifndef render_context_h
#define render_context_h

#import <MetalKit/MetalKit.h>
#import <Metal/Metal.h>

namespace rive
{
class Factory;
class Renderer;
}; // namespace rive

NS_ASSUME_NONNULL_BEGIN

@protocol RiveMetalDrawableView;

/// RenderContext knows how to set up a backend-specific render context (e.g.,
/// CG, Rive, ...), and provides a rive::Factory and rive::Renderer for it.
@interface RenderContext : NSObject
@property(strong) id<MTLDevice> metalDevice;
@property(strong) id<MTLCommandQueue> metalQueue;
@property MTLPixelFormat depthStencilPixelFormat;
@property BOOL framebufferOnly;
- (rive::Factory*)factory;
- (rive::Renderer*)beginFrame:(id<RiveMetalDrawableView>)view;
- (void)endFrame:(id<RiveMetalDrawableView>)view
    withCompletion:(_Nullable MTLCommandBufferHandler)completionHandler;
- (BOOL)canDrawInRect:(CGRect)rect
         drawableSize:(CGSize)size
                scale:(CGFloat)scale;
@end

NS_ASSUME_NONNULL_END

#endif
