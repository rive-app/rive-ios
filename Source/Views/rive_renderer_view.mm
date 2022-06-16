#include "rive_renderer_view.hh"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <UIKit/UIKit.h>

#include "include/core/SkCanvas.h"
#include "include/core/SkSurface.h"
#include "include/core/SkSurfaceProps.h"
#include "include/gpu/GrBackendSurface.h"
#include "include/gpu/GrDirectContext.h"
#include "skia_renderer.hpp"

#import "RivePrivateHeaders.h"

/// We build up a share context manager as recycling skia contexts between view
/// changes is inefficient and error prone (leads to crashes).
@interface SkiaContextManager : NSObject
@property(strong) id<MTLDevice> metalDevice;
@property(strong) id<MTLCommandQueue> metalQueue;
@property sk_sp<GrDirectContext> grContext;
+ (SkiaContextManager *)shared;
@end

@implementation SkiaContextManager

+ (SkiaContextManager *)shared {
  static SkiaContextManager *single = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    single = [[self alloc] init];
  });
  return single;
}

- (id)init {
  if (self = [super init]) {
    [self setMetalDevice:MTLCreateSystemDefaultDevice()];
    if (![self metalDevice]) {
      NSLog(@"Metal is not supported on this device");
      return nil;
    }
    [self setMetalQueue:[[self metalDevice] newCommandQueue]];
    _grContext = GrDirectContext::MakeMetal((__bridge void *)[self metalDevice],
                                            (__bridge void *)[self metalQueue],
                                            GrContextOptions());
  }
  return self;
}

@end

sk_sp<SkSurface> SkMtkViewToSurface(MTKView *mtkView,
                                    GrDirectContext *grContext) {
  if (!grContext ||
      MTLPixelFormatDepth32Float_Stencil8 !=
          [mtkView depthStencilPixelFormat] ||
      MTLPixelFormatBGRA8Unorm != [mtkView colorPixelFormat]) {
    return nullptr;
  }
  const SkColorType colorType = kBGRA_8888_SkColorType;
  sk_sp<SkColorSpace> colorSpace = nullptr;
  const GrSurfaceOrigin origin = kTopLeft_GrSurfaceOrigin;
  const SkSurfaceProps surfaceProps(
      SkSurfaceProps::kUseDeviceIndependentFonts_Flag,
      SkPixelGeometry::kUnknown_SkPixelGeometry);
  int sampleCount = (int)[mtkView sampleCount];
  return SkSurface::MakeFromMTKView(grContext, (__bridge GrMTLHandle)mtkView,
                                    origin, sampleCount, colorType, colorSpace,
                                    &surfaceProps);
}

@implementation RiveRendererView {
  GrDirectContext *_grContext;
  rive::SkiaRenderer *_renderer;
  id<MTLCommandQueue> _queue;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super initWithCoder:decoder];

  self.device = [SkiaContextManager shared].metalDevice;
  _grContext = [SkiaContextManager shared].grContext.get();
  _queue = [SkiaContextManager shared].metalQueue;

  [self setDepthStencilPixelFormat:MTLPixelFormatDepth32Float_Stencil8];
  [self setColorPixelFormat:MTLPixelFormatBGRA8Unorm];
  [self setFramebufferOnly:false];
  [self setSampleCount:1];
  return self;
}

- (instancetype)initWithFrame:(CGRect)frameRect {
  _grContext = [SkiaContextManager shared].grContext.get();
  _queue = [SkiaContextManager shared].metalQueue;
  auto value = [super initWithFrame:frameRect
                             device:[SkiaContextManager shared].metalDevice];
  [self setDepthStencilPixelFormat:MTLPixelFormatDepth32Float_Stencil8];
  [self setColorPixelFormat:MTLPixelFormatBGRA8Unorm];
  [self setFramebufferOnly:false];
  [self setSampleCount:1];
  //    [self setPreferredFramesPerSecond:60];
  return value;
}

- (void)alignWithRect:(CGRect)rect contentRect:(CGRect)contentRect alignment:(Alignment)alignment fit:(Fit)fit {
    rive::AABB frame(rect.origin.x, rect.origin.y,
                   rect.size.width + rect.origin.x,
                   rect.size.height + rect.origin.y);

    rive::AABB content(contentRect.origin.x, contentRect.origin.y,
                     contentRect.size.width + contentRect.origin.x,
                     contentRect.size.height + contentRect.origin.y);

    auto riveFit = [self riveFit:fit];
    auto riveAlignment = [self riveAlignment:alignment];

    _renderer->align(riveFit, riveAlignment, frame, content);
}

- (void)drawWithArtboard:(RiveArtboard *)artboard {
  [artboard instance]->draw(_renderer);
}

- (void)drawWithScene:(RiveScene *)scene {
    [scene draw:(rive::Renderer*)_renderer];
}

- (void)drawRive:(CGRect)rect size:(CGSize)size {
  // Intended to be overridden.
}

- (bool)isPaused {
  return true;
}

- (void)drawRect:(CGRect)rect {
  [super drawRect:rect];
  if (![[self currentDrawable] texture]) {
    return;
  }
  CGSize size = [self drawableSize];
  sk_sp<SkSurface> surface = SkMtkViewToSurface(self, _grContext);
  if (!surface) {
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

  id<MTLCommandBuffer> commandBuffer = [_queue commandBuffer];
  [commandBuffer presentDrawable:[self currentDrawable]];
  [commandBuffer commit];
  bool paused = [self isPaused];
  [self setEnableSetNeedsDisplay:paused];
  [self setPaused:paused];
}

- (rive::Fit)riveFit:(Fit)fit {
    rive::Fit riveFit;
    
    switch (fit) {
    case fitFill:
      riveFit = rive::Fit::fill;
      break;
    case fitContain:
      riveFit = rive::Fit::contain;
      break;
    case fitCover:
      riveFit = rive::Fit::cover;
      break;
    case fitFitHeight:
      riveFit = rive::Fit::fitHeight;
      break;
    case fitFitWidth:
      riveFit = rive::Fit::fitWidth;
      break;
    case fitScaleDown:
      riveFit = rive::Fit::scaleDown;
      break;
    case fitNone:
      riveFit = rive::Fit::none;
      break;
    }
    
    return riveFit;
}

- (rive::Alignment)riveAlignment:(Alignment)alignment {
    rive::Alignment riveAlignment = rive::Alignment::center;
    
    switch (alignment) {
    case alignmentTopLeft:
      riveAlignment = rive::Alignment::topLeft;
      break;
    case alignmentTopCenter:
      riveAlignment = rive::Alignment::topCenter;
      break;
    case alignmentTopRight:
      riveAlignment = rive::Alignment::topRight;
      break;
    case alignmentCenterLeft:
      riveAlignment = rive::Alignment::centerLeft;
      break;
    case alignmentCenter:
      riveAlignment = rive::Alignment::center;
      break;
    case alignmentCenterRight:
      riveAlignment = rive::Alignment::centerRight;
      break;
    case alignmentBottomLeft:
      riveAlignment = rive::Alignment::bottomLeft;
      break;
    case alignmentBottomCenter:
      riveAlignment = rive::Alignment::bottomCenter;
      break;
    case alignmentBottomRight:
      riveAlignment = rive::Alignment::bottomRight;
      break;
    }
    
    return riveAlignment;
}

- (CGPoint)artboardLocationFromTouchLocation:(CGPoint)touchLocation
                               inArtboard:(CGRect)artboardRect fit:(Fit)fit alignment:(Alignment)alignment {
    rive::AABB frame(self.frame.origin.x, self.frame.origin.y,
                         self.frame.size.width + self.frame.origin.x,
                         self.frame.size.height + self.frame.origin.y);

    rive::AABB content(artboardRect.origin.x, artboardRect.origin.y,
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
