#include "rive_renderer_view.hh"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#include "include/core/SkCanvas.h"
#include "include/core/SkSurface.h"
#include "include/core/SkSurfaceProps.h"
#include "include/gpu/GrBackendSurface.h"
#include "include/gpu/GrDirectContext.h"
#include "include/gpu/mtl/GrMtlBackendContext.h"
#include "skia_renderer.hpp"

#import "RivePrivateHeaders.h"

/// SkiaMetalContext knows how to construct & provide a graphics context for a given device.
/// This Can be used directly as an alternative to using the SkiaContextManager, for more
/// fine grained control of skia contexts
@interface SkiaMetalContext : NSObject
@property(strong) id<MTLDevice> metalDevice;
@property(strong) id<MTLCommandQueue> metalQueue;
@property sk_sp<GrDirectContext> graphicsContext;
@end

@implementation SkiaMetalContext

- (instancetype)init
{
    self = [super init];
    [self setMetalDevice:MTLCreateSystemDefaultDevice()];
    if (![self metalDevice])
    {
        NSLog(@"Metal is not supported on this device");
        return nil;
    }
    [self setMetalQueue:[[self metalDevice] newCommandQueue]];

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

- (void)dealloc
{
    _graphicsContext.reset(nil);
}

@end

SkiaMetalContext* MakeSkiaMetalContext() { return [[SkiaMetalContext alloc] init]; }

/// The SkiaContextManager is used to allow us to share a skia context, while there is an active
/// view. It has a weak ref to a SkiaMetalContext, which means that when no more RiveRenderViews
/// require these, they can be freed When that drops to 0, we allow the SkiaContext to be garbage
/// collected.
@interface SkiaContextManager : NSObject
- (SkiaMetalContext*)getContext;
+ (SkiaContextManager*)shared;
@end

@implementation SkiaContextManager
__weak SkiaMetalContext* skiaMetalContext;

// The context manager is a singleton.
+ (SkiaContextManager*)shared
{
    static SkiaContextManager* single = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      single = [[self alloc] init];
    });
    return single;
}

- (SkiaMetalContext*)getContext
{
    if (skiaMetalContext != nullptr)
    {
        return skiaMetalContext;
    }
    else
    {
        SkiaMetalContext* temp = skiaMetalContext = MakeSkiaMetalContext();
        skiaMetalContext = temp;
        return temp;
    }
}

@end

sk_sp<SkSurface> SkMtkViewToSurface(MTKView* mtkView, GrDirectContext* grContext)
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

@implementation RiveRendererView
{
    SkiaMetalContext* skiaContext;
    rive::SkiaRenderer* _renderer;
}

- (instancetype)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];

    skiaContext = [[SkiaContextManager shared] getContext];
    self.device = [skiaContext metalDevice];

    [self setDepthStencilPixelFormat:MTLPixelFormatDepth32Float_Stencil8];
    [self setColorPixelFormat:MTLPixelFormatBGRA8Unorm];
    [self setFramebufferOnly:false];
    [self setSampleCount:1];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frameRect
{
    skiaContext = [[SkiaContextManager shared] getContext];

    auto value = [super initWithFrame:frameRect device:[skiaContext metalDevice]];

    [self setDepthStencilPixelFormat:MTLPixelFormatDepth32Float_Stencil8];
    [self setColorPixelFormat:MTLPixelFormatBGRA8Unorm];
    [self setFramebufferOnly:false];
    [self setSampleCount:1];
    //    [self setPreferredFramesPerSecond:60];
    return value;
}

- (void)alignWithRect:(CGRect)rect
          contentRect:(CGRect)contentRect
            alignment:(RiveAlignment)alignment
                  fit:(RiveFit)fit
{
    rive::AABB frame(rect.origin.x,
                     rect.origin.y,
                     rect.size.width + rect.origin.x,
                     rect.size.height + rect.origin.y);

    rive::AABB content(contentRect.origin.x,
                       contentRect.origin.y,
                       contentRect.size.width + contentRect.origin.x,
                       contentRect.size.height + contentRect.origin.y);

    auto riveFit = [self riveFit:fit];
    auto riveAlignment = [self riveAlignment:alignment];

    _renderer->align(riveFit, riveAlignment, frame, content);
}

- (void)drawWithArtboard:(RiveArtboard*)artboard
{
    [artboard artboardInstance]->draw(_renderer);
}

- (void)drawRive:(CGRect)rect size:(CGSize)size
{
    // Intended to be overridden.
}

- (bool)isPaused
{
    return true;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    if (![[self currentDrawable] texture])
    {
        return;
    }
    CGSize size = [self drawableSize];
    sk_sp<SkSurface> surface = SkMtkViewToSurface(self, [skiaContext graphicsContext].get());
    if (!surface)
    {
        NSLog(@"error: no sksurface");
        return;
    }
    auto canvas = surface->getCanvas();

    rive::SkiaRenderer renderer(canvas);
    _renderer = &renderer;
    canvas->clear(SkColor((0x00000000)));
    _renderer->save();

    [self drawRive:rect size:size];
    _renderer->restore();

    surface->flushAndSubmit();
    surface = nullptr;
    _renderer = nullptr;

    id<MTLCommandBuffer> commandBuffer = [[skiaContext metalQueue] commandBuffer];
    [commandBuffer presentDrawable:[self currentDrawable]];
    [commandBuffer commit];
    bool paused = [self isPaused];
    [self setEnableSetNeedsDisplay:paused];
    [self setPaused:paused];
}

- (rive::Fit)riveFit:(RiveFit)fit
{
    rive::Fit riveFit;

    switch (fit)
    {
        case fill:
            riveFit = rive::Fit::fill;
            break;
        case contain:
            riveFit = rive::Fit::contain;
            break;
        case cover:
            riveFit = rive::Fit::cover;
            break;
        case fitHeight:
            riveFit = rive::Fit::fitHeight;
            break;
        case fitWidth:
            riveFit = rive::Fit::fitWidth;
            break;
        case scaleDown:
            riveFit = rive::Fit::scaleDown;
            break;
        case noFit:
            riveFit = rive::Fit::none;
            break;
    }

    return riveFit;
}

- (rive::Alignment)riveAlignment:(RiveAlignment)alignment
{
    rive::Alignment riveAlignment = rive::Alignment::center;

    switch (alignment)
    {
        case topLeft:
            riveAlignment = rive::Alignment::topLeft;
            break;
        case topCenter:
            riveAlignment = rive::Alignment::topCenter;
            break;
        case topRight:
            riveAlignment = rive::Alignment::topRight;
            break;
        case centerLeft:
            riveAlignment = rive::Alignment::centerLeft;
            break;
        case center:
            riveAlignment = rive::Alignment::center;
            break;
        case centerRight:
            riveAlignment = rive::Alignment::centerRight;
            break;
        case bottomLeft:
            riveAlignment = rive::Alignment::bottomLeft;
            break;
        case bottomCenter:
            riveAlignment = rive::Alignment::bottomCenter;
            break;
        case bottomRight:
            riveAlignment = rive::Alignment::bottomRight;
            break;
    }

    return riveAlignment;
}

- (CGPoint)artboardLocationFromTouchLocation:(CGPoint)touchLocation
                                  inArtboard:(CGRect)artboardRect
                                         fit:(RiveFit)fit
                                   alignment:(RiveAlignment)alignment
{
    rive::AABB frame(self.frame.origin.x,
                     self.frame.origin.y,
                     self.frame.size.width + self.frame.origin.x,
                     self.frame.size.height + self.frame.origin.y);

    rive::AABB content(artboardRect.origin.x,
                       artboardRect.origin.y,
                       artboardRect.size.width + artboardRect.origin.x,
                       artboardRect.size.height + artboardRect.origin.y);

    auto riveFit = [self riveFit:fit];
    auto riveAlignment = [self riveAlignment:alignment];

    rive::Mat2D forward = rive::computeAlignment(riveFit, riveAlignment, frame, content);
    rive::Mat2D inverse = forward.invertOrIdentity();

    rive::Vec2D frameLocation(touchLocation.x, touchLocation.y);
    rive::Vec2D convertedLocation = inverse * frameLocation;

    return CGPointMake(convertedLocation.x, convertedLocation.y);
}

@end
