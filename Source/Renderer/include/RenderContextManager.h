/*
 * Copyright 2023 Rive
 */

#pragma once

#ifndef render_context_manager_h
#define render_context_manager_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, RendererType) { riveRenderer, cgRenderer };

@class RenderContext;
@class RiveFactory;

/// The RenderContextManager is used to allow us to share contexts (e.g., Skia,
/// CG, Rive, ...), while there are active view(s). It has weak refs to its
/// render contexts, which means that when no more RiveRenderViews require
/// these, they can be freed.
@interface RenderContextManager : NSObject
@property RendererType defaultRenderer;
+ (RenderContextManager*)shared;
- (RenderContext*)newDefaultContext;
- (RenderContext*)newRiveContext;
- (RenderContext*)newCGContext;
@end

#endif
