/*
 * Copyright 2023 Rive
 */

#import <RenderContextManager.h>
#import <RenderContext.hh>

#import <PlatformCGImage.h>

@implementation RenderContext

- (rive::Factory*)factory
{
    return nil;
}

- (rive::Renderer*)beginFrame:(MTKView*)view
{
    return nil;
}

- (void)endFrame
{}

@end

#include "include/core/SkCanvas.h"
#include "include/core/SkSurface.h"
#include "include/core/SkSurfaceProps.h"
#include "include/gpu/GrBackendSurface.h"
#include "include/gpu/GrDirectContext.h"
#include "include/gpu/mtl/GrMtlBackendContext.h"
#include "skia_renderer.hpp"
#include "skia_factory.hpp"

@interface SkiaContext : RenderContext
- (rive::Factory*)factory;
- (rive::Renderer*)beginFrame:(MTKView*)view;
- (void)endFrame;
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
    static CGSkiaFactory gFactory;
    return &gFactory;
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

- (void)endFrame
{
    if (_sksurface != nullptr)
    {
        _sksurface->flushAndSubmit();
    }
    _sksurface = nullptr;
    _renderer = nullptr;
}

@end

#include "rive/pls/pls.hpp"

#if !defined(RIVE_NO_PLS)

#include "rive/pls/metal/pls_render_context_metal_impl.h"
#include "rive/pls/pls_image.hpp"
#include "rive/pls/pls_renderer.hpp"

@interface RiveRendererContext : RenderContext
- (rive::Renderer*)beginFrame:(MTKView*)view;
- (void)endFrame;
@end

@implementation RiveRendererContext
{
    rive::pls::PLSRenderContext* _plsContext;
    std::unique_ptr<rive::pls::PLSRenderer> _renderer;
    rive::rcp<rive::pls::PLSRenderTargetMetal> _renderTarget;
}

static std::unique_ptr<rive::pls::PLSRenderContext> make_pls_context_native(
    id<MTLDevice> gpu, id<MTLCommandQueue> queue)
{
    if (![gpu supportsFamily:MTLGPUFamilyApple1])
    {
        NSLog(@"error: GPU is not Apple family");
        return nullptr;
    }
    class PLSRenderContextNativeImpl : public rive::pls::PLSRenderContextMetalImpl
    {
    public:
        PLSRenderContextNativeImpl(id<MTLDevice> gpu, id<MTLCommandQueue> queue) :
            PLSRenderContextMetalImpl(gpu, queue)
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
        std::unique_ptr<PLSRenderContextNativeImpl>(new PLSRenderContextNativeImpl(gpu, queue));
    return std::make_unique<rive::pls::PLSRenderContext>(std::move(plsContextImpl));
}

- (instancetype)init
{
    // Make a single static PLSRenderContext, since it is also the factory and any objects it
    // creates may outlive this 'RiveContext' instance.
    static id<MTLDevice> s_plsGPU = MTLCreateSystemDefaultDevice();
    static id<MTLCommandQueue> s_plsQueue = [s_plsGPU newCommandQueue];
    static std::unique_ptr<rive::pls::PLSRenderContext> s_plsContext =
        make_pls_context_native(s_plsGPU, s_plsQueue);

    self = [super init];
    self.metalDevice = s_plsGPU;
    self.metalQueue = s_plsQueue;
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
    _plsContext->resetGPUResources();
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

    if (_renderTarget == nullptr || _renderTarget->width() != view.drawableSize.width ||
        _renderTarget->height() != view.drawableSize.height)
    {
        _renderTarget =
            _plsContext->static_impl_cast<rive::pls::PLSRenderContextMetalImpl>()->makeRenderTarget(
                view.colorPixelFormat, view.drawableSize.width, view.drawableSize.height);
    }
    _renderTarget->setTargetTexture(surface.texture);

    rive::pls::PLSRenderContext::FrameDescriptor frameDescriptor;
    frameDescriptor.renderTarget = _renderTarget;
    _plsContext->beginFrame(std::move(frameDescriptor));
    return _renderer.get();
}

- (void)endFrame
{
    _plsContext->flush();
}

@end

#endif // !defined(RIVE_NO_PLS)

@implementation RenderContextManager
{
    __weak SkiaContext* _skiaContextWeakPtr;
    __weak RiveRendererContext* _riveRendererContextWeakPtr;
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
#if TARGET_OS_SIMULATOR
    // The simulator does not support the feature set required for the Rive renderer.
    return [self getSkiaContext];
#elif defined(RIVE_NO_PLS)
    return [self getSkiaContext];
#else
    return self.defaultRenderer == RendererType::skiaRenderer ? [self getSkiaContext]
                                                              : [self getRiveRendererContext];
#endif
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
#if !defined(RIVE_NO_PLS)
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
#else
    return nil;
#endif
}

@end
