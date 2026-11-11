//
//  RiveFont.m
//  RiveRuntime
//
//  Created by David Skuza on 10/23/24.
//  Copyright © 2024 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <rive/text/font_hb.hpp>
#import <rive/text/text_language.hpp>
#import <rive/text/utf.hpp>
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
    _languages = @[];
  }
  return self;
}

- (instancetype)initWithRawWeight:(CGFloat)rawWeight
{
  if (self = [super init])
  {
    _rawWeight = rawWeight;
    _weight = RiveFontStyleWeightFromFloat(rawWeight);
    _languages = @[];
  }
  return self;
}

- (instancetype)initWithRawWeight:(CGFloat)rawWeight
                        languages:(NSArray<NSString*>*)languages
{
  if (self = [self initWithRawWeight:rawWeight])
  {
    _languages = [languages copy];
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
  // Languages count, so styles for ja and zh-Hans text, which may want
  // different fonts for the same Han codepoint, never match.
  return self.weight == other.weight &&
         [self.languages isEqualToArray:other.languages];
}

- (id)copyWithZone:(NSZone*)zone
{
  RiveFontStyle* copy = [[RiveFontStyle alloc] initWithWeight:self.weight];
  copy->_languages = _languages;
  return copy;
}
@end

/// A user-specified array of  fallback fonts.
static NSArray<id<RiveFallbackFontProvider>>* _fallbackFonts = nil;
/// A user-specified block that returns usable font providers.
static RiveFallbackFontsCallback _fallbackFontsCallback = nil;

#ifdef WITH_RIVE_TEXT
static rive::rcp<rive::Font> findFallbackFont(
    const rive::Unichar missing,
    const uint32_t fallbackIndex,
    const rive::Font* font,
    NSArray<NSString*>* languages,
    BOOL hasTextLanguage)
{
  // We know font is going to come back as an HBFont
  const HBFont* hbFont = static_cast<const HBFont*>(font);

  // Generate a style that will be used to request a cached font, or otherwise
  // user-specified font.
  float value = hbFont->getWeight();
  RiveFontStyle* style = [[RiveFontStyle alloc] initWithRawWeight:value
                                                        languages:languages];

  // Otherwise, request possible fallback providers based on the missing
  // character and style. fallbackFontsCallback will always be non-nil,
  // and use a default array if no explicit callback has been set.
  NSArray<id<RiveFallbackFontProvider>>*
      providers = [RiveFont fallbackFontsCallback](style);

  if (fallbackIndex / 2 < providers.count)
  {
    id<RiveFallbackFontProvider>
        provider = providers[fallbackIndex % providers.count];
    id fallbackFont = provider.fallbackFont;

    if (provider.allowsSuggestedFonts)
    {
      uint16_t utf16[2];
      int utf16Count = rive::UTF::ToUTF16(missing, utf16);
      CFStringRef string = CFStringCreateWithCharacters(
          kCFAllocatorDefault, utf16, utf16Count);

      if (string)
      {
        // The language decides between fonts that draw the codepoint
        // differently (Han in ja and zh-Hans): the text's own, else the
        // provider's hint, else the system's.
        NSString* language = hasTextLanguage ? languages.firstObject : nil;
        if (language == nil && provider.languageHint)
        {
          language = provider.languageHint();
        }
        if (language == nil)
        {
          language = languages.firstObject;
        }
        CFStringRef cfLanguage = (__bridge CFStringRef)language;
        CTFontRef baseCTFont = (__bridge CTFontRef)fallbackFont;

        // Get Core Text's suggestion for a fallback font
        CTFontRef ctSuggestedFont = CTFontCreateForStringWithLanguage(
            baseCTFont,
            string,
            CFRangeMake(0, CFStringGetLength(string)),
            cfLanguage);
        if (ctSuggestedFont)
        {
          // Convert CTFontRef to the native font (UIFont / NSFont)
          // (they are toll-free bridged) Use __bridge_transfer to
          // transfer ownership to ARC
          id suggestedFont = (__bridge_transfer id)ctSuggestedFont;
          if (suggestedFont)
          {
            fallbackFont = suggestedFont;
          }
        }
      }

      CFRelease(string);
    }

    BOOL usesSystemShaper = fallbackIndex >= providers.count;
    auto riveFont = [RiveFont fontFromNativeFont:fallbackFont
                                 useSystemShaper:usesSystemShaper];
    return rive::rcp<rive::Font>(riveFont);
  }

  return nullptr;
}

// The legacy proc, asked without languages.
static rive::rcp<rive::Font> fallbackProc(
    const rive::Unichar missing,
    const uint32_t fallbackIndex,
    const rive::Font* font)
{
  return findFallbackFont(missing, fallbackIndex, font, @[], NO);
}

// Preferred by the runtime over the legacy proc: also carries the languages
// of the text that needs a fallback.
static rive::rcp<rive::Font> fallbackRequestProc(
    const rive::Font::FallbackRequest& request)
{
  NSMutableArray<NSString*>* languages = [[NSMutableArray alloc]
      initWithCapacity:request.languages.size()];
  for (const std::string& language : request.languages)
  {
    NSString* tag = [[NSString alloc] initWithBytes:language.data()
                                             length:language.size()
                                           encoding:NSUTF8StringEncoding];
    if (tag != nil)
    {
      [languages addObject:tag];
    }
  }
  return findFallbackFont(
      request.missing,
      request.fallbackIndex,
      request.font,
      languages,
      request.hasTextLanguage && languages.count > 0);
}

// Hands the user's preferred languages to the runtime, which shapes text
// without a language of its own in the first and falls back with all of them.
static void applySystemLanguages()
{
  std::vector<std::string> languages;
  for (NSString* language in [NSLocale preferredLanguages])
  {
    const char* utf8 = language.UTF8String;
    if (utf8 != nullptr)
    {
      languages.emplace_back(utf8);
    }
  }
  rive::TextLanguages::setSystemLanguages(languages);
}

// Seeds the runtime's system languages once, and again whenever the user's
// locale changes. Safe to call from any thread, and more than once.
static void seedSystemLanguages()
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // Observe first, so a change can't slip in before the first read.
    [[NSNotificationCenter defaultCenter]
        addObserverForName:NSCurrentLocaleDidChangeNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification* notification) {
                  applySystemLanguages();
                }];
    applySystemLanguages();
  });
}
#endif

@implementation RiveFont
{
  rive::rcp<rive::Font>
      instance; // note: we do NOT own this, so don't delete it
}

+ (rive::rcp<rive::Font>)fontFromNativeFont:(id)font
                            useSystemShaper:(BOOL)useSystemShaper
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

+ (void)load
{
#ifdef WITH_RIVE_TEXT
  rive::Font::gFallbackProc = fallbackProc;
  rive::Font::gFallbackRequestProc = fallbackRequestProc;
  // +load runs before this image's C++ statics are constructed, including
  // the runtime's language list, so seed it once the app is running.
  dispatch_async(dispatch_get_main_queue(), ^{
    seedSystemLanguages();
  });
#endif
}

+ (void)initialize
{
#ifdef WITH_RIVE_TEXT
  // Fonts or fallbacks set up (or a first fallback asked for) before the
  // main queue runs seed the system languages right away.
  if (self == [RiveFont class])
  {
    seedSystemLanguages();
  }
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
                       width:RiveFallbackFontDescriptorWidthStandard
        allowsSuggestedFonts:YES
                languageHint:nil] ];
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
  // Text shaped with the old fallbacks shapes again.
  rive::Font::fallbackFontsChanged();
#endif
}

+ (void)setFallbackFontsCallback:(RiveFallbackFontsCallback)fallbackFontCallback
{
#ifdef WITH_RIVE_TEXT
  // Set the user-specified fallback block, and reset the cache.
  _fallbackFontsCallback = [fallbackFontCallback copy];

  // "Reset" fallback fonts array so that callback can take priority
  _fallbackFonts = nil;
  // Text shaped with the old fallbacks shapes again.
  rive::Font::fallbackFontsChanged();
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
