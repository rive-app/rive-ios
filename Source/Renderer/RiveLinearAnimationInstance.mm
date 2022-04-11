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

- (instancetype)initWithAnimationInstance:(const rive::LinearAnimationInstance *)instance {
    if (self = [super init]) {
        instance = instance;
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

- (void)apply {
    instance->apply();
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

- (NSInteger)fps {
    return instance->fps();
}

- (float)endTime {
    return 0;
    /*
    if (instance->enableWorkArea()){
        return instance->workEnd()/instance->fps();
    }
    return instance->duration()/instance->fps();
     */
}

- (NSString *)name {
    std::string str = instance->animation()->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

- (void)dealloc {
    delete instance;
}

@end
