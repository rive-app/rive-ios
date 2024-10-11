#include "rive_renderer_view.hh"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#import "RivePrivateHeaders.h"
#import <RenderContext.h>
#import <RenderContextManager.h>
// We manually need to provide this as our build-time config isn't shared with
// xcode.
#define WITH_RIVE_AUDIO
#include "rive/audio/audio_engine.hpp"

@implementation RiveRendererView
{
    RenderContext* _renderContext;
    rive::Renderer* _renderer;
}

- (void)didEnterBackground:(NSNotification*)notification
{
    auto engine = rive::AudioEngine::RuntimeEngine(false);
    if (engine != nil)
    {
        engine->stop();
    }
}

- (void)didEnterForeground:(NSNotification*)notification
{
    auto engine = rive::AudioEngine::RuntimeEngine(false);
    if (engine != nil)
    {
        engine->start();
    }
}

- (instancetype)initWithCoder:(NSCoder*)decoder
{
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(didEnterBackground:)
               name:UIApplicationDidEnterBackgroundNotification
             object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(didEnterForeground:)
               name:UIApplicationWillEnterForegroundNotification
             object:nil];
#else
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(didEnterBackground:)
               name:NSApplicationDidResignActiveNotification
             object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(didEnterForeground:)
               name:NSApplicationWillBecomeActiveNotification
             object:nil];
#endif
    self = [super initWithCoder:decoder];

    _renderContext = [[RenderContextManager shared] getDefaultContext];
    assert(_renderContext);
    self.device = [_renderContext metalDevice];

    [self setDepthStencilPixelFormat:_renderContext.depthStencilPixelFormat];
    [self setColorPixelFormat:MTLPixelFormatBGRA8Unorm];
    [self setFramebufferOnly:_renderContext.framebufferOnly];
    [self setSampleCount:1];

    return self;
}

- (instancetype)initWithFrame:(CGRect)frameRect
{
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(didEnterBackground:)
               name:UIApplicationDidEnterBackgroundNotification
             object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(didEnterForeground:)
               name:UIApplicationWillEnterForegroundNotification
             object:nil];
#else
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(didEnterBackground:)
               name:NSApplicationDidResignActiveNotification
             object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(didEnterForeground:)
               name:NSApplicationWillBecomeActiveNotification
             object:nil];
#endif
    _renderContext = [[RenderContextManager shared] getDefaultContext];
    assert(_renderContext);

    auto value = [super initWithFrame:frameRect
                               device:_renderContext.metalDevice];

    [self setDepthStencilPixelFormat:_renderContext.depthStencilPixelFormat];
    [self setColorPixelFormat:MTLPixelFormatBGRA8Unorm];
    [self setFramebufferOnly:_renderContext.framebufferOnly];
    [self setSampleCount:1];

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
- (void)save
{
    assert(_renderer != nil);
    _renderer->save();
}

- (void)restore
{
    assert(_renderer != nil);
    _renderer->restore();
}

- (void)transform:(float)xx
               xy:(float)xy
               yx:(float)yx
               yy:(float)yy
               tx:(float)tx
               ty:(float)ty
{
    assert(_renderer != nil);
    _renderer->transform(rive::Mat2D{xx, xy, yx, yy, tx, ty});
}

- (void)drawWithArtboard:(RiveArtboard*)artboard
{
    assert(_renderer != nil);
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

- (void)drawInRect:(CGRect)rect
    withCompletion:(_Nullable MTLCommandBufferHandler)completionHandler
{
    if (CGRectGetWidth(rect) == 0 || CGRectGetHeight(rect) == 0)
    {
        return;
    }

    if (![[self currentDrawable] texture])
    {
        return;
    }

    _renderer = [_renderContext beginFrame:self];
    if (_renderer != nil)
    {
        _renderer->save();
        [self drawRive:rect size:self.drawableSize];
        _renderer->restore();
    }
    [_renderContext endFrame:self withCompletion:completionHandler];

    _renderer = nil;

    bool paused = [self isPaused];
    [self setEnableSetNeedsDisplay:paused];
    [self setPaused:paused];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    [self drawInRect:rect withCompletion:NULL];
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
    // Note, we've offset the frame by the frame.origin before
    // but in testing our touch location seems to already take this into account
    rive::AABB frame(0, 0, self.frame.size.width, self.frame.size.height);

    rive::AABB content(artboardRect.origin.x,
                       artboardRect.origin.y,
                       artboardRect.size.width + artboardRect.origin.x,
                       artboardRect.size.height + artboardRect.origin.y);

    auto riveFit = [self riveFit:fit];
    auto riveAlignment = [self riveAlignment:alignment];

    rive::Mat2D forward =
        rive::computeAlignment(riveFit, riveAlignment, frame, content);
    rive::Mat2D inverse = forward.invertOrIdentity();

    rive::Vec2D frameLocation(touchLocation.x, touchLocation.y);
    rive::Vec2D convertedLocation = inverse * frameLocation;

    return CGPointMake(convertedLocation.x, convertedLocation.y);
}

@end
