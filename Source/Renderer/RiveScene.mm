//
//  RiveScene.m
//  RiveRuntime
//
//  Created by Zachary Duncan on 6/16/22.
//  Copyright © 2022 Rive. All rights reserved.
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

- (bool)advanceBy:(double)elapsedSeconds {
    return instance->advanceAndApply(elapsedSeconds);
}

- (void)draw:(rive::Renderer *)renderer {
    instance->draw(renderer);
}

- (void)dealloc {
    delete instance;
}

@end
