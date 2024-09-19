//
//  RiveFileAsset.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 07/11/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

#ifndef RiveFileAsset_h
#define RiveFileAsset_h

#import <Foundation/Foundation.h>

@class RiveRenderImage;
@class RiveFont;
@class RiveAudio;

NS_ASSUME_NONNULL_BEGIN

/*
 * RiveFileAsset
 */
@interface RiveFileAsset : NSObject
// TODO: add an asset type?
- (NSString*)name;
- (NSString*)uniqueName;
- (NSString*)uniqueFilename;
- (NSString*)fileExtension;
- (NSString*)cdnBaseUrl;
- (NSString*)cdnUuid;
@end

/*
 * RiveImageAsset
 */
@interface RiveImageAsset : RiveFileAsset
@property(nonatomic, readonly) CGSize size;
- (void)renderImage:(RiveRenderImage*)image;
@end

/*
 * RiveFontAsset
 */
@interface RiveFontAsset : RiveFileAsset
- (void)font:(RiveFont*)font;
@end

/*
 * RiveAudioAsset
 */
@interface RiveAudioAsset : RiveFileAsset
- (void)audio:(RiveAudio*)audio;
@end

NS_ASSUME_NONNULL_END

#endif /* RiveFileAsset_h */
