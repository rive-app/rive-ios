//
//  RiveLinearAnimationInstance.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>


static int animInstanceCount = 0;

/*
 * RiveLinearAnimationInstance
 */
@implementation RiveLinearAnimationInstance {
    rive::LinearAnimationInstance *instance;
}

- (instancetype)initWithAnimation:(rive::LinearAnimationInstance *)anim {
    [RiveLinearAnimationInstance raiseInstanceCount];
    
    if (self = [super init]) {
        instance = anim;
        return self;
    } else {
        return nil;
    }
}

- (float)time {
    return instance->time();
}

- (void)setTime:(float) time {
    instance->time(time);
}

- (bool)advanceBy:(double)elapsedSeconds {
    return instance->advanceAndApply(elapsedSeconds);
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
    std::string str = instance->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

- (void)dealloc {
    [RiveLinearAnimationInstance reduceInstanceCount];
    delete instance;
}

- (NSInteger)fps {
    return instance->fps();
}

- (NSInteger)workStart {
    return instance->animation()->workStart();
}

- (NSInteger)workEnd {
    return instance->animation()->workEnd();
}

- (NSInteger)duration {
    return instance->animation()->duration();
}

- (NSInteger)effectiveDuration {
    if (self.workStart == UINT_MAX) {
        return instance->animation()->duration();
        
    }else {
        return self.workEnd - self.workStart;
    }
}

- (float)effectiveDurationInSeconds {
    return [self effectiveDuration] / (float)instance->fps();
}

- (float)endTime {
    float fps = instance->fps();
    auto animation = instance->animation();
    if (animation->enableWorkArea()){
        return animation->workEnd() / fps;
    }
    return animation->duration() / fps;
}

- (bool)hasEnded {
    return [self time] >= [self endTime];
}

+ (int)instanceCount {
    return animInstanceCount;
}

+ (void)raiseInstanceCount {
    animInstanceCount++;
    NSLog(@"+ Animation: %d", animInstanceCount);
}

+ (void)reduceInstanceCount {
    animInstanceCount--;
    NSLog(@"- Animation: %d", animInstanceCount);
}

@end
