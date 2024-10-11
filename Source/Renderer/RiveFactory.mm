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
#import <rive/text/font_hb.hpp>
#import <CoreText/CTFont.h>
#import <RiveRuntime/RiveRuntime-Swift.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIFont.h>
#endif

static NSArray<id<RiveFallbackFontProvider>>* _fallbackFonts = nil;

static rive::rcp<rive::Font> riveFontFromNativeFont(id font)
{
    uint16_t weight = 400;
    if ([font conformsToProtocol:@protocol(RiveWeightProvider)])
    {
        weight = [font riveWeightValue];
    }

    uint8_t width = 100;
    if ([font conformsToProtocol:@protocol(RiveFontWidthProvider)])
    {
        width = [font riveFontWidthValue];
    }

    CTFontRef ctFont = (__bridge CTFontRef)font;
    return HBFont::FromSystem((void*)ctFont, weight, width);
}

static rive::rcp<rive::Font> findFallbackFont(
    rive::Span<const rive::Unichar> missing)
{
    // For each descriptor…
    for (id<RiveFallbackFontProvider> fallback in RiveFont.fallbackFonts)
    {
        auto font = riveFontFromNativeFont(fallback.fallbackFont);
        if (font->hasGlyph(missing))
        {
            rive::rcp<rive::Font> rcFont = rive::rcp<rive::Font>(font);
            // because the font was released at load time, we need to give it an
            // extra ref whenever we bump it to a reference counted pointer.
            rcFont->ref();
            return rcFont;
        }
    }
    return nullptr;
}

@implementation RiveFont
{
    rive::rcp<rive::Font>
        instance; // note: we do NOT own this, so don't delete it
}

+ (void)load
{
    rive::Font::gFallbackProc = findFallbackFont;
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

+ (NSArray<id<RiveFallbackFontProvider>>*)fallbackFonts
{
    if (_fallbackFonts.count == 0)
    {
        return @[ [[RiveFallbackFontDescriptor alloc]
            initWithDesign:RiveFallbackFontDescriptorDesignDefault
                    weight:RiveFallbackFontDescriptorWeightRegular
                     width:RiveFallbackFontDescriptorWidthStandard] ];
    }

    return _fallbackFonts;
}

+ (void)setFallbackFonts:
    (nonnull NSArray<id<RiveFallbackFontProvider>>*)fallbackFonts
{
    _fallbackFonts = [fallbackFonts copy];
}

@end

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
    return [[RiveFont alloc] initWithFont:riveFontFromNativeFont(font)];
}
#else
- (RiveFont*)decodeNSFont:(NSFont*)font
{
    return [[RiveFont alloc] initWithFont:riveFontFromNativeFont(font)];
}
#endif

- (RiveAudio*)decodeAudio:(nonnull NSData*)data
{
    UInt8* bytes = (UInt8*)[data bytes];
    return [[RiveAudio alloc]
        initWithAudio:instance->decodeAudio(
                          rive::Span<const uint8_t>(bytes, [data length]))];
}

@end
