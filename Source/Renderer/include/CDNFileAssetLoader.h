//
//  CDNFileAssetLoader.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 06/11/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

#ifndef CDNFileAssetLoader_h
#define CDNFileAssetLoader_h

#import <RiveRuntime/RiveFileAssetLoader.h>

@class RiveFileAssetLoader;

DEPRECATED_MSG_ATTRIBUTE(
    "The legacy automatic CDN asset loading API is deprecated. Load hosted "
    "assets explicitly in the concurrency runtime instead. See "
    "https://rive.app/docs/runtimes/apple/"
    "migrating-from-legacy#automatic-cdn-asset-loading")
@interface CDNFileAssetLoader : RiveFileAssetLoader
@end

DEPRECATED_MSG_ATTRIBUTE("The legacy asset loading API is deprecated. Use "
                         "File.getAssets() and Worker asset APIs instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#loading-referenced-assets")
@interface FallbackFileAssetLoader : RiveFileAssetLoader
- (void)addLoader:(RiveFileAssetLoader*)loader;
@end

typedef bool (^LoadAsset)(
    RiveFileAsset* asset, NSData* data, RiveFactory* factory)
    DEPRECATED_MSG_ATTRIBUTE(
        "The legacy asset loading API is deprecated. Use File.getAssets() and "
        "Worker asset APIs instead. See "
        "https://rive.app/docs/runtimes/apple/"
        "migrating-from-legacy#loading-referenced-assets");

DEPRECATED_MSG_ATTRIBUTE("The legacy asset loading API is deprecated. Use "
                         "File.getAssets() and Worker asset APIs instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#loading-referenced-assets")
@interface CustomFileAssetLoader : RiveFileAssetLoader
@property(nonatomic, copy) LoadAsset loadAsset;

- (instancetype)initWithLoader:(LoadAsset)loader;

@end

#endif /* CDNFileAssetLoader_h */
