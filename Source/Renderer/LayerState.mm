//
//  LayerState.mm
//  RiveRuntime
//
//  Created by Maxwell Talbot on 8/30/20.
//  Copyright © 2021 Rive. All rights reserved.
//

#import "Rive.h"
#import "RivePrivateHeaders.h"

@implementation RiveLayerState
{
    const rive::LayerState* instance;
}

- (instancetype)initWithLayerState:(const rive::LayerState*)layerState
{
    if (self = [super init])
    {
        self->instance = layerState;
        return self;
    }
    else
    {
        return nil;
    }
}

- (const void*)rive_layer_state
{
    return instance;
}

- (bool)isEntryState
{
    return instance->is<rive::EntryState>();
}

- (bool)isExitState
{
    return instance->is<rive::ExitState>();
}

- (bool)isAnyState
{
    return instance->is<rive::AnyState>();
}

- (bool)isAnimationState
{
    return instance->is<rive::AnimationState>();
}

- (NSString*)name
{
    return @"RiveLayerState";
}

@end

@implementation RiveAnyState

- (NSString*)name
{
    return @"AnyState";
}
@end

@implementation RiveEntryState

- (NSString*)name
{
    return @"EntryState";
}
@end

@implementation RiveExitState

- (NSString*)name
{
    return @"ExitState";
}
@end

@implementation RiveAnimationState

- (NSString*)name
{
    auto inst = [self rive_layer_state];
    auto str = ((const rive::AnimationState*)inst)->animation()->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}
@end

@implementation RiveUnknownState

- (NSString*)name
{
    return @"UnknownState";
}
@end
