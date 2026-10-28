//
//  OutOfBandAssetTest.mm
//  RiveRuntimeTests
//
//  Created by Maxwell Talbot on 21/11/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Rive.h"
#import "RivePrivateHeaders.h"
#import "RenderContext.h"
#import "util.h"

@interface OutOfBandAssetTest : XCTestCase
@end

@implementation OutOfBandAssetTest

// Retain only the callback's factory and bytes, as a deferred download would.
- (RiveFactory*)factoryAfterReleasingFile:(NSString*)fileName
                               assetClass:(Class)assetClass
                                     data:(NSData**)assetData
{
  __block RiveFactory* retainedFactory = nil;
  __block NSData* retainedData = nil;
  __weak RiveFile* weakFile = nil;
  @autoreleasepool
  {
    NSError* error = nil;
    RiveFile* file = [[RiveFile alloc]
             initWithData:[Util loadTestData:fileName]
                  loadCdn:false
        customAssetLoader:^bool(
            RiveFileAsset* asset, NSData* data, RiveFactory* factory) {
          if ([asset isKindOfClass:assetClass] && data.length > 0)
          {
            retainedFactory = factory;
            retainedData = data;
          }
          return true;
        }
                    error:&error];
    XCTAssertNotNil(file);
    XCTAssertNil(error);
    weakFile = file;
  }

  XCTAssertNil(weakFile);
  XCTAssertNotNil(retainedFactory);
  XCTAssertGreaterThan(retainedData.length, 0u);
  *assetData = retainedData;
  return retainedFactory;
}

- (void)testDecodeImageAfterFileIsDeallocated
{
  NSData* data = nil;
  RiveFactory* factory = [self factoryAfterReleasingFile:@"embedded_assets"
                                              assetClass:[RiveImageAsset class]
                                                    data:&data];
  RiveRenderImage* image = [factory decodeImage:data];
  XCTAssertNotNil(image);
  if (image != nil)
  {
    XCTAssertTrue([image instance] != nullptr);
  }
}

- (void)testDecodeFontAfterFileIsDeallocated
{
  NSData* data = nil;
  RiveFactory* factory = [self factoryAfterReleasingFile:@"embedded_assets"
                                              assetClass:[RiveFontAsset class]
                                                    data:&data];
  RiveFont* font = [factory decodeFont:data];
  XCTAssertNotNil(font);
  if (font != nil)
  {
    XCTAssertTrue([font instance] != nullptr);
  }
}

- (void)testDecodeAudioAfterFileIsDeallocated
{
  NSData* data = nil;
  RiveFactory* factory = [self factoryAfterReleasingFile:@"audio_test"
                                              assetClass:[RiveAudioAsset class]
                                                    data:&data];
  RiveAudio* audio = [factory decodeAudio:data];
  XCTAssertNotNil(audio);
  if (audio != nil)
  {
    XCTAssertTrue([audio instance] != nullptr);
  }
}

- (void)testDecodeInvalidImageDataReturnsEmptyImage
{
  RenderContext* context = [[RenderContextManager shared] newDefaultContext];
  RiveFactory* factory = [[RiveFactory alloc] initWithRenderContext:context];
  NSData* data = [@"not an image" dataUsingEncoding:NSUTF8StringEncoding];
  RiveRenderImage* image = [factory decodeImage:data];
  XCTAssertNotNil(image);
  XCTAssertTrue([image instance] == nullptr);
}

- (void)testDecodeImageWithoutFactoryReturnsEmptyImage
{
  RiveRenderImage* image = [[[RiveFactory alloc] init]
      decodeImage:[NSData data]];
  XCTAssertNotNil(image);
  if (image != nil)
  {
    XCTAssertTrue([image instance] == nullptr);
  }
}

- (void)testDecodeFontWithoutFactoryReturnsEmptyFont
{
  RiveFont* font = [[[RiveFactory alloc] init] decodeFont:[NSData data]];
  XCTAssertNotNil(font);
  if (font != nil)
  {
    XCTAssertTrue([font instance] == nullptr);
  }
}

- (void)testDecodeAudioWithoutFactoryReturnsEmptyAudio
{
  RiveAudio* audio = [[[RiveFactory alloc] init] decodeAudio:[NSData data]];
  XCTAssertNotNil(audio);
  if (audio != nil)
  {
    XCTAssertTrue([audio instance] == nullptr);
  }
}

- (void)testFactoryOwnsContextUntilFactoryIsReleased
{
  __weak RenderContext* weakContext = nil;
  @autoreleasepool
  {
    RiveFactory* factory = nil;
    @autoreleasepool
    {
      RenderContext* context = [[RenderContextManager shared]
          newDefaultContext];
      weakContext = context;
      factory = [[RiveFactory alloc] initWithRenderContext:context];
    }

    // The factory is now the only owner; decoding still needs the context.
    XCTAssertNotNil(weakContext);
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    NSData* data = [NSData
        dataWithContentsOfFile:[bundle pathForResource:@"1x1_png"
                                                ofType:@"png"]];
    XCTAssertGreaterThan(data.length, 0u);
    RiveRenderImage* image = [factory decodeImage:data];
    XCTAssertNotNil(image);
    if (image != nil)
    {
      XCTAssertTrue([image instance] != nullptr);
    }
  }
  XCTAssertNil(weakContext);
}

- (void)testFactoryDecodesEmbeddedAssetsWhileFileIsAlive
{
  for (NSString* fileName in @[ @"embedded_assets", @"audio_test" ])
  {
    NSError* error = nil;
    __block NSUInteger decodedCount = 0;
    RiveFile* file = [[RiveFile alloc]
             initWithData:[Util loadTestData:fileName]
                  loadCdn:false
        customAssetLoader:^bool(
            RiveFileAsset* asset, NSData* data, RiveFactory* factory) {
          if (data.length == 0)
          {
            return true;
          }
          if ([asset isKindOfClass:[RiveImageAsset class]])
          {
            auto image = [[factory decodeImage:data] instance];
            XCTAssertTrue(image != nullptr);
            decodedCount++;
          }
          else if ([asset isKindOfClass:[RiveFontAsset class]])
          {
            auto font = [[factory decodeFont:data] instance];
            XCTAssertTrue(font != nullptr);
            decodedCount++;
          }
          else if ([asset isKindOfClass:[RiveAudioAsset class]])
          {
            auto audio = [[factory decodeAudio:data] instance];
            XCTAssertTrue(audio != nullptr);
            decodedCount++;
          }
          return true;
        }
                    error:&error];
    XCTAssertNotNil(file);
    XCTAssertNil(error);
    XCTAssertEqual(
        decodedCount, [fileName isEqualToString:@"embedded_assets"] ? 2u : 1u);
  }
}

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
      customAssetLoader:^bool(
          RiveFileAsset* asset, NSData* data, RiveFactory* factory) {
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
  XCTAssertEqualObjects(
      [image cdnBaseUrl], @"https://public.uat.rive.app/cdn/uuid");
  XCTAssertEqualObjects(
      [image cdnUuid], @"eadb7ed8-6d71-4b6c-bbc2-f0f5e9c5dd92");

  XCTAssertNotNil(font);
  XCTAssertEqual(fontData.length, 0);
  XCTAssertEqualObjects([font name], @"Inter");
  XCTAssertEqualObjects([font uniqueName], @"Inter-45562");
  XCTAssertEqualObjects([font uniqueFilename], @"Inter-45562.ttf");
  XCTAssertEqualObjects([font fileExtension], @"ttf");
  XCTAssertEqualObjects(
      [font cdnBaseUrl], @"https://public.uat.rive.app/cdn/uuid");
  XCTAssertEqualObjects(
      [font cdnUuid], @"60ad5ede-993c-4e03-9a80-e56888b2cff3");
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
      customAssetLoader:^bool(
          RiveFileAsset* asset, NSData* data, RiveFactory* factory) {
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
  XCTAssertEqualObjects(
      [hosted cdnBaseUrl], @"https://public.uat.rive.app/cdn/uuid");
  XCTAssertEqualObjects(
      [hosted cdnUuid], @"79b65f1e-94ea-4191-b5ad-b3d5495b6343");

  XCTAssertNotNil(embedded);
  XCTAssertEqual(embeddedData.length, 26095);
  XCTAssertEqualObjects([embedded name], @"embedded");
  //    TODO: fix asset export issue and re-export test file
  XCTAssertEqualObjects([embedded uniqueName], @"embedded-0");
  XCTAssertEqualObjects([embedded uniqueFilename], @"embedded-0.wav");
  XCTAssertEqualObjects([embedded fileExtension], @"wav");
  XCTAssertEqualObjects(
      [embedded cdnBaseUrl], @"https://public.rive.app/cdn/uuid");
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
      customAssetLoader:^bool(
          RiveFileAsset* asset, NSData* data, RiveFactory* factory) {
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
      customAssetLoader:^bool(
          RiveFileAsset* asset, NSData* data, RiveFactory* factory) {
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
  XCTAssertEqualObjects(
      [image cdnBaseUrl], @"https://public.rive.app/cdn/uuid");
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

- (void)testReferencedImageAssetReturnsSize
{
  NSError* error = nil;
  NSData* data = [Util loadTestData:@"referenced_image_asset"];
  __block RiveImageAsset* image;

  RiveFile* file = [[RiveFile alloc]
           initWithData:data
                loadCdn:false
      customAssetLoader:^bool(
          RiveFileAsset* asset, NSData* data, RiveFactory* factory) {
        if ([asset isKindOfClass:[RiveImageAsset class]])
        {
          image = (RiveImageAsset*)asset;
        }
        return false;
      }
                  error:&error];

  XCTAssertEqual(image.size.width, 320);
  XCTAssertEqual(image.size.height, 240);
}

@end
