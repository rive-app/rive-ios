//
//  LayerState.mm
//  RiveRuntime
//
//  Created by Maxwell Talbot on 8/30/20.
//  Copyright © 2021 Rive. All rights reserved.
//

#import "Rive.h"
#import "LayerState.h"
#import "RivePrivateHeaders.h"
#include "layer_state.hpp"
#include "exit_state.hpp"
#include "entry_state.hpp"
#include "any_state.hpp"
#include "animation_state.hpp"

@implementation RiveLayerState{
    const rive::LayerState* instance;
}

- (instancetype) initWithLayerState:(const rive::LayerState *)layerState{
    if (self = [super init]) {
        self->instance = layerState;
        return self;
    } else {
        return nil;
    }
}

- (RiveLinearAnimation *)animation{
    return [[RiveLinearAnimation alloc] initWithAnimation: ((const rive::AnimationState *)instance)->animation()];
};

- (bool)isEntryState{
    return instance->is<rive::EntryState>();
}

- (bool)isExitState{
    return instance->is<rive::ExitState>();
}

- (bool)isAnyState{
    return instance->is<rive::AnyState>();
}

- (bool)isAnimationState{
    return instance->is<rive::AnimationState>();
}

- (NSString * )name{
    return @"RiveLayerState";
}

@end

@implementation RiveAnyState

- (NSString * )name{
    return @"AnyState";
}
@end

@implementation RiveEntryState

- (NSString * )name{
    return @"EntryState";
}
@end


@implementation RiveExitState

- (NSString * )name{
    return @"ExitState";
}
@end

@implementation RiveAnimationState

- (NSString * )name{
    return [[self animation] name];
}
@end
