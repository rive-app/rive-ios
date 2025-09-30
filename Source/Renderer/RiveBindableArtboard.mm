//
//  RiveBindableArtboard.m
//  RiveRuntime
//
//  Created by David Skuza on 7/14/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>

@implementation RiveBindableArtboard
{
    rive::rcp<rive::BindableArtboard> _bindableArtboard;
}

- (instancetype)initWithBindableArtboard:
    (rive::rcp<rive::BindableArtboard>)bindableArtboard
{
    if (self = [super init])
    {
        _bindableArtboard = bindableArtboard;
    }
    return self;
}

- (rive::rcp<rive::BindableArtboard>)bindableArtboard
{
    return _bindableArtboard;
}

- (NSString*)name
{
    auto name = _bindableArtboard->artboard()->name();
    return [NSString stringWithCString:name.c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

- (void)dealloc
{
    _bindableArtboard = nullptr;
}

@end
