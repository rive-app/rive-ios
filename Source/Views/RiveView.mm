//
//  RiveView.m
//  RiveRuntime
//
//  Created by Matt Sullivan on 4/29/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import "RiveView.h"
#import "RiveRenderer.hpp"

@interface RiveView()

@end

@implementation RiveView

RiveArtboard *riveArtboard;

- (void)drawRect:(CGRect)rect {
 RiveRenderer *renderer = [[RiveRenderer alloc] initWithContext:UIGraphicsGetCurrentContext()];
 [renderer alignWithRect:rect withContentRect:[riveArtboard bounds] withAlignment:Alignment::Center withFit:Fit::Contain];
 [riveArtboard draw:renderer];
}

- (void)updateArtboard:(RiveArtboard *)artboard {
 riveArtboard = artboard;
}

@end
