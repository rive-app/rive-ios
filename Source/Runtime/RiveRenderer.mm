//
//  RiveRenderer.m
//  RiveRuntime
//
//  Created by Matt Sullivan on 8/31/20.
//  Copyright © 2020 Rive. All rights reserved.
//

#import "RiveRenderer.h"


@implementation RiveRenderer

//iOSRenderer *renderer;
UIBezierPath *renderContext;

-(instancetype) initWithContext:(UIBezierPath *) context {
    if (self = [super init]) {
        renderContext = context;
        return self;
    } else {
        return nil;
    }
}

@end
