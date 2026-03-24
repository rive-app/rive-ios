//
//  RiveAudioEngine.m
//  RiveRuntime
//
//  Created by David Skuza on 3/11/26.
//  Copyright © 2026 Rive. All rights reserved.
//

#import "RiveAudioEngine.h"

#ifdef WITH_RIVE_AUDIO
#include "rive/audio/audio_engine.hpp"
#endif

@implementation RiveAudioEngine

+ (void)start
{
#ifdef WITH_RIVE_AUDIO
    auto engine = rive::AudioEngine::RuntimeEngine(false);
    if (engine != nil)
    {
        engine->start();
    }
#endif
}

+ (void)stop
{
#ifdef WITH_RIVE_AUDIO
    auto engine = rive::AudioEngine::RuntimeEngine(false);
    if (engine != nil)
    {
        engine->stop();
    }
#endif
}

@end
