//
//  RiveScene.m
//  RiveRuntime
//
//  Created by Zachary Duncan on 6/16/22.
//  Copyright © 2022 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>

@implementation RiveScene


/// StateMachine and Animation instance classes must override this
- (rive::Scene *)instance {
    [NSException raise:@"NotImplemented" format:@"Scene implementation must be overriden"];
    return nil;
}

- (NSString *)name {
    std::string str = [self instance]->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

- (CGRect)bounds {
    rive::AABB aabb = [self instance]->bounds();
    return CGRectMake(aabb.minX, aabb.minY, aabb.width(), aabb.height());
}

- (bool)advanceBy:(double)elapsedSeconds {
    return [self instance]->advanceAndApply(elapsedSeconds);
}

- (void)draw:(rive::Renderer *)renderer {
    [self instance]->draw(renderer);
}

@end
