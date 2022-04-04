#import <MetalKit/MetalKit.h>
#import <RiveRuntime/RiveArtboard.h>
#import <RiveRuntime/Rive.h>

#import <Metal/Metal.h>

@interface RiveRendererView : MTKView
    @property (strong) id<MTLDevice> metalDevice;
    @property (strong) id<MTLCommandQueue> metalQueue;
    - (instancetype)initWithFrame:(CGRect)frameRect;
    - (void)alignWithRect:(CGRect)rect contentRect:(CGRect)contentRect alignment:(Alignment)alignment fit:(Fit)fit;
    - (void)drawWithArtboard:(RiveArtboard*)artboard;
    - (void)drawRive:(CGRect)rect size:(CGSize)size;
    - (bool)isPaused;
@end
