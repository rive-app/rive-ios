//
//  RiveFileLodaTest.m
//  RiveFileLodaTest
//
//  Created by Maxwell Talbot on 5/10/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Rive.h"
#import "util.h"

@interface RiveFileLoadTest : XCTestCase

@end

@implementation RiveFileLoadTest

/*
 * Test loading junk, should complain.
 */
- (void)testLoadFile
{
    NSError* error = nil;
    RiveFile* file = [Util loadTestFile:@"junk" error:&error];

    XCTAssertNil(file);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects([error domain], @"rive.app.ios.runtime");
    XCTAssertEqualObjects([[error userInfo] valueForKey:@"name"], @"Malformed");
    XCTAssertEqual([error code], 600);
}

/*
 * Test loading format 6 file. this should complain
 */
- (void)testLoadFormat6
{
    NSError* error = nil;
    RiveFile* file = [Util loadTestFile:@"sample6" error:&error];

    XCTAssertNil(file);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects([error domain], @"rive.app.ios.runtime");
    XCTAssertEqualObjects([[error userInfo] valueForKey:@"name"], @"UnsupportedVersion");
    XCTAssertEqual([error code], 500);
}

/*
 * Test loading format Flux file
 */
- (void)testLoadFlux
{
    NSError* error = nil;
    RiveFile* file = [Util loadTestFile:@"flux_capacitor" error:&error];
    RiveArtboard* artboard = [file artboard:&error];
    XCTAssertEqual(artboard.animationCount, 1);
}

/*
 * Test loading format Buggy file
 */
- (void)testLoadBuggy
{
    NSError* error = nil;
    RiveFile* file = [Util loadTestFile:@"off_road_car_blog" error:&error];
    RiveArtboard* artboard = [file artboard:&error];
    XCTAssertEqual(artboard.animationCount, 5);
}

@end
