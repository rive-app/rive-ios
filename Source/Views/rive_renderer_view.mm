#include "skia_view.hh"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <UIKit/UIKit.h>

@implementation SkiaView {
    id<MTLCommandQueue> fQueue;
}

- (instancetype)initWithFrame:(CGRect)frameRect {
    return [super initWithFrame:frameRect device:MTLCreateSystemDefaultDevice()];
}

@end
