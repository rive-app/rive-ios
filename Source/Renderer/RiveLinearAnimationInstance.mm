//
//  RiveLinearAnimationInstance.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>

/*
 * RiveLinearAnimationInstance
 */
@implementation RiveLinearAnimationInstance {
    rive::LinearAnimationInstance *instance;
}

- (instancetype)initWithAnimation:(const rive::LinearAnimation *)riveAnimation {
    if (self = [super init]) {
        instance = new rive::LinearAnimationInstance(riveAnimation);
        return self;
    } else {
        return nil;
    }
}

- (RiveLinearAnimation *)animation {
    const rive::LinearAnimation *linearAnimation = instance->animation();
    return [[RiveLinearAnimation alloc] initWithAnimation: linearAnimation];
}

- (float)time {
    return instance->time();
}

- (void)setTime:(float) time {
    instance->time(time);
}

- (void)applyTo:(RiveArtboard*) artboard {
    instance->apply(artboard.artboard);
}

- (bool)advanceBy:(double)elapsedSeconds {
    return instance->advance(elapsedSeconds);
}
- (void)direction:(int)direction {
    instance->direction(direction);
}
- (int)direction {
    return instance->direction();
}

- (int)loop {
    return instance->loopValue();
}

- (void)loop:(int)loopType {
    instance->loopValue(loopType);
}

- (bool)didLoop {
    return instance->didLoop();
}

- (NSString *)name {
    std::string str = instance->animation()->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

- (void)dealloc {
    delete instance;
}

@end
