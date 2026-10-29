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
DEPRECATED_MSG_ATTRIBUTE("The legacy asset loading API is deprecated. Use "
                         "File.getAssets() and Worker asset APIs instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#loading-referenced-assets")
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
DEPRECATED_MSG_ATTRIBUTE("The legacy asset loading API is deprecated. Use "
                         "File.getAssets() and Worker asset APIs instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#loading-referenced-assets")
@interface RiveImageAsset : RiveFileAsset
@property(nonatomic, readonly) CGSize size;
- (void)renderImage:(RiveRenderImage*)image;
@end

/*
 * RiveFontAsset
 */
DEPRECATED_MSG_ATTRIBUTE("The legacy asset loading API is deprecated. Use "
                         "File.getAssets() and Worker asset APIs instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#loading-referenced-assets")
@interface RiveFontAsset : RiveFileAsset
- (void)font:(RiveFont*)font;
@end

/*
 * RiveAudioAsset
 */
DEPRECATED_MSG_ATTRIBUTE("The legacy asset loading API is deprecated. Use "
                         "File.getAssets() and Worker asset APIs instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#loading-referenced-assets")
@interface RiveAudioAsset : RiveFileAsset
- (void)audio:(RiveAudio*)audio;
@end

NS_ASSUME_NONNULL_END

#endif /* RiveFileAsset_h */
