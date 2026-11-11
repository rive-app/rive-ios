//
//  RiveFont.h
//  RiveRuntime
//
//  Created by David Skuza on 10/23/24.
//  Copyright © 2024 Rive. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// An enumeration of possible weight values, mirroring those of
/// UIFont/NSFont.Weight
typedef NS_ENUM(NSInteger, RiveFontStyleWeight) {
  RiveFontStyleWeightThin = 100,
  RiveFontStyleWeightUltraLight = 200,
  RiveFontStyleWeightLight = 300,
  RiveFontStyleWeightRegular = 400,
  RiveFontStyleWeightMedium = 500,
  RiveFontStyleWeightSemibold = 600,
  RiveFontStyleWeightBold = 700,
  RiveFontStyleWeightHeavy = 800,
  RiveFontStyleWeightBlack = 900
};

/// An object that represents the styling of a font.
@interface RiveFontStyle : NSObject <NSCopying>
/// The weight of the font. See `RiveFontStyleWeight` for possible values.
/// This value is computed by rounding `rawWeight` to the nearest hundredth.
@property(nonatomic, readonly) RiveFontStyleWeight weight;
/// The raw weight of the font. This value is used to generate the `weight` of
/// the style.
@property(nonatomic, readonly) CGFloat rawWeight;
/// The language tags (usually BCP 47) of the text that needs a fallback font,
/// most preferred first: the text's own language as written in the file when
/// it has one, then the system's preferred languages. Use these to pick a font
/// per language, e.g. for Han characters, which Japanese and Chinese draw
/// differently.
/// - Note: Empty when no language is known.
@property(nonatomic, readonly, copy) NSArray<NSString*>* languages;
- (instancetype)initWithWeight:(RiveFontStyleWeight)weight;
- (instancetype)initWithRawWeight:(CGFloat)rawWeight;
- (instancetype)initWithRawWeight:(CGFloat)rawWeight
                        languages:(NSArray<NSString*>*)languages;
@end

@protocol RiveFallbackFontProvider;

typedef NSArray<id<RiveFallbackFontProvider>>* _Nonnull (
    ^RiveFallbackFontsCallback)(RiveFontStyle*);

@interface RiveFont : NSObject
/// An array of font descriptors to attempt to use when text being rendererd by
/// Rive uses a font that is missing a glyph. The fonts will be tried in the
/// order in which they are added to the array.
/// - Note: If unset, the default fallback is a default system font, with
/// regular font weight.
@property(class, copy, nonnull)
    NSArray<id<RiveFallbackFontProvider>>* fallbackFonts;
/// A block that requests fallback font providers, given a font style.
/// This way, different fallback fonts can be used depending on the styling
/// of the font at draw-time (e.g weight).
@property(class, nonatomic, copy, nonnull)
    RiveFallbackFontsCallback fallbackFontsCallback;
@end

NS_ASSUME_NONNULL_END
