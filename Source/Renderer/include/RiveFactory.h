//
//  RiveFactory.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 08/11/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

#ifndef RiveFactory_h
#define RiveFactory_h

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIFont.h>
#else
#import <AppKit/NSFont.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@protocol RiveFallbackFontProvider;

@interface RiveFont : NSObject
/// An array of font descriptors to attempt to use when text being rendererd by Rive uses a font
/// that is missing a glyph. The fonts will be tried in the order in which they are added to the
/// array.
/// - Note: If unset, the default fallback is a default system font, with regular font weight.
@property(class, copy, nonnull) NSArray<id<RiveFallbackFontProvider>>* fallbackFonts;
@end

@interface RiveRenderImage : NSObject
@end

@interface RiveAudio : NSObject
@end

/*
 * RiveFactory
 */
@interface RiveFactory : NSObject
- (RiveFont*)decodeFont:(NSData*)data;
- (RiveRenderImage*)decodeImage:(NSData*)data;
- (RiveAudio*)decodeAudio:(NSData*)data;
@end

NS_ASSUME_NONNULL_END

#endif /* RiveFactory_h */
