//
//  OutOfBandAssetTest.mm
//  RiveRuntimeTests
//
//  Created by Maxwell Talbot on 21/11/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Rive.h"
#import "util.h"

@interface OutOfBandAssetTest : XCTestCase
@end

@implementation OutOfBandAssetTest

- (void)testHostedAssetsProvideCallbacks
{
    NSError* error = nil;
    NSData* data = [Util loadTestData:@"hosted_assets"];
    __block RiveImageAsset* image;
    __block RiveFontAsset* font;

    __block NSData* imageData;
    __block NSData* fontData;

    RiveFile* file = [[RiveFile alloc]
             initWithData:data
                  loadCdn:false
        customAssetLoader:^bool(RiveFileAsset* asset, NSData* data, RiveFactory* factory) {
          if ([asset isKindOfClass:[RiveImageAsset class]])
          {
              image = (RiveImageAsset*)asset;
              imageData = data;
          }
          if ([asset isKindOfClass:[RiveFontAsset class]])
          {
              font = (RiveFontAsset*)asset;
              fontData = data;
          }
          return false;
        }
                    error:&error];

    XCTAssertNotNil(file);
    XCTAssertNil(error);

    XCTAssertNotNil(image);
    XCTAssertEqual(imageData.length, 0);
    XCTAssertEqualObjects([image name], @"image.png");
    XCTAssertEqualObjects([image uniqueFilename], @"image-49934.png");
    XCTAssertEqualObjects([image fileExtension], @"png");
    XCTAssertEqualObjects([image cdnBaseUrl], @"https://public.uat.rive.app/cdn/uuid");
    XCTAssertEqualObjects([image cdnUuid], @"eadb7ed8-6d71-4b6c-bbc2-f0f5e9c5dd92");

    XCTAssertNotNil(font);
    XCTAssertEqual(fontData.length, 0);
    XCTAssertEqualObjects([font name], @"Inter");
    XCTAssertEqualObjects([font uniqueFilename], @"Inter-45562.ttf");
    XCTAssertEqualObjects([font fileExtension], @"ttf");
    XCTAssertEqualObjects([font cdnBaseUrl], @"https://public.uat.rive.app/cdn/uuid");
    XCTAssertEqualObjects([font cdnUuid], @"60ad5ede-993c-4e03-9a80-e56888b2cff3");
}

- (void)testEmbeddedAssetsProvideData
{
    NSError* error = nil;
    NSData* data = [Util loadTestData:@"embedded_assets"];
    __block RiveImageAsset* image;
    __block RiveFontAsset* font;

    __block NSData* imageData;
    __block NSData* fontData;

    RiveFile* file = [[RiveFile alloc]
             initWithData:data
                  loadCdn:false
        customAssetLoader:^bool(RiveFileAsset* asset, NSData* data, RiveFactory* factory) {
          if ([asset isKindOfClass:[RiveImageAsset class]])
          {
              image = (RiveImageAsset*)asset;
              imageData = data;
          }
          if ([asset isKindOfClass:[RiveFontAsset class]])
          {
              font = (RiveFontAsset*)asset;
              fontData = data;
          }
          return false;
        }
                    error:&error];

    XCTAssertNotNil(file);
    XCTAssertNil(error);

    XCTAssertNotNil(image);
    // data provided in line.
    XCTAssertEqual(imageData.length, 308);
    XCTAssertEqualObjects([image name], @"1x1.png");
    XCTAssertEqualObjects([image uniqueFilename], @"1x1-49935.png");
    XCTAssertEqualObjects([image fileExtension], @"png");
    XCTAssertEqualObjects([image cdnBaseUrl], @"https://public.rive.app/cdn/uuid");
    XCTAssertEqualObjects([image cdnUuid], @"");

    XCTAssertNotNil(font);
    XCTAssertEqual(fontData.length, 3348);
    // data provided in line.
    XCTAssertEqualObjects([font name], @"Inter");
    XCTAssertEqualObjects([font uniqueFilename], @"Inter-45562.ttf");
    XCTAssertEqualObjects([font fileExtension], @"ttf");
    XCTAssertEqualObjects([font cdnBaseUrl], @"https://public.rive.app/cdn/uuid");
    XCTAssertEqualObjects([font cdnUuid], @"");
}

@end
