//
//  CDNFileAssetLoader.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 06/11/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <RiveFileAssetLoader.h>

using namespace rive;

@implementation RiveFileAssetLoader

- (BOOL)loadContentsWithAsset:(RiveFileAsset*)asset
                      andData:(NSData*)data
                   andFactory:(RiveFactory*)factory
{
    return false;
}

@end
