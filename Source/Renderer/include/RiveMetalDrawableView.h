//
//  RiveMetalDrawableView.h
//  RiveRuntime
//
//  Created by David Skuza on 9/12/24.
//  Copyright © 2024 Rive. All rights reserved.
//

#ifndef RiveMetalDrawableView_h
#define RiveMetalDrawableView_h

#import <Metal/Metal.h>

@protocol RiveMetalDrawableView
@property(nullable, nonatomic, retain) id<MTLDevice> device;
@property(nonatomic) MTLPixelFormat
    depthStencilPixelFormat; // Currently unused; not available in CAMetalLayer
@property(nonatomic) BOOL framebufferOnly;
@property(nonatomic)
    NSUInteger sampleCount; // Currently unused; not available in CAMetalLayer
@property(nonatomic) BOOL
    enableSetNeedsDisplay; // Currently unused; not available in CAMetalLayer
@property(nonatomic, getter=isPaused)
    BOOL paused; // Currently unused; no internal display link used
@property(nullable, nonatomic, readonly) id<CAMetalDrawable> currentDrawable;
@property(nonatomic) MTLPixelFormat colorPixelFormat;
@property(nonatomic) CGSize drawableSize;
- (void)drawableSizeDidChange:(CGSize)drawableSize;
@end

#endif /* RiveMetalDrawableView_h */
