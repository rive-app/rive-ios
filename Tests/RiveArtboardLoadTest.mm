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
- (void)testLoadArtboard {
    RiveFile* file = [Util loadTestFile:@"multipleartboards"];
    
    XCTAssertEqual([file artboardCount], 2);
    
    XCTAssertEqual([[file artboardFromIndex:1] name], [[file artboardFromName:@"artboard1"] name]);
    XCTAssertEqual([[file artboardFromIndex:0] name], [[file artboardFromName:@"artboard2"] name]);
    
    
    NSArray *target = [NSArray arrayWithObjects:@"artboard2", @"artboard1", nil];
    XCTAssertTrue([[file artboardNames] isEqualToArray: target]);
}

/*
 * Test no animations
 */
- (void)testNoArtboard {
    RiveFile* file = [Util loadTestFile:@"noartboard"];

    XCTAssertEqual([file artboardCount], 0);
    XCTAssertTrue([[file artboardNames] isEqualToArray: [NSArray array]]);
}

/*
 * Test access first
 */
- (void)testNoArtboardAccessFirst {
    RiveFile* file = [Util loadTestFile:@"noartboard"];
    
    XCTAssertThrowsSpecificNamed(
         [file artboard],
         RiveException,
         @"NoArtboardsFound"
    );
}

/*
 * Test access index doesnt exist
 */
- (void)testNoArtboardAccessFromIndex {
    RiveFile* file = [Util loadTestFile:@"noartboard"];
    
    XCTAssertThrowsSpecificNamed(
         [file artboardFromIndex:0],
         RiveException,
         @"NoArtboardFound"
    );
}

/*
 * Test access name doesnt exist
 */
- (void)testNoArtboardAccessFromName {
    RiveFile* file = [Util loadTestFile:@"noartboard"];
    
    XCTAssertThrowsSpecificNamed(
         [file artboardFromName:@"boo"],
         RiveException,
         @"NoArtboardFound"
    );
}

/*
 * Test access a bunch of artboards
 */
- (void)testLoadArtboardsForEachShape {
    RiveFile* file = [Util loadTestFile:@"shapes"];
    
    [file artboardFromName:@"rect"];
    [file artboardFromName:@"ellipse"];
    [file artboardFromName:@"triangle"];
    [file artboardFromName:@"polygon"];
    [file artboardFromName:@"star"];
    [file artboardFromName:@"pen"];
    [file artboardFromName:@"groups"];
    [file artboardFromName:@"bone"];
}

@end
