//
//  FileAssetLoaderAdapter.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 07/11/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

#import <FileAssetLoaderAdapter.hpp>
#import <RiveFileAssetLoader.h>
#import <RiveFileAsset.h>
#import <RiveFactory.h>

NS_ASSUME_NONNULL_BEGIN

rive::FileAssetLoaderAdapter::FileAssetLoaderAdapter(RiveFileAssetLoader* myLoader)
{
    loader = myLoader;
}

bool rive::FileAssetLoaderAdapter::loadContents(rive::FileAsset& asset,
                                                rive::Span<const uint8_t> bytes,
                                                rive::Factory* factory)
{
    NSData* data = [NSData dataWithBytes:bytes.data() length:bytes.size()];
    RiveFactory* myFactory = [[RiveFactory alloc] initWithFactory:factory];
    if (asset.is<rive::FontAsset>())
    {
        RiveFontAsset* fontAsset =
            [[RiveFontAsset alloc] initWithFileAsset:asset.as<rive::FontAsset>()];
        return [loader loadContentsWithAsset:fontAsset andData:data andFactory:myFactory];
    }
    else if (asset.is<rive::ImageAsset>())
    {
        RiveImageAsset* imageAsset =
            [[RiveImageAsset alloc] initWithFileAsset:asset.as<rive::ImageAsset>()];
        return [loader loadContentsWithAsset:imageAsset andData:data andFactory:myFactory];
    }
    else if (asset.is<rive::AudioAsset>())
    {
        RiveAudioAsset* audioAsset =
            [[RiveAudioAsset alloc] initWithFileAsset:asset.as<rive::AudioAsset>()];
        return [loader loadContentsWithAsset:audioAsset andData:data andFactory:myFactory];
    }
    return false;
}

NS_ASSUME_NONNULL_END
