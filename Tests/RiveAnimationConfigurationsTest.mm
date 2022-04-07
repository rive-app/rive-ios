//
//  RiveAnimationConfigurationsTest.m
//  RiveRuntimeTests
//
//  Created by Maxwell Talbot on 11/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//


#import <XCTest/XCTest.h>
#import "Rive.h"
#import "util.h"

@interface RiveAnimationConfigurationsTest : XCTestCase

@end

@implementation RiveAnimationConfigurationsTest

/*
 * Test loop mode -> loop
 */
- (void)testLoop {
    RiveFile* file = [Util loadTestFile:@"animationconfigurations" error:nil];
    RiveArtboard* artboard = [file artboard:nil];

    RiveLinearAnimation* animation = [artboard animationFromName:@"loop" error:nil];

    XCTAssertEqual([animation loop], Loop::loopLoop);
}

/*
 * Test loop mode -> pingpong
 */
- (void)testPingPong {
    RiveFile* file = [Util loadTestFile:@"animationconfigurations" error:nil];
    RiveArtboard* artboard = [file artboard:nil];

    RiveLinearAnimation* animation = [artboard animationFromName:@"pingpong" error:nil];
    
    XCTAssertEqual([animation loop], Loop::loopPingPong);
}

/*
 * Test loop mode -> oneShot
 */
- (void)testOneShot {
    RiveFile* file = [Util loadTestFile:@"animationconfigurations" error:nil];
    RiveArtboard* artboard = [file artboard:nil];

    RiveLinearAnimation* animation = [artboard animationFromName:@"oneshot" error:nil];

    XCTAssertEqual([animation loop], Loop::loopOneShot);
}

/*
 * Test duration -> 1sec/ 60fps
 */
- (void)testDuration1sec60fps {
    RiveFile* file = [Util loadTestFile:@"animationconfigurations" error:nil];
    RiveArtboard* artboard = [file artboard:nil];
    
    RiveLinearAnimation* animation = [artboard animationFromName:@"1sec60fps" error:nil];

    XCTAssertEqual([animation duration], 60);
    XCTAssertEqual([animation effectiveDuration], 60);
    XCTAssertEqual([animation fps], 60);
    XCTAssertEqual([animation workStart], UINT_MAX);
    XCTAssertEqual([animation workEnd], UINT_MAX);
}

/*
 * Test duration -> 1sec/ 120fps
 */
- (void)testDuration1sec120fps {
    RiveFile* file = [Util loadTestFile:@"animationconfigurations" error:nil];
    RiveArtboard* artboard = [file artboard:nil];
    
    RiveLinearAnimation* animation = [artboard animationFromName:@"1sec120fps" error:nil];

    XCTAssertEqual([animation duration], 120);
    XCTAssertEqual([animation effectiveDuration], 120);
    XCTAssertEqual([animation fps], 120);
    XCTAssertEqual([animation workStart], UINT_MAX);
    XCTAssertEqual([animation workEnd], UINT_MAX);
}

/*
 * Test duration -> 1sec/ 60fps f30->f50
 */
- (void)testDuration1sec60fpsf30f50 {
    RiveFile* file = [Util loadTestFile:@"animationconfigurations" error:nil];
    RiveArtboard* artboard = [file artboard:nil];
    
    RiveLinearAnimation* animation = [artboard animationFromName:@"1sec60fps_f30f50" error:nil];

    XCTAssertEqual([animation duration], 60);
    XCTAssertEqual([animation effectiveDuration], 20);
    XCTAssertEqual([animation fps], 60);
    XCTAssertEqual([animation workStart], 30);
    XCTAssertEqual([animation workEnd], 50);
}

/*
 * Test duration -> 1sec/ 120fps f50->f80
 */
- (void)testDuration1sec120fpsf50f80 {
    RiveFile* file = [Util loadTestFile:@"animationconfigurations" error:nil];
    RiveArtboard* artboard = [file artboard:nil];
    
    RiveLinearAnimation* animation = [artboard animationFromName:@"1sec120fps_f50f80" error:nil];

    XCTAssertEqual([animation duration], 120);
    XCTAssertEqual([animation effectiveDuration], 30);
    XCTAssertEqual([animation fps], 120);
    XCTAssertEqual([animation workStart], 50);
    XCTAssertEqual([animation workEnd], 80);
}

@end
