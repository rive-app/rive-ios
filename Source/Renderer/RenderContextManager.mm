/*
 * Copyright 2023 Rive
 */

#import <RenderContextManager.h>
#import <RenderContext.h>

#import <PlatformCGImage.h>

#include "utils/auto_cf.hpp"

@implementation RenderContext

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

// skia throws out a bunch of documentation warnings for us
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#include "include/core/SkCanvas.h"
#include "include/core/SkSurface.h"
#include "include/core/SkSurfaceProps.h"
#include "include/gpu/GrBackendSurface.h"
#include "include/gpu/GrDirectContext.h"
#include "include/gpu/mtl/GrMtlBackendContext.h"
#include "skia_renderer.hpp"
#include "skia_factory.hpp"
#pragma clang diagnostic pop

#include "cg_factory.hpp"
#include "cg_renderer.hpp"

#include "Rive.h"
#include "RivePrivateHeaders.h"

@interface SkiaContext : RenderContext
- (rive::Factory*)factory;
- (rive::Renderer*)beginFrame:(MTKView*)view;
@end

@implementation SkiaContext
{
    sk_sp<GrDirectContext> _graphicsContext;
    sk_sp<SkSurface> _sksurface;
    std::unique_ptr<rive::SkiaRenderer> _renderer;
}

- (instancetype)init
{
    self = [super init];

    self.metalDevice = MTLCreateSystemDefaultDevice();
    if (!self.metalDevice)
    {
        NSLog(@"Metal is not supported on this device");
        return nil;
    }
    self.metalQueue = [self.metalDevice newCommandQueue];
    self.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    self.framebufferOnly = NO;

    GrMtlBackendContext metalBackendContext;
    metalBackendContext.fDevice = sk_ret_cfp((__bridge const void*)self.metalDevice);
    metalBackendContext.fQueue = sk_ret_cfp((__bridge const void*)self.metalQueue);

    _graphicsContext = GrDirectContext::MakeMetal(metalBackendContext, GrContextOptions());

    if (!_graphicsContext)
    {
        NSLog(@"GrDirectContext::MakeMetal failed");
        return nil;
    }
    return self;
}

- (rive::Factory*)factory
{
    struct CGSkiaFactory : public rive::SkiaFactory
    {
        std::vector<uint8_t> platformDecode(rive::Span<const uint8_t> span,
                                            rive::SkiaFactory::ImageInfo* info) override
        {
            std::vector<uint8_t> pixels;
            PlatformCGImage image;
            if (PlatformCGImageDecode(span.data(), span.size(), &image))
            {
                info->alphaType = image.opaque ? AlphaType::opaque : AlphaType::premul;
                info->colorType = ColorType::rgba;
                info->width = image.width;
                info->height = image.height;
                info->rowBytes = image.width * 4;
                pixels = std::move(image.pixels);
            }
            return pixels;
        }
    };
    static CGSkiaFactory factory;
    return &factory;
}

static sk_sp<SkSurface> mtk_view_to_sk_surface(MTKView* mtkView, GrDirectContext* grContext)
{
    if (!grContext || MTLPixelFormatDepth32Float_Stencil8 != [mtkView depthStencilPixelFormat] ||
        MTLPixelFormatBGRA8Unorm != [mtkView colorPixelFormat])
    {
        return nullptr;
    }
    const SkColorType colorType = kBGRA_8888_SkColorType;
    sk_sp<SkColorSpace> colorSpace = nullptr;
    const GrSurfaceOrigin origin = kTopLeft_GrSurfaceOrigin;
    const SkSurfaceProps surfaceProps(SkSurfaceProps::kUseDeviceIndependentFonts_Flag,
                                      SkPixelGeometry::kUnknown_SkPixelGeometry);
    int sampleCount = (int)[mtkView sampleCount];
    return SkSurface::MakeFromMTKView(grContext,
                                      (__bridge GrMTLHandle)mtkView,
                                      origin,
                                      sampleCount,
                                      colorType,
                                      colorSpace,
                                      &surfaceProps);
}

- (rive::Renderer*)beginFrame:(MTKView*)view
{
    _sksurface = mtk_view_to_sk_surface(view, _graphicsContext.get());
    if (!_sksurface)
    {
        NSLog(@"error: failed to create SkSurface from MTKView.");
        return nil;
    }
    auto canvas = _sksurface->getCanvas();
    canvas->clear(SkColor((0x00000000)));
    _renderer = std::make_unique<rive::SkiaRenderer>(canvas);
    return _renderer.get();
}

- (void)endFrame:(MTKView*)view withCompletion:(_Nullable MTLCommandBufferHandler)completionHandler;
{
    if (_sksurface != nullptr)
    {
        _sksurface->flushAndSubmit();
    }
    _sksurface = nullptr;
    _renderer = nullptr;

    id<MTLCommandBuffer> commandBuffer = [self.metalQueue commandBuffer];
    [commandBuffer presentDrawable:view.currentDrawable];
    if (completionHandler)
    {
        [commandBuffer addCompletedHandler:completionHandler];
    }
    [commandBuffer commit];
}

@end

#include "rive/pls/pls.hpp"

#if !defined(RIVE_NO_PLS)

#include "rive/pls/metal/pls_render_context_metal_impl.h"
#include "rive/pls/pls_image.hpp"
#include "rive/pls/pls_renderer.hpp"

@interface RiveRendererContext : RenderContext
- (rive::Renderer*)beginFrame:(MTKView*)view;
@end

@implementation RiveRendererContext
{
    rive::pls::PLSRenderContext* _plsContext;
    std::unique_ptr<rive::pls::PLSRenderer> _renderer;
    rive::rcp<rive::pls::PLSRenderTargetMetal> _renderTarget;
}

static std::unique_ptr<rive::pls::PLSRenderContext> make_pls_context_native(id<MTLDevice> gpu)
{
    if (![gpu supportsFamily:MTLGPUFamilyApple1])
    {
        NSLog(@"error: GPU is not Apple family");
        return nullptr;
    }
    class PLSRenderContextNativeImpl : public rive::pls::PLSRenderContextMetalImpl
    {
    public:
        PLSRenderContextNativeImpl(id<MTLDevice> gpu) :
            PLSRenderContextMetalImpl(gpu, ContextOptions())
        {}

    protected:
        rive::rcp<rive::pls::PLSTexture> decodeImageTexture(
            rive::Span<const uint8_t> encodedBytes) override
        {
            PlatformCGImage image;
            if (!PlatformCGImageDecode(encodedBytes.data(), encodedBytes.size(), &image))
            {
                return nullptr;
            }
            // CG only supports premultiplied alpha. Unmultiply now.
            size_t imageSizeInBytes = image.height * image.width * 4;
            for (size_t i = 0; i < imageSizeInBytes; i += 4)
            {
                auto rgba = rive::simd::load<uint8_t, 4>(&image.pixels[i]);
                if (rgba.a != 0)
                {
                    rgba = rgba * 255 / rgba.a;
                }
            }
            uint32_t mipLevelCount = rive::math::msb(image.height | image.width);
            return makeImageTexture(image.width, image.height, mipLevelCount, image.pixels.data());
        }
    };
    auto plsContextImpl =
        std::unique_ptr<PLSRenderContextNativeImpl>(new PLSRenderContextNativeImpl(gpu));
    return std::make_unique<rive::pls::PLSRenderContext>(std::move(plsContextImpl));
}

- (instancetype)init
{
    // Make a single static PLSRenderContext, since it is also the factory and any objects it
    // creates may outlive this 'RiveContext' instance.
    static id<MTLDevice> s_plsGPU = MTLCreateSystemDefaultDevice();
    static std::unique_ptr<rive::pls::PLSRenderContext> s_plsContext =
        make_pls_context_native(s_plsGPU);

    self = [super init];
    self.metalDevice = s_plsGPU;
    self.metalQueue = [s_plsGPU newCommandQueue];
    self.depthStencilPixelFormat = MTLPixelFormatInvalid;
    self.framebufferOnly = YES;
    _plsContext = s_plsContext.get();
    _renderer = std::make_unique<rive::pls::PLSRenderer>(_plsContext);
    return self;
}

- (void)dealloc
{
    // Once nobody is referencing a RiveContext anymore, release the global PLSRenderContext's GPU
    // resource.
    _plsContext->releaseResources();
}

- (rive::Factory*)factory
{
    return _plsContext;
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
            _plsContext->static_impl_cast<rive::pls::PLSRenderContextMetalImpl>()->makeRenderTarget(
                view.colorPixelFormat, view.drawableSize.width, view.drawableSize.height);
    }
    _renderTarget->setTargetTexture(surface.texture);

    _plsContext->beginFrame({
        .renderTargetWidth = _renderTarget->width(),
        .renderTargetHeight = _renderTarget->height(),
        .loadAction = rive::pls::LoadAction::clear,
        .clearColor = 0,
    });
    return _renderer.get();
}

- (void)endFrame:(MTKView*)view withCompletion:(_Nullable MTLCommandBufferHandler)completionHandler;
{
    id<MTLCommandBuffer> flushCommandBuffer = [self.metalQueue commandBuffer];
    _plsContext->flush({
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

#endif // !defined(RIVE_NO_PLS)

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
    self = [super init];

    _renderTargetTexture = nil;
    for (int i = 0; i < kBufferRingSize; ++i)
    {
        _buffers[i] = nil;
    }
    _currentBufferIdx = -1;

    self.metalDevice = MTLCreateSystemDefaultDevice();
    if (!self.metalDevice)
    {
        NSLog(@"Metal is not supported on this device");
        return nil;
    }
    self.metalQueue = [self.metalDevice newCommandQueue];
    self.depthStencilPixelFormat = MTLPixelFormatInvalid;
    self.framebufferOnly = NO;
    return self;
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
    __weak SkiaContext* _skiaContextWeakPtr;
#if !defined(RIVE_NO_PLS)
    __weak RiveRendererContext* _riveRendererContextWeakPtr;
#endif
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
    self.defaultRenderer = RendererType::skiaRenderer;
    return self;
}

- (RenderContext*)getDefaultContext
{
    switch (self.defaultRenderer)
    {
        case RendererType::skiaRenderer:
            return [self getSkiaContext];
        case RendererType::riveRenderer:
            return [self getRiveRendererContext];
        case RendererType::cgRenderer:
            return [self getCGRendererContext];
    }
}

- (RenderContext*)getSkiaContext
{
    // Convert our weak reference to strong before trying to work with it. A weak pointer is liable
    // to be released out from under us at any moment.
    // https://stackoverflow.com/questions/15674320/understanding-weak-reference
    SkiaContext* strongPtr = _skiaContextWeakPtr;
    if (strongPtr == nil)
    {
        strongPtr = [[SkiaContext alloc] init];
        _skiaContextWeakPtr = strongPtr;
    }
    return strongPtr;
}

- (RenderContext*)getRiveRendererContext
{
#if defined(RIVE_NO_PLS)
    NSLog(@"error: build does not include Rive Renderer");
    return nil;
#else
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
#endif
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

- (RiveFactory*)getSkiaFactory
{
    return [[RiveFactory alloc] initWithFactory:[[self getSkiaContext] factory]];
}

- (RiveFactory*)getCGFactory
{
    return [[RiveFactory alloc] initWithFactory:[[self getCGRendererContext] factory]];
}

@end
