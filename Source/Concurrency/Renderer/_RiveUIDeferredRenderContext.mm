//
//  _RiveUIDeferredRenderContext.mm
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <RiveRuntime/_RiveUIRenderContextProtocol.h>
#import "_RiveUIDeferredRenderContext.h"

#if defined(RIVE_CANVAS) && defined(RIVE_ORE)

#import <Metal/Metal.h>

#include "rive/renderer/cmd/deferred_host.hpp"
#include "rive/renderer/metal/render_context_metal_impl.h"

#include <cassert>
#include <memory>

NS_ASSUME_NONNULL_BEGIN

@implementation _RiveUIDeferredRenderContext
{
    std::unique_ptr<rive::gpu::RenderContext> _renderContext;
    id<MTLCommandQueue> _metalQueue;
    std::unique_ptr<rive::cmd::DeferredSession> _session;
    rive::cmd::DeferredInlineHost _host;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if (self = [super init])
    {
        _renderContext = rive::gpu::RenderContextMetalImpl::MakeContext(
            device, rive::gpu::RenderContextMetalImpl::ContextOptions());
        _metalQueue = [device newCommandQueue];
        auto metalContext =
            _renderContext
                ->static_impl_cast<rive::gpu::RenderContextMetalImpl>();
        // Canvas and Ore replay may submit internal command buffers while the
        // screen flush uses an external buffer. Routing both through this queue
        // lets Metal preserve their submission and GPU execution order.
        metalContext->setCommandQueue(_metalQueue);
    }
    return self;
}

- (void)dealloc
{
    assert(_session == nullptr);
    _renderContext->releaseResources();
}

- (rive::Factory*)beginCommandProcessing
{
    assert(_session == nullptr);
    _session = std::make_unique<rive::cmd::DeferredSession>(
        rive::ore::ReplayCaps::from(*_renderContext->ore()));
    // The session remains the import/recording factory. Binding the real
    // context lets scripts reach GPU state through Factory::renderContext;
    // their visible artboard and Canvas draws are still recorded.
    _session->bindRenderContext(_renderContext.get());
    _host.bindSession(_session.get());
    return _session.get();
}

- (void)endCommandProcessing
{
    assert(_session != nullptr);
    // Unbind first, then release the replayer's resident GPU resources. A later
    // session restarts its handle namespace, so it must not inherit resident
    // table entries from this run.
    _host.bindSession(nullptr);
    _host.replayer().reset();
    _session.reset();
}

- (rive::gpu::RenderContext*)renderContext
{
    return _renderContext.get();
}

- (id<MTLCommandBuffer>)newCommandBuffer
{
    return [_metalQueue commandBuffer];
}

- (rive::cmd::DeferredInlineHost*)deferredHost
{
    return &_host;
}

@end

NS_ASSUME_NONNULL_END

#endif // RIVE_CANVAS && RIVE_ORE
