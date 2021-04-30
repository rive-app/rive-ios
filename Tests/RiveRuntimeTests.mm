//
//  RiveRuntimeTests.m
//  RiveRuntimeTests
//
//  Created by Matt Sullivan on 8/30/20.
//  Copyright © 2020 Rive. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Rive.h"
#import "RiveRenderer.hpp"

@interface RiveRuntimeTests : XCTestCase

@end

@implementation RiveRuntimeTests

UInt8 brokenRiveFileBytes[] = {
    0x05, 0x25, 0x31, 0x31, 0x31, 0xFF, 0x00, 0x1F,
    0x37, 0x0B, 0x41, 0x6E, 0x69, 0x6D, 0x61, 0x74,
    0x00, 0x7A, 0x43, 0x00
};

UInt8 pingPongRiveFileBytes[] = {
    0x52, 0x49, 0x56, 0x45, 0x07, 0x00, 0x8B, 0x94,
    0x02, 0x00, 0x17, 0x00, 0x01, 0x07, 0x00, 0x00,
    0xFA, 0x43, 0x08, 0x00, 0x00, 0xFA, 0x43, 0x04,
    0x0C, 0x4E, 0x65, 0x77, 0x20, 0x41, 0x72, 0x74,
    0x62, 0x6F, 0x61, 0x72, 0x64, 0x00, 0x03, 0x05,
    0x00, 0x0D, 0x00, 0x00, 0x7A, 0x43, 0x0E, 0x00,
    0x00, 0x7A, 0x43, 0x00, 0x07, 0x05, 0x01, 0x14,
    0xEA, 0xA3, 0xC7, 0x42, 0x15, 0xEA, 0xA3, 0xC7,
    0x42, 0x00, 0x14, 0x05, 0x01, 0x00, 0x12, 0x05,
    0x03, 0x00, 0x14, 0x05, 0x00, 0x00, 0x12, 0x05,
    0x05, 0x25, 0x31, 0x31, 0x31, 0xFF, 0x00, 0x1F,
    0x37, 0x0B, 0x41, 0x6E, 0x69, 0x6D, 0x61, 0x74,
    0x69, 0x6F, 0x6E, 0x20, 0x31, 0x39, 0x0A, 0x00,
    0x19, 0x33, 0x01, 0x00, 0x1A, 0x35, 0x0D, 0x00,
    0x1E, 0x44, 0x01, 0x46, 0xE8, 0xA3, 0x47, 0x42,
    0x00, 0x1E, 0x43, 0x0A, 0x44, 0x01, 0x46, 0x83,
    0x0B, 0xE1, 0x43, 0x00, 0x1A, 0x35, 0x0E, 0x00,
    0x1E, 0x44, 0x01, 0x46, 0x00, 0x00, 0x7A, 0x43,
    0x00, 0x1E, 0x43, 0x0A, 0x44, 0x01, 0x46, 0x00,
    0x00, 0x7A, 0x43, 0x00
};

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

/*
 * Tests creating Rive files
 */
- (void)testRiveFileCreation {
    // Valid Rive file, should not be null
    RiveFile* file = [[RiveFile alloc] initWithBytes: pingPongRiveFileBytes byteLength: 156];
    XCTAssert(file != NULL);
    
    // Invalid Rive file, should be null
    file = [[RiveFile alloc] initWithBytes: brokenRiveFileBytes byteLength: 20];
    XCTAssert(file == NULL);
}

/*
 * Tests retrieving the default artboard from Rive files
 */
- (void)testRetrieveDefaultArtboardFromRiveFile {
    RiveFile* file = [[RiveFile alloc] initWithBytes: pingPongRiveFileBytes byteLength: 156];
    RiveArtboard* artboard = [file artboard];
    XCTAssert(artboard != NULL);
    XCTAssert([[artboard name] isEqual: @"New Artboard"]);
}

/*
 * Tests retrieving artboard count from Rive files
 */
- (void)testRetrieveArtboardCountFromRiveFile {
    RiveFile* file = [[RiveFile alloc] initWithBytes: pingPongRiveFileBytes byteLength: 156];
    NSInteger count = [file artboardCount];
    XCTAssert(count == 1);
}

/*
 * Tests retrieving artboard by index
 */
- (void)testRetrieveArtboardByIndex {
    RiveFile* file = [[RiveFile alloc] initWithBytes: pingPongRiveFileBytes byteLength: 156];
    RiveArtboard* artboard = [file artboardFromIndex: 0];
    XCTAssert(artboard != NULL);
    XCTAssert([[artboard name] isEqual: @"New Artboard"]);
}

/*
 * Tests retrieving artboard by name
 */
- (void)testRetrieveArtboardByName {
    RiveFile* file = [[RiveFile alloc] initWithBytes: pingPongRiveFileBytes byteLength: 156];
    RiveArtboard* artboard = [file artboardFromName: @"New Artboard"];
    XCTAssert(artboard != NULL);
    XCTAssert([[artboard name] isEqual: @"New Artboard"]);
    
    artboard = [file artboardFromName: @"Bad Artboard"];
    XCTAssert(artboard == NULL);
}

//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
