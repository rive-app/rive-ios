//
//  RiveUIRenderContext.m
//  RiveRuntime
//
//  Created by David Skuza on 9/10/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import "RiveUIRenderContext.h"
#import <RiveRuntime/RiveConcurrency.h>

#import <CoreGraphics/CoreGraphics.h>

#include "rive/renderer/render_context.hpp"
#include "rive/renderer/rive_renderer.hpp"
#include "rive/renderer/gpu.hpp"
#include "rive/renderer/metal/render_context_metal_impl.h"

#include <memory>

NS_ASSUME_NONNULL_BEGIN

@implementation RiveUIRenderContext
{
    std::unique_ptr<rive::gpu::RenderContext> _renderContext;
    id<MTLCommandQueue> _metalQueue;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if (self = [super init])
    {
        _renderContext = rive::gpu::RenderContextMetalImpl::MakeContext(
            device, rive::gpu::RenderContextMetalImpl::ContextOptions());
        _metalQueue = [device newCommandQueue];
    }
    return self;
}

- (void)dealloc
{
    _renderContext->releaseResources();
}

+ (RiveUIRenderContext*)sharedContext
{
    static dispatch_once_t onceToken;
    static RiveUIRenderContext* renderContext;
    dispatch_once(&onceToken, ^{
      renderContext = [[RiveUIRenderContext alloc] init];
    });
    return renderContext;
}

- (rive::Factory*)factory
{
    return _renderContext.get();
}

- (id<MTLCommandBuffer>)newCommandBuffer
{
    return [_metalQueue commandBuffer];
}

@end

NS_ASSUME_NONNULL_END
