//
//  RiveFileAssetLoader.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 06/11/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

#ifndef RiveFileAssetLoader_h
#define RiveFileAssetLoader_h

#import <Foundation/Foundation.h>

@class RiveFactory;
@class RiveFileAsset;

DEPRECATED_MSG_ATTRIBUTE("The legacy asset loading API is deprecated. Use "
                         "File.getAssets() and Worker asset APIs instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#loading-referenced-assets")
@interface RiveFileAssetLoader : NSObject
- (BOOL)loadContentsWithAsset:(RiveFileAsset*)asset
                      andData:(NSData*)data
                   andFactory:(RiveFactory*)factory;
- (void)cancel;
@end

#endif /* RiveFileAssetLoader_h */
