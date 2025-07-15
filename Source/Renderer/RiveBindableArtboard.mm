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
    std::unique_ptr<rive::ArtboardInstance> _artboardInstance;
}

- (instancetype)initWithArtboard:
    (std::unique_ptr<rive::ArtboardInstance>)artboard
{
    if (self = [super init])
    {
        _artboardInstance = std::move(artboard);
    }
    return self;
}

- (rive::ArtboardInstance*)artboardInstance
{
    return _artboardInstance.get();
}

- (NSString*)name
{
    auto name = _artboardInstance->name();
    return [NSString stringWithCString:name.c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

@end
