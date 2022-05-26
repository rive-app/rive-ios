//
//  RiveLinearAnimationInstance.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>

@implementation RiveScene {
    rive::Scene *instance;
}

- (instancetype)initWithScene:(rive::Scene *)scene {
    if (self = [super init]) {
        instance = scene;
        return self;
    } else {
        return nil;
    }
}

- (NSString *)name {
    std::string str = instance->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

- (CGRect)bounds {
    rive::AABB aabb = instance->bounds();
    return CGRectMake(aabb.minX, aabb.minY, aabb.width(), aabb.height());
}

- (void)draw:(RiveRenderer *)renderer {
    instance->draw([renderer renderer]);
}

- (void)dealloc {
    delete instance;
}

@end
