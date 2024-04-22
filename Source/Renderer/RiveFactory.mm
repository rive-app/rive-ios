//
//  RiveFactory.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 08/11/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <RiveFactory.h>

@implementation RiveFont
{
    rive::rcp<rive::Font> instance; // note: we do NOT own this, so don't delete it
}
- (instancetype)initWithFont:(rive::rcp<rive::Font>)font
{
    if (self = [super init])
    {
        instance = font;
        return self;
    }
    else
    {
        return nil;
    }
}
- (rive::rcp<rive::Font>)instance
{
    return instance;
}

@end

@implementation RiveRenderImage
{
    rive::rcp<rive::RenderImage> instance; // note: we do NOT own this, so don't delete it
}
- (instancetype)initWithImage:(rive::rcp<rive::RenderImage>)image
{
    if (self = [super init])
    {
        instance = image;
        return self;
    }
    else
    {
        return nil;
    }
}
- (rive::rcp<rive::RenderImage>)instance
{
    return instance;
}

@end

@implementation RiveAudio
{
    rive::rcp<rive::AudioSource> instance; // note: we do NOT own this, so don't delete it
}
- (instancetype)initWithAudio:(rive::rcp<rive::AudioSource>)audio
{
    if (self = [super init])
    {
        instance = audio;
        return self;
    }
    else
    {
        return nil;
    }
}
- (rive::rcp<rive::AudioSource>)instance
{
    return instance;
}

@end

/*
 * RiveFactory
 */
@implementation RiveFactory
{
    rive::Factory* instance; // note: we do NOT own this, so don't delete it
}

// Creates a new RiveFactory from a cpp RiveFactory
- (instancetype)initWithFactory:(rive::Factory*)factory
{
    if (self = [super init])
    {
        instance = factory;
        return self;
    }
    else
    {
        return nil;
    }
}

- (RiveRenderImage*)decodeImage:(nonnull NSData*)data
{
    UInt8* bytes = (UInt8*)[data bytes];
    return [[RiveRenderImage alloc]
        initWithImage:instance->decodeImage(rive::Span<const uint8_t>(bytes, [data length]))];
}

- (RiveFont*)decodeFont:(nonnull NSData*)data
{
    UInt8* bytes = (UInt8*)[data bytes];
    return [[RiveFont alloc]
        initWithFont:instance->decodeFont(rive::Span<const uint8_t>(bytes, [data length]))];
}

- (RiveAudio*)decodeAudio:(nonnull NSData*)data
{
    UInt8* bytes = (UInt8*)[data bytes];
    return [[RiveAudio alloc]
        initWithAudio:instance->decodeAudio(rive::Span<const uint8_t>(bytes, [data length]))];
}

@end
