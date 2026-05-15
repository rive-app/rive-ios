//
//  CDNFileAssetLoaderTest.mm
//  RiveRuntimeTests
//
//  Tests that CDNFileAssetLoader does not crash when the RiveFile is
//  deallocated while CDN downloads are in-flight, and that the
//  RenderContext is properly released after downloads complete/cancel.
//

#import <XCTest/XCTest.h>
#import "Rive.h"
#import "util.h"

@interface CDNFileAssetLoaderTest : XCTestCase
@end

@implementation CDNFileAssetLoaderTest

/// Releasing a RiveFile immediately after loading with CDN enabled must not
/// crash. Before the fix, the NSURLSession completion block would call
/// [factory decodeImage:] on a freed render context.
- (void)testImmediateReleaseDoesNotCrash
{
    NSError* error = nil;
    @autoreleasepool
    {
        RiveFile* file =
            [[RiveFile alloc] initWithData:[Util loadTestData:@"hosted_assets"]
                                   loadCdn:true
                                     error:&error];
        XCTAssertNotNil(file);
        XCTAssertNil(error);
        // file released here at end of autoreleasepool
    }

    // Wait long enough for any in-flight CDN downloads to complete/cancel.
    // If the fix is broken, this will crash in decodeImage.
    XCTestExpectation* wait =
        [self expectationWithDescription:@"wait for downloads"];
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
          [wait fulfill];
        });
    [self waitForExpectations:@[ wait ] timeout:5];
}

/// Same test but with a short delay before release, simulating a user
/// navigating away shortly after the file loads.
- (void)testDelayedReleaseDoesNotCrash
{
    NSError* error = nil;
    __block RiveFile* file =
        [[RiveFile alloc] initWithData:[Util loadTestData:@"hosted_assets"]
                               loadCdn:true
                                 error:&error];
    XCTAssertNotNil(file);
    XCTAssertNil(error);

    // Release after 10ms — downloads are in-flight
    XCTestExpectation* released =
        [self expectationWithDescription:@"file released"];
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_MSEC)),
        dispatch_get_main_queue(),
        ^{
          file = nil;
          [released fulfill];
        });
    [self waitForExpectations:@[ released ] timeout:1];

    // Wait for any remaining downloads to finish/cancel
    XCTestExpectation* wait =
        [self expectationWithDescription:@"wait for downloads"];
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
          [wait fulfill];
        });
    [self waitForExpectations:@[ wait ] timeout:5];
}

/// Verify that the RiveFile is released promptly — dealloc cancels
/// pending downloads so nothing holds the file alive.
- (void)testFileIsReleasedAfterDealloc
{
    __weak RiveFile* weakFile = nil;

    @autoreleasepool
    {
        NSError* error = nil;
        RiveFile* file =
            [[RiveFile alloc] initWithData:[Util loadTestData:@"hosted_assets"]
                                   loadCdn:true
                                     error:&error];
        XCTAssertNotNil(file);
        weakFile = file;
    }

    XCTAssertNil(weakFile,
                 @"RiveFile should be released immediately — dealloc cancels "
                 @"pending downloads");
}

@end
