// Copyright © 2026 Rive. All rights reserved.

#import <Metal/Metal.h>
#import <RiveRuntime/_RiveUIRenderContextProtocol.h>

#if defined(RIVE_CANVAS) && defined(RIVE_ORE)

NS_ASSUME_NONNULL_BEGIN

/// Records draws on the CPU without creating a Rive GPU context.
@interface RecordingRenderContext : NSObject <_RiveUIRenderContextProtocol>
/// Off by default so tests can isolate artboard changes.
@property(atomic) BOOL checksPendingWork;
- (instancetype)initWithDevice:(id<MTLDevice>)device;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END

#endif
