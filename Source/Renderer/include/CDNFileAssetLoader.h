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

@interface CDNFileAssetLoader : RiveFileAssetLoader
@end

@interface FallbackFileAssetLoader : RiveFileAssetLoader
- (void)addLoader:(RiveFileAssetLoader*)loader;
@end

typedef bool (^LoadAsset)(RiveFileAsset* asset,
                          NSData* data,
                          RiveFactory* factory);

@interface CustomFileAssetLoader : RiveFileAssetLoader
@property(nonatomic, copy) LoadAsset loadAsset;

- (instancetype)initWithLoader:(LoadAsset)loader;

@end

#endif /* CDNFileAssetLoader_h */
