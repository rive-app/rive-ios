//
//  _RiveUIDeferredRenderContext.h
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

#ifndef _RiveUIDeferredRenderContext_h
#define _RiveUIDeferredRenderContext_h

#import <Foundation/Foundation.h>

#if defined(RIVE_CANVAS) && defined(RIVE_ORE)

NS_ASSUME_NONNULL_BEGIN

@protocol MTLDevice;
@protocol _RiveUIRenderContextProtocol;

#ifdef __cplusplus
namespace rive::cmd
{
class DeferredInlineHost;
}
#endif

/// Internal worker-scoped owner of the deferred rendering pipeline.
///
/// The context owns the real GPU context and Metal queue for the worker. While
/// its command server is running, it also owns exactly one recording session
/// and binds that session to a context-owned inline replay host.
/// Active-session, host, and rendering access is serialized on the
/// command-server thread. This type is not a singleton and must not be shared
/// between workers.
@interface _RiveUIDeferredRenderContext
    : NSObject <_RiveUIRenderContextProtocol>

/// Creates a deferred context dedicated to `device`. All target textures must
/// be created by this device.
- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (instancetype)init NS_UNAVAILABLE;

#ifdef __cplusplus
/// Returns a borrowed, context-owned host. The host is bound to a session only
/// between `beginCommandProcessing` and `endCommandProcessing` and may be used
/// only on that processing thread.
- (rive::cmd::DeferredInlineHost*)deferredHost;
#endif

@end

NS_ASSUME_NONNULL_END

#endif // RIVE_CANVAS && RIVE_ORE

#endif /* _RiveUIDeferredRenderContext_h */
