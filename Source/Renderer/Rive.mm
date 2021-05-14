//
//  RiveFile.m
//  RiveRuntime
//
//  Created by Matt Sullivan on 8/30/20.
//  Copyright © 2020 Rive. All rights reserved.
//

#import "Rive.h"
#import "RivePrivateHeaders.h"
#import "RiveRenderer.hpp"

@implementation RiveException
@end

/*
 * RiveRenderer
 */
@implementation RiveRenderer {
    CGContextRef ctx;
}

-(instancetype) initWithContext:(CGContextRef) context {
    if (self = [super init]) {
        ctx = context;
        _renderer = new rive::RiveRenderer(context);
        return self;
    } else {
        return nil;
    }
}

-(void) dealloc {
    delete _renderer;
}

-(void) alignWithRect:(CGRect)rect withContentRect:(CGRect)contentRect withAlignment:(Alignment)alignment withFit:(Fit)fit {
//    NSLog(@"Rect in align %@", NSStringFromCGRect(rect));
    
    // Calculate the AABBs
    rive::AABB frame = rive::AABB(rect.origin.x, rect.origin.y, rect.size.width + rect.origin.x, rect.size.height + rect.origin.y);
    rive::AABB content = rive::AABB(contentRect.origin.x, contentRect.origin.y, contentRect.size.width + contentRect.origin.x, contentRect.size.height + contentRect.origin.y);

    // Work out the fit
    rive::Fit riveFit;
    switch(fit) {
        case fitFill:
            riveFit = rive::Fit::fill;
            break;
        case fitContain:
            riveFit = rive::Fit::contain;
            break;
        case fitCover:
            riveFit = rive::Fit::cover;
            break;
        case fitFitHeight:
            riveFit = rive::Fit::fitHeight;
            break;
        case fitFitWidth:
            riveFit = rive::Fit::fitWidth;
            break;
        case fitScaleDown:
            riveFit = rive::Fit::scaleDown;
            break;
        case fitNone:
            riveFit = rive::Fit::none;
            break;
    }

    // Work out the alignment
    rive::Alignment riveAlignment = rive::Alignment::center;
    switch(alignment) {
        case alignmentTopLeft:
            riveAlignment = rive::Alignment::topLeft;
            break;
        case alignmentTopCenter:
            riveAlignment = rive::Alignment::topCenter;
            break;
        case alignmentTopRight:
            riveAlignment = rive::Alignment::topRight;
            break;
        case alignmentCenterLeft:
            riveAlignment = rive::Alignment::centerLeft;
            break;
        case alignmentCenter:
            riveAlignment = rive::Alignment::center;
            break;
        case alignmentCenterRight:
            riveAlignment = rive::Alignment::centerRight;
            break;
        case alignmentBottomLeft:
            riveAlignment = rive::Alignment::bottomLeft;
            break;
        case alignmentBottomCenter:
            riveAlignment = rive::Alignment::bottomCenter;
            break;
        case alignmentBottomRight:
            riveAlignment = rive::Alignment::bottomRight;
            break;
    }
    
    _renderer->align(riveFit, riveAlignment, frame, content);
}

@end
