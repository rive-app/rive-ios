//
//  FileAssetLoaderAdapter.hpp
//  RiveRuntime
//
//  Created by Maxwell Talbot on 07/11/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

#ifndef FileAssetLoaderAdapter_h
#define FileAssetLoaderAdapter_h

#import <Rive.h>
#import <RivePrivateHeaders.h>

@class RiveFileAssetLoader;

namespace rive
{

class FileAssetLoaderAdapter : public FileAssetLoader
{
private:
    RiveFileAssetLoader* loader;

public:
    FileAssetLoaderAdapter(RiveFileAssetLoader*);

    bool loadContents(rive::FileAsset& asset,
                      rive::Span<const uint8_t> bytes,
                      rive::Factory* factory) override;
};

} // namespace rive

#endif /* FileAssetLoaderAdapter_h */
