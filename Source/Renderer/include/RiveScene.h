/*
 * Copyright 2022 Rive
 */

#ifndef rive_scene_h
#define rive_scene_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RiveScene : NSObject

- (NSString *)name;
- (CGRect)bounds;
- (void)draw:(RiveRenderer *)renderer;

@end

NS_ASSUME_NONNULL_END

#endif /* rive_scene_h */
