//
//  RiveArtboardLoadTest.m
//  RiveRuntimeTests
//
//  Created by Maxwell Talbot on 11/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Rive.h"
#import "util.h"

@interface RiveArtboardLoadTest : XCTestCase

@end

@implementation RiveArtboardLoadTest

/*
 * Test loading multiple artboards
 */
- (void)testLoadArtboard
{
    RiveFile* file = [Util loadTestFile:@"multipleartboards" error:nil];

    XCTAssertEqual([file artboardCount], 2);

    XCTAssertEqual([[file artboardFromIndex:1 error:nil] name],
                   [[file artboardFromName:@"artboard1" error:nil] name]);
    XCTAssertEqual([[file artboardFromIndex:0 error:nil] name],
                   [[file artboardFromName:@"artboard2" error:nil] name]);

    NSArray* target = [NSArray arrayWithObjects:@"artboard2", @"artboard1", nil];
    XCTAssertTrue([[file artboardNames] isEqualToArray:target]);
}

/*
 * Test no animations
 */
- (void)testNoArtboard
{
    RiveFile* file = [Util loadTestFile:@"noartboard" error:nil];

    XCTAssertEqual([file artboardCount], 0);
    XCTAssertTrue([[file artboardNames] isEqualToArray:[NSArray array]]);
}

/*
 * Test access first
 */
- (void)testNoArtboardAccessFirst
{
    RiveFile* file = [Util loadTestFile:@"noartboard" error:nil];

    NSError* error = nil;
    RiveArtboard* artboard = [file artboard:&error];

    XCTAssertNil(artboard);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects([error domain], @"rive.app.ios.runtime");
    XCTAssertEqual([error code], 100);
    XCTAssertEqualObjects([[error userInfo] valueForKey:@"name"], @"NoArtboardsFound");
}

/*
 * Test access index doesnt exist
 */
- (void)testNoArtboardAccessFromIndex
{
    RiveFile* file = [Util loadTestFile:@"noartboard" error:nil];

    NSError* error = nil;
    RiveArtboard* artboard = [file artboardFromIndex:0 error:&error];

    XCTAssertNil(artboard);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects([error domain], @"rive.app.ios.runtime");
    XCTAssertEqual([error code], 101);
    XCTAssertEqualObjects([[error userInfo] valueForKey:@"name"], @"NoArtboardFound");
}

/*
 * Test access name doesnt exist
 */
- (void)testNoArtboardAccessFromName
{
    RiveFile* file = [Util loadTestFile:@"noartboard" error:nil];

    NSError* error = nil;
    RiveArtboard* artboard = [file artboardFromName:@"boo" error:&error];

    XCTAssertNil(artboard);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects([error domain], @"rive.app.ios.runtime");
    XCTAssertEqual([error code], 101);
    XCTAssertEqualObjects([[error userInfo] valueForKey:@"name"], @"NoArtboardFound");
}

/*
 * Test access a bunch of artboards
 */
- (void)testLoadArtboardsForEachShape
{
    RiveFile* file = [Util loadTestFile:@"shapes" error:nil];

    [file artboardFromName:@"rect" error:nil];
    [file artboardFromName:@"ellipse" error:nil];
    [file artboardFromName:@"triangle" error:nil];
    [file artboardFromName:@"polygon" error:nil];
    [file artboardFromName:@"star" error:nil];
    [file artboardFromName:@"pen" error:nil];
    [file artboardFromName:@"groups" error:nil];
    [file artboardFromName:@"bone" error:nil];
}

@end
