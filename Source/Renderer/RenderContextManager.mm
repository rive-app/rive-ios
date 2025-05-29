/*
 * Copyright 2023 Rive
 */

#import <RenderContextManager.h>
#import <RenderContext.h>
#import <RiveMetalDrawableView.h>
#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <RiveFactory.h>
#import <rive_renderer_view.hh>

#include "utils/auto_cf.hpp"
#include "cg_factory.hpp"
#include "cg_renderer.hpp"
#include "rive/renderer/gpu.hpp"

// Values taken from Page 7 of
// https://developer.apple.com/metal/Metal-Feature-Set-Tables.pdf
// Last updated 10/2024
static CGSize Maximum2DTextureSizeFromDevice(id<MTLDevice> device)
{
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

@interface RenderContext (Private)
@property(nonatomic, assign) CGSize maximum2DTextureSize;
@end

@implementation RenderContext

- (rive::Factory*)factory
{
    return nil;
}

- (rive::Renderer*)beginFrame:(id<RiveMetalDrawableView>)view
{
    return nil;
}

- (void)endFrame:(id<RiveMetalDrawableView>)view
    withCompletion:(_Nullable MTLCommandBufferHandler)completionHandler;
{}

- (BOOL)canDrawInRect:(CGRect)rect
         drawableSize:(CGSize)drawableSize
                scale:(CGFloat)scale;
{
    // If for some reason the view is not within a window (screen),
    // scale will be -1
    if (scale == -1)
    {
        return NO;
    }

    BOOL (^CGSizeWithinRange)(CGSize, CGSize) =
        ^BOOL(CGSize size, CGSize maxSize) {
          BOOL isWidthValid = size.width > 0 && size.width <= maxSize.width;
          BOOL isHeightValid = size.height > 0 && size.height <= maxSize.height;
          return isWidthValid && isHeightValid;
        };

    // Convert points to pixels, as Metal works in pixels
    CGFloat pixelWidth = CGRectGetWidth(rect) * scale;
    CGFloat pixelHeight = CGRectGetHeight(rect) * scale;
    CGSize pixelSize = CGSizeMake(pixelWidth, pixelHeight);

    return CGSizeWithinRange(pixelSize, self.maximum2DTextureSize) &&
           CGSizeWithinRange(drawableSize, self.maximum2DTextureSize);
}

- (void)setMaximum2DTextureSize:(CGSize)maximum2DTextureSize
{}

- (CGSize)maximum2DTextureSize
{
    return CGSizeZero;
}

@end

#include "rive/renderer/metal/render_context_metal_impl.h"
#include "rive/renderer/rive_render_image.hpp"
#include "rive/renderer/rive_renderer.hpp"

@interface RiveRendererContext : RenderContext
@end

@implementation RiveRendererContext
{
    std::unique_ptr<rive::gpu::RenderContext> renderContext;
    std::unique_ptr<rive::RiveRenderer> _renderer;
    rive::rcp<rive::gpu::RenderTargetMetal> _renderTarget;
    CGSize _maximum2DTextureSize;
}

static std::unique_ptr<rive::gpu::RenderContext> make_pls_context_native(
    id<MTLDevice> gpu)
{
    return rive::gpu::RenderContextMetalImpl::MakeContext(
        gpu, rive::gpu::RenderContextMetalImpl::ContextOptions());
}

- (instancetype)init
{
    // Make a single static RenderContext, since it is also the factory and any
    // objects it creates may outlive this 'RiveContext' instance.
    static id<MTLDevice> s_plsGPU = MTLCreateSystemDefaultDevice();
    renderContext = make_pls_context_native(s_plsGPU);

    self = [super init];
    self.metalDevice = s_plsGPU;
    self.metalQueue = [s_plsGPU newCommandQueue];
    self.depthStencilPixelFormat = MTLPixelFormatInvalid;
    self.framebufferOnly = YES;
    _renderer = std::make_unique<rive::RiveRenderer>(renderContext.get());
    self.maximum2DTextureSize =
        Maximum2DTextureSizeFromDevice(self.metalDevice);
    return self;
}

- (void)dealloc
{
    // Once nobody is referencing a RiveContext anymore, release the global
    // RenderContext's GPU resource.
    renderContext->releaseResources();
}

- (rive::Factory*)factory
{
    return renderContext.get();
}

- (rive::Renderer*)beginFrame:(id<RiveMetalDrawableView>)view
{
    id<CAMetalDrawable> surface = view.currentDrawable;
    if (!surface.texture)
    {
        NSLog(@"error: no surface texture on MTKView");
        return nullptr;
    }

    switch (view.colorPixelFormat)
    {
        case MTLPixelFormatBGRA8Unorm:
        case MTLPixelFormatRGBA8Unorm:
            break;
        default:
            NSLog(@"error: unsupported colorPixelFormat on MTKView");
            return nullptr;
    }

    if (_renderTarget == nullptr ||
        _renderTarget->width() != view.drawableSize.width ||
        _renderTarget->height() != view.drawableSize.height)
    {
        _renderTarget =
            renderContext->static_impl_cast<rive::gpu::RenderContextMetalImpl>()
                ->makeRenderTarget(view.colorPixelFormat,
                                   view.drawableSize.width,
                                   view.drawableSize.height);
    }
    _renderTarget->setTargetTexture(surface.texture);

    renderContext->beginFrame({
        .renderTargetWidth = _renderTarget->width(),
        .renderTargetHeight = _renderTarget->height(),
        .loadAction = rive::gpu::LoadAction::clear,
        .clearColor = 0,
    });
    return _renderer.get();
}

- (void)endFrame:(id<RiveMetalDrawableView>)view
    withCompletion:(_Nullable MTLCommandBufferHandler)completionHandler;
{
    id<MTLCommandBuffer> flushCommandBuffer = [self.metalQueue commandBuffer];
    renderContext->flush({
        .renderTarget = _renderTarget.get(),
        .externalCommandBuffer = (__bridge void*)flushCommandBuffer,
    });

    [flushCommandBuffer presentDrawable:view.currentDrawable];
    if (completionHandler)
    {
        [flushCommandBuffer addCompletedHandler:completionHandler];
    }
    [flushCommandBuffer commit];
}

- (void)setMaximum2DTextureSize:(CGSize)maximum2DTextureSize
{
    _maximum2DTextureSize = maximum2DTextureSize;
}

- (CGSize)maximum2DTextureSize;
{
    return _maximum2DTextureSize;
}

@end

@interface CGRendererContext : RenderContext
- (rive::Renderer*)beginFrame:(id<RiveMetalDrawableView>)view;
@end

constexpr static int kBufferRingSize = 3;

@implementation CGRendererContext
{
    id<MTLTexture> _renderTargetTexture;
    id<MTLBuffer> _buffers[kBufferRingSize];
    int _currentBufferIdx;
    AutoCF<CGContextRef> _cgContext;
    std::unique_ptr<rive::CGRenderer> _renderer;
    CGSize _maximum2DTextureSize;
}

- (instancetype)init
{
    self = [super init];

    _renderTargetTexture = nil;
    for (int i = 0; i < kBufferRingSize; ++i)
    {
        _buffers[i] = nil;
    }
    _currentBufferIdx = -1;

    static id<MTLDevice> s_plsGPU = MTLCreateSystemDefaultDevice();
    self.metalDevice = s_plsGPU;
    if (!self.metalDevice)
    {
        NSLog(@"Metal is not supported on this device");
        return nil;
    }
    self.metalQueue = [self.metalDevice newCommandQueue];
    self.depthStencilPixelFormat = MTLPixelFormatInvalid;
    self.framebufferOnly = NO;
    self.maximum2DTextureSize =
        Maximum2DTextureSizeFromDevice(self.metalDevice);
    return self;
}

- (rive::Factory*)factory
{
    static rive::CGFactory factory;
    return &factory;
}

- (rive::Renderer*)beginFrame:(id<RiveMetalDrawableView>)view
{
    uint32_t cgBitmapInfo;
    switch (view.colorPixelFormat)
    {
        case MTLPixelFormatBGRA8Unorm:
            cgBitmapInfo =
                kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst;
            break;
        case MTLPixelFormatRGBA8Unorm:
            cgBitmapInfo =
                kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
            break;
        default:
            NSLog(@"error: unsupported colorPixelFormat on MTKView");
            return nullptr;
    }

    id<CAMetalDrawable> surface = view.currentDrawable;
    _renderTargetTexture = surface.texture;
    if (!_renderTargetTexture)
    {
        NSLog(@"error: no surface texture on MTKView");
        return nullptr;
    }

    _currentBufferIdx = (_currentBufferIdx + 1) % kBufferRingSize;
    size_t bufferSize =
        _renderTargetTexture.height * _renderTargetTexture.width * 4;
    if (_buffers[_currentBufferIdx] == nil ||
        _buffers[_currentBufferIdx].allocatedSize != bufferSize)
    {
        _buffers[_currentBufferIdx] =
            [self.metalDevice newBufferWithLength:bufferSize
                                          options:MTLResourceStorageModeShared];
    }
    AutoCF<CGColorSpaceRef> colorSpace = CGColorSpaceCreateDeviceRGB();
    _cgContext =
        AutoCF(CGBitmapContextCreate(_buffers[_currentBufferIdx].contents,
                                     _renderTargetTexture.width,
                                     _renderTargetTexture.height,
                                     8,
                                     _renderTargetTexture.width * 4,
                                     colorSpace,
                                     cgBitmapInfo));

    _renderer = std::make_unique<rive::CGRenderer>(
        _cgContext, _renderTargetTexture.width, _renderTargetTexture.height);
    return _renderer.get();
}

- (void)endFrame:(id<RiveMetalDrawableView>)view
    withCompletion:(_Nullable MTLCommandBufferHandler)completionHandler;
{
    if (_cgContext != nil)
    {
        id<MTLCommandBuffer> commandBuffer = [self.metalQueue commandBuffer];
        id<MTLBlitCommandEncoder> blitEncoder =
            [commandBuffer blitCommandEncoder];
        [blitEncoder copyFromBuffer:_buffers[_currentBufferIdx]
                       sourceOffset:0
                  sourceBytesPerRow:_renderTargetTexture.width * 4
                sourceBytesPerImage:_renderTargetTexture.height *
                                    _renderTargetTexture.width * 4
                         sourceSize:MTLSizeMake(_renderTargetTexture.width,
                                                _renderTargetTexture.height,
                                                1)
                          toTexture:_renderTargetTexture
                   destinationSlice:0
                   destinationLevel:0
                  destinationOrigin:MTLOriginMake(0, 0, 0)];
        [blitEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
        if (completionHandler)
        {
            [commandBuffer addCompletedHandler:completionHandler];
        }
        [commandBuffer commit];
    }
    _renderTargetTexture = nil;
    _renderer = nullptr;
    _cgContext = nullptr;
}

- (void)setMaximum2DTextureSize:(CGSize)maximum2DTextureSize
{
    _maximum2DTextureSize = maximum2DTextureSize;
}

- (CGSize)maximum2DTextureSize;
{
    return _maximum2DTextureSize;
}

@end

@implementation RenderContextManager

// The context manager is a singleton.
+ (RenderContextManager*)shared
{
    static RenderContextManager* single = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      single = [[self alloc] init];
    });
    return single;
}

- (instancetype)init
{
    self.defaultRenderer = RendererType::riveRenderer;
    return self;
}

- (RenderContext*)newDefaultContext
{
    switch (self.defaultRenderer)
    {
        case RendererType::riveRenderer:
            return [self newRiveContext];
        case RendererType::cgRenderer:
            return [self newCGContext];
    }
    RIVE_UNREACHABLE();
}

- (RenderContext*)newRiveContext
{
    return [[RiveRendererContext alloc] init];
}

- (RenderContext*)newCGContext
{
    return [[RiveRendererContext alloc] init];
}

@end
