//
//  RiveFallbackFontCache.h
//  RiveRuntime
//
//  Created by David Skuza on 10/23/24.
//  Copyright © 2024 Rive. All rights reserved.
//

#ifdef WITH_RIVE_TEXT
#import <Foundation/Foundation.h>
#import <rive/text/font_hb.hpp>
#import <RiveRuntime/RiveRuntime-Swift.h>

@class RiveFontStyle;

NS_ASSUME_NONNULL_BEGIN

/// An object that can be used as a dictionary key when caching fallback fonts.
/// - Note: This implements NSCopying and overrides `isEqual` and `hash` to add
/// support for an object of this type to be used as a key in dictionaries.
@interface RiveFallbackFontCacheKey : NSObject <NSCopying>
/// The style of the requested fallback font to be cached.
@property(nonatomic, readonly, nonnull) RiveFontStyle* style;
/// The actual character for which a fallback font is being requested.
@property(nonatomic, readonly) rive::Unichar character;
/// The fallback index used when originally requesting a fallback.
@property(nonatomic, readonly) uint32_t index;
- (instancetype)initWithStyle:(RiveFontStyle*)style
                    character:(rive::Unichar)character
                        index:(uint32_t)index;
@end

/// An object that can be used as a dictionary value (typically keyed to
/// `RiveFallbackFontCacheKey`), which contains the cached font types.
@interface RiveFallbackFontCacheValue : NSObject
/// The native font type used as the fallback (passed to the C++
/// runtime). On iOS, this will be UIFont. On macOS, this
/// will be NSFont.
@property(nonatomic, readonly) id font;
/// Whether the font used the system shaper (i.e Core Text over Harfbuzz)
@property(nonatomic, readonly) BOOL usesSystemShaper;
- (instancetype)initWithFont:(id)font usesSystemShaper:(BOOL)usesSystemShaper;
@end

NS_ASSUME_NONNULL_END
#endif
