//
//  _RiveUIRenderContextProtocol.h
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

#ifndef _RiveUIRenderContextProtocol_h
#define _RiveUIRenderContextProtocol_h

#import <Foundation/Foundation.h>

#ifdef __cplusplus
namespace rive
{
class Factory;
namespace gpu
{
class RenderContext;
}
} // namespace rive
#endif

NS_ASSUME_NONNULL_BEGIN

@protocol MTLCommandBuffer;

/// Internal worker-scoped rendering strategy shared by the command server and
/// renderer. A context owns the objects returned by its C++ accessors and must
/// not serve concurrent command servers.
@protocol _RiveUIRenderContextProtocol <NSObject>

/// Creates an uncommitted Metal command buffer on the context's queue.
/// Worker renderers call this on the serialized command-server thread.
- (id<MTLCommandBuffer>)newCommandBuffer;

#ifdef __cplusplus
/// Begins one non-reentrant processing session on the command-server thread.
/// The returned factory is borrowed and remains valid only until the paired
/// `endCommandProcessing` call. The C++ command server must be destroyed before
/// that call.
- (rive::Factory*)beginCommandProcessing;

/// Ends the active processing session. Called exactly once, on the same thread
/// as `beginCommandProcessing`, after the C++ command server is destroyed.
- (void)endCommandProcessing;

/// Returns the borrowed, context-owned GPU context used for visible rendering.
/// It is accessed only on the active command-server thread. In immediate mode
/// this object is also the import factory; in deferred mode it is distinct from
/// the recording factory returned by `beginCommandProcessing`.
- (rive::gpu::RenderContext*)renderContext;
#endif

@end

NS_ASSUME_NONNULL_END

#endif /* _RiveUIRenderContextProtocol_h */
