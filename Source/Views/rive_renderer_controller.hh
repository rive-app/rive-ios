#ifndef _RIVE_RENDERER_CONTROLLER_H_
#define _RIVE_RENDERER_CONTROLLER_H_

#import <Foundation/Foundation.h>
#import "Renderer/"

@interface SkiaRenderer : NSObject
- (void)draw:(CGRect)rect toCanvas:(SkCanvas*)canvas atSize:(CGSize)size;
- (bool)isPaused;
- (void)togglePaused;
@end
#endif
