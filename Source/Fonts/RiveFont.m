//
//  RiveFont.m
//  RiveRuntime
//
//  Created by David Skuza on 10/23/24.
//  Copyright © 2024 Rive. All rights reserved.
//

#ifdef WITH_RIVE_TEXT

#import "RiveFont.h"
#import "RiveFallbackFontCache.h"
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

/// A cache of all used (Rive) fonts, keyed by style and character.
static NSMutableDictionary<RiveFallbackFontCacheKey*,
                           RiveFallbackFontCacheValue*>* _fallbackFontCache =
    nil;
/// A user-specified array of  fallback fonts.
static NSArray<id<RiveFallbackFontProvider>>* _fallbackFonts = nil;
/// A user-specified block that returns usable font providers.
static RiveFallbackFontsCallback _fallbackFontsCallback = nil;

static rive::rcp<rive::Font> riveFontFromNativeFont(id font,
                                                    bool useSystemShaper)
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
    return HBFont::FromSystem((void*)ctFont, useSystemShaper, weight, width);
}

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

    // Using the above style, check the cache keyed by the given style and
    // missing character.
    RiveFallbackFontCacheKey* cache =
        [[RiveFallbackFontCacheKey alloc] initWithStyle:style
                                              character:missing
                                                  index:fallbackIndex];

    // If there is a cached fallback font, use that.
    RiveFallbackFontCacheValue* cachedValue = _fallbackFontCache[cache];
    if (cachedValue != nil)
    {
        auto font = riveFontFromNativeFont(cachedValue.font,
                                           cachedValue.usesSystemShaper);
        rive::rcp<rive::Font> rcFont = rive::rcp<rive::Font>(font);
        // because the font was released at load time, we need to give
        // it an extra ref whenever we bump it to a reference counted
        // pointer.
        rcFont->ref();
        return rcFont;
    }

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
        rive::rcp<rive::Font> rcFont = rive::rcp<rive::Font>(font);
        // because the font was released at load time, we need to give
        // it an extra ref whenever we bump it to a reference counted
        // pointer.
        rcFont->ref();

        // Once we've used a font, cache it for later use.
        _fallbackFontCache[cache] =
            [[RiveFallbackFontCacheValue alloc] initWithFont:fallbackFont
                                            usesSystemShaper:usesSystemShaper];

        return rcFont;
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
    _fallbackFontCache = [NSMutableDictionary dictionary];
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
    // Set the user-specified fallbacks, and reset the cache.
    _fallbackFonts = [fallbackFonts copy];
    _fallbackFontCache = [NSMutableDictionary dictionary];

    // "Reset" fallback fonts callback so that array can take priority
    _fallbackFontsCallback = nil;
}

+ (void)setFallbackFontsCallback:(RiveFallbackFontsCallback)fallbackFontCallback
{
    // Set the user-specified fallback block, and reset the cache.
    _fallbackFontsCallback = [fallbackFontCallback copy];
    _fallbackFontCache = [NSMutableDictionary dictionary];

    // "Reset" fallback fonts array so that callback can take priority
    _fallbackFonts = nil;
}

+ (RiveFallbackFontsCallback)fallbackFontsCallback
{
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
}

@end

#endif
