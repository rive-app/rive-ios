//
//  RiveFont.m
//  RiveRuntime
//
//  Created by David Skuza on 10/23/24.
//  Copyright © 2024 Rive. All rights reserved.
//

#import "RiveFont.h"
#import <rive/text/font_hb.hpp>
#import <RiveRuntime/RiveRuntime-Swift.h>
#import <CoreText/CoreText.h>

/// Returns a RiveFontStyleWeight for a given float value. Rounds to the nearest
/// hundredth. These values mirror those found here:
/// https://developer.mozilla.org/en-US/docs/Web/CSS/font-weight#common_weight_name_mapping
/// - Parameter value: The float value of the weight.
static RiveFontStyleWeight RiveFontStyleWeightFromFloat(float value)
{
    float rounded = round(value / 100);
    NSInteger toInt = (NSInteger)rounded * 100;
    NSInteger weight = MIN(MAX(toInt, 100), 900);
    switch (weight)
    {
        case RiveFontStyleWeightThin:
            return RiveFontStyleWeightThin;
        case RiveFontStyleWeightUltraLight:
            return RiveFontStyleWeightUltraLight;
        case RiveFontStyleWeightLight:
            return RiveFontStyleWeightLight;
        case RiveFontStyleWeightRegular:
            return RiveFontStyleWeightRegular;
        case RiveFontStyleWeightMedium:
            return RiveFontStyleWeightMedium;
        case RiveFontStyleWeightSemibold:
            return RiveFontStyleWeightSemibold;
        case RiveFontStyleWeightBold:
            return RiveFontStyleWeightBold;
        case RiveFontStyleWeightHeavy:
            return RiveFontStyleWeightHeavy;
        case RiveFontStyleWeightBlack:
            return RiveFontStyleWeightBlack;
        default:
            return RiveFontStyleWeightRegular;
    }
}

@implementation RiveFontStyle
- (instancetype)initWithWeight:(RiveFontStyleWeight)weight
{
    if (self = [super init])
    {
        _weight = weight;
        _rawWeight = CGFloat(weight);
    }
    return self;
}

- (instancetype)initWithRawWeight:(CGFloat)rawWeight
{
    if (self = [super init])
    {
        _rawWeight = rawWeight;
        _weight = RiveFontStyleWeightFromFloat(rawWeight);
    }
    return self;
}

- (NSUInteger)hash
{
    return _rawWeight;
}

// Overwritten since it's used for equality checks of RiveFallbackFontCacheKey
- (BOOL)isEqual:(id)object
{
    if (object == nil)
    {
        return NO;
    }

    if (![object isKindOfClass:[RiveFontStyle class]])
    {
        return NO;
    }

    if (self == object)
    {
        return YES;
    }

    RiveFontStyle* other = (RiveFontStyle*)object;
    return self.weight == other.weight;
}

- (id)copyWithZone:(NSZone*)zone
{
    return [[RiveFontStyle alloc] initWithWeight:self.weight];
}
@end

/// A user-specified array of  fallback fonts.
static NSArray<id<RiveFallbackFontProvider>>* _fallbackFonts = nil;
/// A user-specified block that returns usable font providers.
static RiveFallbackFontsCallback _fallbackFontsCallback = nil;

static rive::rcp<rive::Font> riveFontFromNativeFont(id font,
                                                    bool useSystemShaper)
{
#ifdef WITH_RIVE_TEXT
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
    return HBFont::FromSystem((void*)ctFont, useSystemShaper, weight, width);
#else
    return nullptr;
#endif
}

#ifdef WITH_RIVE_TEXT
static rive::rcp<rive::Font> findFallbackFont(const rive::Unichar missing,
                                              const uint32_t fallbackIndex,
                                              const rive::Font* font)
{
    // We know font is going to come back as an HBFont
    const HBFont* hbFont = static_cast<const HBFont*>(font);

    // Generate a style that will be used to request a cached font, or otherwise
    // user-specified font.
    float value = hbFont->getWeight();
    RiveFontStyle* style = [[RiveFontStyle alloc] initWithRawWeight:value];

    // Otherwise, request possible fallback providers based on the missing
    // character and style. fallbackFontsCallback will always be non-nil,
    // and use a default array if no explicit callback has been set.
    NSArray<id<RiveFallbackFontProvider>>*
        providers = [RiveFont fallbackFontsCallback](style);

    if (fallbackIndex / 2 < providers.count)
    {
        id<RiveFallbackFontProvider> provider =
            providers[fallbackIndex % providers.count];
        id fallbackFont = provider.fallbackFont;
        BOOL usesSystemShaper = fallbackIndex >= providers.count;
        auto font = riveFontFromNativeFont(fallbackFont, usesSystemShaper);
        return rive::rcp<rive::Font>(font);
    }

    return nullptr;
}
#endif

@implementation RiveFont
{
    rive::rcp<rive::Font>
        instance; // note: we do NOT own this, so don't delete it
}

+ (void)load
{
#ifdef WITH_RIVE_TEXT
    rive::Font::gFallbackProc = findFallbackFont;
#endif
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
#ifdef WITH_RIVE_TEXT
    if (_fallbackFonts.count == 0)
    {
        return @[ [[RiveFallbackFontDescriptor alloc]
            initWithDesign:RiveFallbackFontDescriptorDesignDefault
                    weight:RiveFallbackFontDescriptorWeightRegular
                     width:RiveFallbackFontDescriptorWidthStandard] ];
    }

    return _fallbackFonts;
#else
    return @[];
#endif
}

+ (void)setFallbackFonts:
    (nonnull NSArray<id<RiveFallbackFontProvider>>*)fallbackFonts
{
#ifdef WITH_RIVE_TEXT
    // Set the user-specified fallbacks, and reset the cache.
    _fallbackFonts = [fallbackFonts copy];

    // "Reset" fallback fonts callback so that array can take priority
    _fallbackFontsCallback = nil;
#endif
}

+ (void)setFallbackFontsCallback:(RiveFallbackFontsCallback)fallbackFontCallback
{
#ifdef WITH_RIVE_TEXT
    // Set the user-specified fallback block, and reset the cache.
    _fallbackFontsCallback = [fallbackFontCallback copy];

    // "Reset" fallback fonts array so that callback can take priority
    _fallbackFonts = nil;
#endif
}

+ (RiveFallbackFontsCallback)fallbackFontsCallback
{
#ifdef WITH_RIVE_TEXT
    // If there is no user-specified block set, use our internal defaults.
    if (_fallbackFontsCallback == nil)
    {
        return ^NSArray<id<RiveFallbackFontProvider>>*(RiveFontStyle* style)
        {
            // Using this getter will always return a font.
            // If no user-specified fonts were added, this
            // returns a default.
            return [RiveFont fallbackFonts];
        };
    }

    return _fallbackFontsCallback;
#else
    return ^NSArray<id<RiveFallbackFontProvider>>*(RiveFontStyle* style)
    {
        // Using this getter will always return a font.
        // If no user-specified fonts were added, this
        // returns a default.
        return [RiveFont fallbackFonts];
    };
#endif
}

@end
