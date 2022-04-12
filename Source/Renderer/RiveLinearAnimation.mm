//
//  RiveLinearAnimation.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>

/*
 * RiveLinearAnimation
 */
@implementation RiveLinearAnimation {
    const rive::LinearAnimation *animation;
}


- (instancetype)initWithAnimation:(const rive::LinearAnimation *) riveAnimation {
    if (self = [super init]) {
        animation = riveAnimation;
        return self;
    } else {
        return nil;
    }
}

- (NSString *)name {
    std::string str = animation->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

- (RiveLinearAnimationInstance *)instanceWithArtboard:(RiveArtboard *)artboard {
    return [[RiveLinearAnimationInstance alloc] initWithAnimation:animation artboard:artboard];
}

- (NSInteger)workStart {
    return animation->workStart();
}

- (NSInteger)workEnd {
    return animation->workEnd();
}

- (NSInteger)duration {
    return animation->duration();
}

- (NSInteger)effectiveDuration {
    if (self.workStart == UINT_MAX) {
        return animation->duration();
        
    }else {
        return self.workEnd - self.workStart;
    }
}

- (float)effectiveDurationInSeconds {
    float ifps = 1.0 / animation->fps();
    return [self effectiveDuration] * ifps;
}

- (float)endTime {
    float ifps = 1.0 / animation->fps();
    if (animation->enableWorkArea()){
        return animation->workEnd() * ifps;
    }
    return animation->duration() * ifps;
}

- (NSInteger)fps {
    return animation->fps();
}

- (void)apply:(float)time to:(RiveArtboard *)artboard {
    animation->apply(artboard.artboardInstance, time);
}

- (int)loop {
    return animation->loopValue();
}

@end
