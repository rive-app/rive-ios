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
{
    NSMutableArray<NSURLSessionTask*>* _activeTasks;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _activeTasks = [NSMutableArray array];
    }
    return self;
}

- (void)cancel
{
    @synchronized(_activeTasks)
    {
        for (NSURLSessionTask* task in _activeTasks)
        {
            [task cancel];
        }
        [_activeTasks removeAllObjects];
    }
}

- (void)dealloc
{
    [self cancel];
}

- (bool)loadContentsWithAsset:(RiveFileAsset*)asset
                      andData:(NSData*)data
                   andFactory:(RiveFactory*)factory
{
    if ([[asset cdnUuid] length] > 0)
    {
        NSURL* URL =
            [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",
                                                            [asset cdnBaseUrl],
                                                            [asset cdnUuid]]];
        __block NSURLSessionTask* task = nil;
        task = [[NSURLSession sharedSession]
            downloadTaskWithURL:URL
              completionHandler:^(
                  NSURL* location, NSURLResponse* response, NSError* error) {
                if (error.code == NSURLErrorCancelled)
                {
                    [RiveLogger logCancelledAssetDownload:asset fromURL:URL];
                    return;
                }

                if (!error)
                {
                    NSData* data = [NSData dataWithContentsOfURL:location];

#ifdef WITH_RIVE_TEXT
                    if ([asset isKindOfClass:[RiveFontAsset class]])
                    {
                        RiveFontAsset* fontAsset = (RiveFontAsset*)asset;
                        [fontAsset font:[factory decodeFont:data]];
                        [RiveLogger logFontAssetLoad:fontAsset fromURL:URL];
                    }
#endif
                    if ([asset isKindOfClass:[RiveImageAsset class]])
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

                @synchronized(self->_activeTasks)
                {
                    [self->_activeTasks removeObject:task];
                }
              }];

        @synchronized(_activeTasks)
        {
            [_activeTasks addObject:task];
        }
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

- (void)cancel
{
    for (RiveFileAssetLoader* loader in loaders)
    {
        [loader cancel];
    }
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
