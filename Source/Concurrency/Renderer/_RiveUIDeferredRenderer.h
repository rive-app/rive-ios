//
//  _RiveUIDeferredRenderer.h
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

#ifndef _RiveUIDeferredRenderer_h
#define _RiveUIDeferredRenderer_h

#import <Foundation/Foundation.h>

#if defined(RIVE_CANVAS) && defined(RIVE_ORE)

NS_ASSUME_NONNULL_BEGIN

@protocol RiveCommandQueueProtocol;
@protocol RiveUIRendererProtocol;
@class _RiveUIDeferredRenderContext;

/// Internal deferred implementation of `RiveUIRendererProtocol`.
///
/// Each instance owns a draw key and render-target cache for one output
/// surface. Sibling renderers share their worker's command queue and deferred
/// context, including its Metal pipeline, recording session, and replay host.
/// Create instances through `Rive.makeRenderer()` so the renderer matches its
/// worker context.
@interface _RiveUIDeferredRenderer : NSObject <RiveUIRendererProtocol>

/// Creates a renderer from the command queue and deferred context belonging to
/// the same worker pipeline.
- (instancetype)initWithCommandQueue:(id<RiveCommandQueueProtocol>)commandQueue
                       renderContext:
                           (_RiveUIDeferredRenderContext*)renderContext;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

#endif // RIVE_CANVAS && RIVE_ORE

#endif /* _RiveUIDeferredRenderer_h */
