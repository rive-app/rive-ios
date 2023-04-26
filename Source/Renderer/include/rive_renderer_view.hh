#import <MetalKit/MetalKit.h>
#import <RiveRuntime/RiveArtboard.h>
#import <RiveRuntime/Rive.h>

#import <Metal/Metal.h>

@interface RiveRendererView : MTKView
- (instancetype)initWithFrame:(CGRect)frameRect;
- (void)alignWithRect:(CGRect)rect
          contentRect:(CGRect)contentRect
            alignment:(RiveAlignment)alignment
                  fit:(RiveFit)fit;
- (void)drawWithArtboard:(RiveArtboard*)artboard;
- (void)drawRive:(CGRect)rect size:(CGSize)size;
- (bool)isPaused;
- (CGPoint)artboardLocationFromTouchLocation:(CGPoint)touchLocation
                                  inArtboard:(CGRect)artboardRect
                                         fit:(RiveFit)fit
                                   alignment:(RiveAlignment)alignment;
@end
