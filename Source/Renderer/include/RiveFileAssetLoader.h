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

@interface RiveFileAssetLoader : NSObject
- (BOOL)loadContentsWithAsset:(RiveFileAsset*)asset
                      andData:(NSData*)data
                   andFactory:(RiveFactory*)factory;
- (void)cancel;
@end

#endif /* RiveFileAssetLoader_h */
