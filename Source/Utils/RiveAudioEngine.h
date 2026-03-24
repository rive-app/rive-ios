//
//  RiveAudioEngine.h
//  RiveRuntime
//
//  Created by David Skuza on 3/11/26.
//  Copyright © 2026 Rive. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AudioEngine)
@interface RiveAudioEngine : NSObject

+ (void)start;
+ (void)stop;

@end

NS_ASSUME_NONNULL_END
