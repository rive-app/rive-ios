#import <MetalKit/MetalKit.h>
#import <RiveRuntime/RiveArtboard.h>
#import <RiveRuntime/Rive.h>

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface RiveRendererView : MTKView

- (instancetype)initWithFrame:(CGRect)frameRect;
/// Deprecated. Use `alignWithRect:contentRect:alignment:fit:scaleFactor:` instead.
/// This is equivalent to calling the new function with a scale factor of 1.
- (void)alignWithRect:(CGRect)rect
          contentRect:(CGRect)contentRect
            alignment:(RiveAlignment)alignment
fit:(RiveFit)fit DEPRECATED_MSG_ATTRIBUTE("Use alignWithRect:contentRect:alignment:fit:scaleFactor: instead.");
- (void)alignWithRect:(CGRect)rect
          contentRect:(CGRect)contentRect
            alignment:(RiveAlignment)alignment
                  fit:(RiveFit)fit
          scaleFactor:(CGFloat)scaleFactor;
- (void)save;
- (void)restore;
- (void)transform:(float)xx
               xy:(float)xy
               yx:(float)yx
               yy:(float)yy
               tx:(float)tx
               ty:(float)ty;
- (void)drawWithArtboard:(RiveArtboard*)artboard;
- (void)drawRive:(CGRect)rect size:(CGSize)size;
- (void)drawInRect:(CGRect)rect
    withCompletion:(_Nullable MTLCommandBufferHandler)completionHandler;
- (bool)isPaused;
- (CGPoint)artboardLocationFromTouchLocation:(CGPoint)touchLocation
                                  inArtboard:(CGRect)artboardRect
                                         fit:(RiveFit)fit
                                   alignment:(RiveAlignment)alignment;

NS_ASSUME_NONNULL_END
@end
