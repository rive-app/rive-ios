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
#import <RiveRuntime/RiveRuntime-Swift.h>
#import <RenderContext.h>

@implementation RiveRenderImage
{
    rive::rcp<rive::RenderImage>
        instance; // note: we do NOT own this, so don't delete it
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

- (instancetype)initWithData:(NSData*)data
{
    RenderContext* context = [[RenderContextManager shared] newDefaultContext];
    RiveFactory* factory =
        [[RiveFactory alloc] initWithFactory:[context factory]];
    auto renderImage = [factory decodeImage:data];
    auto image = [renderImage instance];
    if (image == nullptr || image.get() == nullptr)
    {
        return nil;
    }
    return [[RiveRenderImage alloc] initWithImage:image];
}

- (rive::rcp<rive::RenderImage>)instance
{
    return instance;
}

@end

@implementation RiveAudio
{
    rive::rcp<rive::AudioSource>
        instance; // note: we do NOT own this, so don't delete it
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
        initWithImage:instance->decodeImage(
                          rive::Span<const uint8_t>(bytes, [data length]))];
}

- (RiveFont*)decodeFont:(nonnull NSData*)data
{
    UInt8* bytes = (UInt8*)[data bytes];
    return [[RiveFont alloc]
        initWithFont:instance->decodeFont(
                         rive::Span<const uint8_t>(bytes, [data length]))];
}

#if TARGET_OS_IPHONE
- (RiveFont*)decodeUIFont:(UIFont*)font
{
    auto riveFont = [RiveFont fontFromNativeFont:font useSystemShaper:YES];
    if (riveFont == nullptr)
    {
        return nil;
    }
    return [[RiveFont alloc] initWithFont:std::move(riveFont)];
}
#else
- (RiveFont*)decodeNSFont:(NSFont*)font
{
    auto riveFont = [RiveFont fontFromNativeFont:font useSystemShaper:YES];
    if (riveFont == nullptr)
    {
        return nil;
    }
    return [[RiveFont alloc] initWithFont:std::move(riveFont)];
}
#endif

- (RiveAudio*)decodeAudio:(nonnull NSData*)data
{
#ifdef WITH_RIVE_AUDIO
    UInt8* bytes = (UInt8*)[data bytes];
    return [[RiveAudio alloc]
        initWithAudio:instance->decodeAudio(
                          rive::Span<const uint8_t>(bytes, [data length]))];
#else
    return nil;
#endif
}

#pragma mark Private

- (rive::Factory*)factory
{
    return instance;
}

@end
