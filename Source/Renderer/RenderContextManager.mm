/*
 * Copyright 2023 Rive
 */

#import <RenderContextManager.h>
#import <RenderContext.h>
#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <RiveFactory.h>

#include "utils/auto_cf.hpp"
#include "cg_factory.hpp"
#include "cg_renderer.hpp"
#include "rive/renderer/gpu.hpp"

@implementation RenderContext

- (instancetype)init
{
    if (self = [super init])
    {
        _metalDevice = MTLCreateSystemDefaultDevice();
        if (!_metalDevice)
        {
            NSLog(@"Metal is not supported on this device");
            return nil;
        }
        _metalQueue = [_metalDevice newCommandQueue];
        _depthStencilPixelFormat = MTLPixelFormatInvalid;
        // See https://developer.apple.com/metal/Metal-Feature-Set-Tables.pdf
        if ([_metalDevice supportsFamily:MTLGPUFamilyApple3]) {
            _maxTextureSize = 16384;
        } else if ([_metalDevice supportsFamily:MTLGPUFamilyApple2]) {
            _maxTextureSize = 8192;
        } else {
            _maxTextureSize = 4096; // See archive.org for older versions of the document.
        }
        _framebufferOnly = NO;

        return self;
    }
    else
    {
        return nil;
    }
}

- (rive::Factory*)factory
{
    return nil;
}

- (rive::Renderer*)beginFrame:(MTKView*)view
{
    return nil;
}

- (void)endFrame:(MTKView*)view withCompletion:(_Nullable MTLCommandBufferHandler)completionHandler;
{}

@end

#include "rive/renderer/metal/render_context_metal_impl.h"
#include "rive/renderer/rive_render_image.hpp"
#include "rive/renderer/rive_renderer.hpp"

@interface RiveRendererContext : RenderContext
- (rive::Renderer*)beginFrame:(MTKView*)view;
@end

@implementation RiveRendererContext
{
    rive::gpu::RenderContext* _renderContext;
    std::unique_ptr<rive::RiveRenderer> _renderer;
    rive::rcp<rive::gpu::RenderTargetMetal> _renderTarget;
}

static std::unique_ptr<rive::gpu::RenderContext> make_pls_context_native(id<MTLDevice> gpu)
{
    if (![gpu supportsFamily:MTLGPUFamilyApple1])
    {
        NSLog(@"error: GPU is not Apple family");
        return nullptr;
    }
    return rive::gpu::RenderContextMetalImpl::MakeContext(
        gpu, rive::gpu::RenderContextMetalImpl::ContextOptions());
}

- (instancetype)init
{
    if (self = [super init])
    {
        // Make a single static RenderContext, since it is also the factory and any objects it
        // creates may outlive this 'RiveContext' instance.
        static std::unique_ptr<rive::gpu::RenderContext> s_renderContext =
            make_pls_context_native(self.metalDevice);

        self.framebufferOnly = YES;
        _renderContext = s_renderContext.get();
        _renderer = std::make_unique<rive::RiveRenderer>(_renderContext);

        return self;
    }
    else
    {
        return nil;
    }
}

- (void)dealloc
{
    // Once nobody is referencing a RiveContext anymore, release the global RenderContext's GPU
    // resource.
    _renderContext->releaseResources();
}

- (rive::Factory*)factory
{
    return _renderContext;
}

- (rive::Renderer*)beginFrame:(MTKView*)view
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

    if (_renderTarget == nullptr || _renderTarget->width() != view.drawableSize.width ||
        _renderTarget->height() != view.drawableSize.height)
    {
        _renderTarget =
            _renderContext->static_impl_cast<rive::gpu::RenderContextMetalImpl>()->makeRenderTarget(
                view.colorPixelFormat, view.drawableSize.width, view.drawableSize.height);
    }
    _renderTarget->setTargetTexture(surface.texture);

    _renderContext->beginFrame({
        .renderTargetWidth = _renderTarget->width(),
        .renderTargetHeight = _renderTarget->height(),
        .loadAction = rive::gpu::LoadAction::clear,
        .clearColor = 0,
    });
    return _renderer.get();
}

- (void)endFrame:(MTKView*)view withCompletion:(_Nullable MTLCommandBufferHandler)completionHandler;
{
    id<MTLCommandBuffer> flushCommandBuffer = [self.metalQueue commandBuffer];
    _renderContext->flush({
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

@end

@interface CGRendererContext : RenderContext
- (rive::Renderer*)beginFrame:(MTKView*)view;
@end

constexpr static int kBufferRingSize = 3;

@implementation CGRendererContext
{
    id<MTLTexture> _renderTargetTexture;
    id<MTLBuffer> _buffers[kBufferRingSize];
    int _currentBufferIdx;
    AutoCF<CGContextRef> _cgContext;
    std::unique_ptr<rive::CGRenderer> _renderer;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _renderTargetTexture = nil;
        for (int i = 0; i < kBufferRingSize; ++i)
        {
            _buffers[i] = nil;
        }
        _currentBufferIdx = -1;

        return self;
    }
    else
    {
        return nil;
    }
}

- (rive::Factory*)factory
{
    static rive::CGFactory factory;
    return &factory;
}

- (rive::Renderer*)beginFrame:(MTKView*)view
{
    uint32_t cgBitmapInfo;
    switch (view.colorPixelFormat)
    {
        case MTLPixelFormatBGRA8Unorm:
            cgBitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst;
            break;
        case MTLPixelFormatRGBA8Unorm:
            cgBitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
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
    size_t bufferSize = _renderTargetTexture.height * _renderTargetTexture.width * 4;
    if (_buffers[_currentBufferIdx] == nil ||
        _buffers[_currentBufferIdx].allocatedSize != bufferSize)
    {
        _buffers[_currentBufferIdx] =
            [self.metalDevice newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];
    }
    AutoCF<CGColorSpaceRef> colorSpace = CGColorSpaceCreateDeviceRGB();
    _cgContext = AutoCF(CGBitmapContextCreate(_buffers[_currentBufferIdx].contents,
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

- (void)endFrame:(MTKView*)view withCompletion:(_Nullable MTLCommandBufferHandler)completionHandler;
{
    if (_cgContext != nil)
    {
        id<MTLCommandBuffer> commandBuffer = [self.metalQueue commandBuffer];
        id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
        [blitEncoder copyFromBuffer:_buffers[_currentBufferIdx]
                       sourceOffset:0
                  sourceBytesPerRow:_renderTargetTexture.width * 4
                sourceBytesPerImage:_renderTargetTexture.height * _renderTargetTexture.width * 4
                         sourceSize:MTLSizeMake(
                                        _renderTargetTexture.width, _renderTargetTexture.height, 1)
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

@end

@implementation RenderContextManager
{
    __weak RiveRendererContext* _riveRendererContextWeakPtr;
    __weak CGRendererContext* _cgContextWeakPtr;
}

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

- (RenderContext*)getDefaultContext
{
    switch (self.defaultRenderer)
    {
        case RendererType::riveRenderer:
            return [self getRiveRendererContext];
        case RendererType::cgRenderer:
            return [self getCGRendererContext];
    }
    RIVE_UNREACHABLE();
}

- (RenderContext*)getRiveRendererContext
{
    // Convert our weak reference to strong before trying to work with it. A weak pointer is liable
    // to be released out from under us at any moment.
    // https://stackoverflow.com/questions/15674320/understanding-weak-reference
    RiveRendererContext* strongPtr = _riveRendererContextWeakPtr;
    if (strongPtr == nil)
    {
        strongPtr = [[RiveRendererContext alloc] init];
        _riveRendererContextWeakPtr = strongPtr;
    }
    return strongPtr;
}

- (RenderContext*)getCGRendererContext
{
    // Convert our weak reference to strong before trying to work with it. A weak pointer is liable
    // to be released out from under us at any moment.
    // https://stackoverflow.com/questions/15674320/understanding-weak-reference
    CGRendererContext* strongPtr = _cgContextWeakPtr;
    if (strongPtr == nil)
    {
        strongPtr = [[CGRendererContext alloc] init];
        _cgContextWeakPtr = strongPtr;
    }
    return strongPtr;
}

- (RiveFactory*)getDefaultFactory
{
    return [[RiveFactory alloc] initWithFactory:[[self getDefaultContext] factory]];
}

- (RiveFactory*)getRiveRendererFactory
{
    return [[RiveFactory alloc] initWithFactory:[[self getRiveRendererContext] factory]];
}

- (RiveFactory*)getCGFactory
{
    return [[RiveFactory alloc] initWithFactory:[[self getCGRendererContext] factory]];
}

@end
