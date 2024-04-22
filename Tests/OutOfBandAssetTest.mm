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
    XCTAssertEqualObjects([image uniqueName], @"image-49934");
    XCTAssertEqualObjects([image uniqueFilename], @"image-49934.png");
    XCTAssertEqualObjects([image fileExtension], @"png");
    XCTAssertEqualObjects([image cdnBaseUrl], @"https://public.uat.rive.app/cdn/uuid");
    XCTAssertEqualObjects([image cdnUuid], @"eadb7ed8-6d71-4b6c-bbc2-f0f5e9c5dd92");

    XCTAssertNotNil(font);
    XCTAssertEqual(fontData.length, 0);
    XCTAssertEqualObjects([font name], @"Inter");
    XCTAssertEqualObjects([font uniqueName], @"Inter-45562");
    XCTAssertEqualObjects([font uniqueFilename], @"Inter-45562.ttf");
    XCTAssertEqualObjects([font fileExtension], @"ttf");
    XCTAssertEqualObjects([font cdnBaseUrl], @"https://public.uat.rive.app/cdn/uuid");
    XCTAssertEqualObjects([font cdnUuid], @"60ad5ede-993c-4e03-9a80-e56888b2cff3");
}

- (void)testAudioAssetCallbacks
{
    NSError* error = nil;
    NSData* data = [Util loadTestData:@"audio_test"];
    __block RiveAudioAsset* hosted;
    __block RiveAudioAsset* embedded;

    __block NSData* hostedData;
    __block NSData* embeddedData;

    RiveFile* file = [[RiveFile alloc]
             initWithData:data
                  loadCdn:false
        customAssetLoader:^bool(RiveFileAsset* asset, NSData* data, RiveFactory* factory) {
          if ([asset isKindOfClass:[RiveAudioAsset class]])
          {
              if (data.length > 0)
              {
                  embedded = (RiveAudioAsset*)asset;
                  embeddedData = data;
              }
              else
              {
                  hosted = (RiveAudioAsset*)asset;
              }
          }
          return false;
        }
                    error:&error];

    XCTAssertNotNil(file);
    XCTAssertNil(error);

    XCTAssertNotNil(hosted);
    XCTAssertEqual(hostedData.length, 0);
    XCTAssertEqualObjects([hosted name], @"hosted");
    XCTAssertEqualObjects([hosted uniqueName], @"hosted-55368");
    XCTAssertEqualObjects([hosted uniqueFilename], @"hosted-55368.wav");
    XCTAssertEqualObjects([hosted fileExtension], @"wav");
    XCTAssertEqualObjects([hosted cdnBaseUrl], @"https://public.uat.rive.app/cdn/uuid");
    XCTAssertEqualObjects([hosted cdnUuid], @"79b65f1e-94ea-4191-b5ad-b3d5495b6343");

    XCTAssertNotNil(embedded);
    XCTAssertEqual(embeddedData.length, 26095);
    XCTAssertEqualObjects([embedded name], @"embedded");
    //    TODO: fix asset export issue and re-export test file
    XCTAssertEqualObjects([embedded uniqueName], @"embedded-0");
    XCTAssertEqualObjects([embedded uniqueFilename], @"embedded-0.wav");
    XCTAssertEqualObjects([embedded fileExtension], @"wav");
    XCTAssertEqualObjects([embedded cdnBaseUrl], @"https://public.rive.app/cdn/uuid");
    XCTAssertEqualObjects([embedded cdnUuid], @"");
}

- (void)testImageTypesCallbacks
{
    XCTSkip("File extensions are not returning correct values at this point.");
    NSError* error = nil;
    NSData* data = [Util loadTestData:@"img_test"];
    __block RiveImageAsset* png;
    __block RiveImageAsset* webp;
    __block RiveImageAsset* jpeg;

    RiveFile* file = [[RiveFile alloc]
             initWithData:data
                  loadCdn:false
        customAssetLoader:^bool(RiveFileAsset* asset, NSData* data, RiveFactory* factory) {
          if ([asset isKindOfClass:[RiveImageAsset class]])
          {

              if ([asset.fileExtension isEqual:@"png"])
              {
                  png = (RiveImageAsset*)asset;
              }
              else if ([asset.fileExtension isEqual:@"webp"])
              {
                  webp = (RiveImageAsset*)asset;
              }
              else if ([asset.fileExtension isEqual:@"jpeg"])
              {
                  jpeg = (RiveImageAsset*)asset;
              }
          }
          return false;
        }
                    error:&error];

    XCTAssertNotNil(file);
    XCTAssertNil(error);

    XCTAssertNotNil(webp);
    XCTAssertEqualObjects([webp fileExtension], @"webp");
    XCTAssertNotNil(png);
    XCTAssertEqualObjects([png fileExtension], @"png");
    XCTAssertNotNil(jpeg);
    XCTAssertEqualObjects([jpeg fileExtension], @"jpeg");
    XCTAssertEqualObjects([jpeg uniqueFilename], @"hosted-55368.wav");
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
