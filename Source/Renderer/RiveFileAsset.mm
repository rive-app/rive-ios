//
//  RiveFileAsset.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 07/11/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <RiveFileAsset.h>

@implementation RiveFileAsset
{
    const rive::FileAsset* instance;
}
- (const rive::FileAsset*)getInstance
{
    return instance;
}

- (instancetype)initWithFileAsset:(const rive::FileAsset*)fileAsset
{
    if (self = [super init])
    {
        instance = (rive::FileAsset* _Nonnull)fileAsset;
        return self;
    }
    else
    {
        return nil;
    }
}

- (nonnull NSString*)cdnBaseUrl
{
    std::string str = instance->cdnBaseUrl();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

- (nonnull NSString*)cdnUuid
{
    std::string str = instance->cdnUuidStr();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

- (nonnull NSString*)fileExtension
{
    std::string str = instance->fileExtension();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

- (nonnull NSString*)name
{
    std::string str = instance->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

- (nonnull NSString*)uniqueFilename
{
    std::string str = instance->uniqueFilename();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

@end

@implementation RiveImageAsset
- (instancetype)initWithFileAsset:(const rive::ImageAsset*)fileAsset
{
    return [super initWithFileAsset:fileAsset];
}

- (void)renderImage:(RiveRenderImage*)image
{

    ((rive::ImageAsset*)[self getInstance])->renderImage([image instance]);
}

@end

@implementation RiveFontAsset
- (instancetype)initWithFileAsset:(const rive::FontAsset*)fileAsset
{
    return [super initWithFileAsset:fileAsset];
}

- (void)font:(RiveFont*)font
{
    ((rive::FontAsset*)[self getInstance])->font([font instance]);
}
@end
