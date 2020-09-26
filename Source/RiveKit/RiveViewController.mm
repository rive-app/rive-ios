//
//  RiveViewController.m
//  RiveRuntime
//
//  Created by Matt Sullivan on 9/11/20.
//  Copyright © 2020 Rive. All rights reserved.
//

#import "Rive.h"
#import "RiveViewController.h"
#import "RiveView.h"

@implementation RiveViewController

NSString *_resource;
NSString *_extension;

RiveArtboard *artboard;
RiveLinearAnimationInstance *_instance;

CADisplayLink *displayLink = NULL;
CFTimeInterval lastTime = .0;


- (instancetype)initWithResource:(NSString *) resource withExtension:(NSString *)extension {
    if (self = [super init]) {
        _resource = resource;
        _extension = extension;
        return self;
    } else {
        return nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self forResource:_resource withExtension:_extension];
}

- (void) loadView {
    RiveView *riveView = [[RiveView alloc] init];
    [riveView setBackgroundColor:[UIColor blueColor]];
    self.view = riveView;
}

- (void) forResource: (NSString *) resource withExtension: (NSString *) extension {
    // load the Rive data
    NSString *filepath = [[NSBundle mainBundle] pathForResource:resource ofType:extension];
    NSError *error;
    NSData* data = [NSData dataWithContentsOfFile:filepath options:NSDataReadingUncached error:&error];
    // initialize the Rive file
    RiveFile* riveFile = [[RiveFile alloc] init];
    UInt8 *bytes = (UInt8 *) data.bytes;
    ImportResult result = [RiveFile import:bytes bytesLength:data.length toFile:riveFile];
    if (result != 0) {
        NSLog(@"Unable to import file: result code %i", (uint)result);
        return;
    }
    
    artboard = [riveFile artboard];
    // update the artboard in the view
    [(RiveView *)self.view updateArtboard: artboard];
    
    NSInteger animationCount = [artboard animationCount];
//    NSLog(@"Animation count: %d", (uint)animationcount);
    
    if (animationCount > 0) {
        RiveAnimation *animation = [artboard animationAt: 0];
        // NSLog(@"Animation name: %@", [animation name]);
        _instance = [animation instance];
        [_instance advanceBy:.0];     // advance the animation
        [_instance applyTo:artboard]; // apply to the artboard
        [artboard advanceBy:.0];      // advance the artboard
        
        [self runTimer];
    }
}

-(void) runTimer {
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

-(void) stopTimer {
    if (displayLink != NULL) {
        [displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

-(void) tick {
    if (displayLink == NULL) {
        // Something's gone wrong, clean up and bug out
        [self stopTimer];
    }
    
    double timestamp = [displayLink timestamp];
    
    // Last time needs to be set on the first tick
    if (lastTime == 0) {
        lastTime = timestamp;
    }
    
    // Calculate the time elapsed between ticks
    double elapsedTime = timestamp - lastTime;
    lastTime = timestamp;
//    NSLog(@"Timestamp: %.1f, elapsed time: %.5f, framerate %.1f", [displayLink timestamp], elapsedTime, 1. / elapsedTime);
    
    [_instance advanceBy:elapsedTime]; // advance the animation
    [_instance applyTo:artboard];      // apply to the artboard
    [artboard advanceBy:elapsedTime];  // advance the artboard
    
    [self.view setNeedsDisplay];
}
@end
