//
//  CDNFileAssetLoader.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 07/11/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

#import <RiveFileAsset.h>
#import <RiveFactory.h>
#import <CDNFileAssetLoader.h>
#import <RiveRuntime/RiveRuntime-Swift.h>

@implementation CDNFileAssetLoader
{}

- (bool)loadContentsWithAsset:(RiveFileAsset*)asset
                      andData:(NSData*)data
                   andFactory:(RiveFactory*)factory
{
    // TODO: Error handling
    // TODO: Track tasks, so we can cancel them if we garbage collect the asset
    // loader

    if ([[asset cdnUuid] length] > 0)
    {
        NSURL* URL =
            [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",
                                                            [asset cdnBaseUrl],
                                                            [asset cdnUuid]]];
        NSURLSessionTask* task = [[NSURLSession sharedSession]
            downloadTaskWithURL:URL
              completionHandler:^(
                  NSURL* location, NSURLResponse* response, NSError* error) {
                if (!error)
                {
                    // Load the data into the reader
                    NSData* data = [NSData dataWithContentsOfURL:location];

                    if ([asset isKindOfClass:[RiveFontAsset class]])
                    {
                        RiveFontAsset* fontAsset = (RiveFontAsset*)asset;
                        [fontAsset font:[factory decodeFont:data]];
                        [RiveLogger logFontAssetLoad:fontAsset fromURL:URL];
                    }
                    else if ([asset isKindOfClass:[RiveImageAsset class]])
                    {
                        RiveImageAsset* imageAsset = (RiveImageAsset*)asset;
                        [imageAsset renderImage:[factory decodeImage:data]];
                        [RiveLogger logImageAssetLoad:imageAsset fromURL:URL];
                    }
                }
                else
                {
                    NSString* message =
                        [NSString stringWithFormat:
                                      @"Failed to load asset from URL %@: %@",
                                      URL.absoluteString,
                                      error.localizedDescription];
                    [RiveLogger logFile:nil error:message];
                }
              }];

        // Kick off the http download
        // QUESTION: Do we need to tie this into the RiveFile so we can wait for
        // these loads to be completed?
        [task resume];
        return true;
    }

    return false;
}

@end

@implementation FallbackFileAssetLoader
{
    NSMutableArray* loaders;
}

- (instancetype)init
{
    self = [super init];
    loaders = [NSMutableArray array];
    return self;
}

- (void)addLoader:(RiveFileAssetLoader*)loader
{
    [loaders addObject:loader];
}

- (bool)loadContentsWithAsset:(RiveFileAsset*)asset
                      andData:(NSData*)data
                   andFactory:(RiveFactory*)factory
{
    for (RiveFileAssetLoader* loader in loaders)
    {
        if ([loader loadContentsWithAsset:asset
                                  andData:data
                               andFactory:factory])
        {
            return true;
        }
    }
    return false;
}

@end

@implementation CustomFileAssetLoader

- (instancetype)initWithLoader:(LoadAsset)loader
{
    self = [super init];
    _loadAsset = loader;
    return self;
}

- (bool)loadContentsWithAsset:(RiveFileAsset*)asset
                      andData:(NSData*)data
                   andFactory:(RiveFactory*)factory
{
    [RiveLogger logLoadingAsset:asset];
    bool loaded = _loadAsset(asset, data, factory);
    if (loaded)
    {
        [RiveLogger logAssetLoaded:asset];
    }
    return loaded;
}

@end
