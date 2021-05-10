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
- (void)testLoadFile {
    XCTAssertThrowsSpecificNamed(
         [Util loadTestFile:@"junk"],
         RiveException,
         @"Malformed"
    );
}

/*
 * Test loading format 6 file. this should complain
 */
- (void)testLoadFormat6 {
    XCTAssertThrowsSpecificNamed(
         [Util loadTestFile:@"sample6"],
         RiveException,
         @"UnsupportedVersion"
    );
}

/*
 * Test loading format Flux file
 */
- (void)testLoadFlux {
    RiveFile* file = [Util loadTestFile:@"flux_capacitor"];
    RiveArtboard* artboard = [file artboard];
    XCTAssertEqual(artboard.animationCount, 1);
}

/*
 * Test loading format Buggy file
 */
- (void)testLoadBuggy {
    RiveFile* file = [Util loadTestFile:@"off_road_car_blog"];
    RiveArtboard* artboard = [file artboard];
    XCTAssertEqual(artboard.animationCount, 5);
}

@end
