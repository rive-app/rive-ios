/*
 * Copyright 2023 Rive
 */

#pragma once

#ifndef render_context_manager_h
#define render_context_manager_h

#import <Foundation/Foundation.h>

/// Renderer selection is retained for compatibility and has no effect on
/// rendering. Only the Rive renderer is currently used.
typedef NS_ENUM(NSInteger, RendererType) {
  riveRenderer DEPRECATED_MSG_ATTRIBUTE(
      "Only the Rive renderer is currently used. Renderer selection is "
      "retained for compatibility and has no effect on rendering.") = 0,
  cgRenderer DEPRECATED_MSG_ATTRIBUTE(
      "Only the Rive renderer is currently used. Renderer selection is "
      "retained for compatibility and has no effect on rendering.") = 1
} DEPRECATED_MSG_ATTRIBUTE("The legacy rendering API is deprecated. Use the "
                           "concurrency runtime instead. See "
                           "https://rive.app/docs/runtimes/apple/"
                           "migrating-from-legacy#creating-a-rive-view");

@class RenderContext;
@class RiveFactory;

/// Creates render contexts using the Rive renderer.
DEPRECATED_MSG_ATTRIBUTE("The legacy rendering API is deprecated. Use the "
                         "concurrency runtime instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#creating-a-rive-view")
@interface RenderContextManager : NSObject
/// Retains the selected value for compatibility without affecting rendering.
@property RendererType defaultRenderer DEPRECATED_MSG_ATTRIBUTE(
    "Only the Rive renderer is currently used. Renderer selection is retained "
    "for compatibility and has no effect on rendering.");
+ (RenderContextManager*)shared;
- (RenderContext*)newDefaultContext;
- (RenderContext*)newRiveContext;
/// Returns a Rive renderer context, regardless of the legacy method name.
- (RenderContext*)newCGContext DEPRECATED_MSG_ATTRIBUTE(
    "Only the Rive renderer is currently used. This method returns a Rive "
    "renderer context. Use newRiveContext instead.");
@end

#endif
