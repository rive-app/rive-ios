//
//  RiveRenderer.m
//  RiveRuntime
//
//  Created by Matt Sullivan on 9/11/20.
//  Copyright © 2020 Rive. All rights reserved.
//


#include "RiveRenderer.hpp"
#include "renderer.hpp"

// Creates a UIColor from an RGBA int value
#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/0xFF \
         green:((float)((rgbValue & 0xFF00) >> 8))/0xFF \
         blue:((float)(rgbValue & 0xFF))/0xFF \
         alpha:((float)((rgbValue & 0xFF000000) >> 24))/0xFF]

#define opacityFromARGB(rgbValue) ((float)((rgbValue & 0xFF000000) >> 24))/0xFF

using namespace rive;

// Base color space used throughout the renderer
const CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();

/*
 * Render paint
 */

RiveRenderPaint::RiveRenderPaint() {
    // NSLog(@"INITIALIZING A NEW RENDER PAINT");
}

void RiveRenderPaint::style(RenderPaintStyle value) {
//    NSLog(@" --- RenderPaint::style");
    switch(value) {
        case RenderPaintStyle::fill:
            paintStyle = RivePaintStyle::Fill;
            break;
        case RenderPaintStyle::stroke:
//            NSLog(@"Ask for stroke");
            paintStyle = RivePaintStyle::Stroke;
            break;
    }
}

void RiveRenderPaint::color(unsigned int value) {
    // NSLog(@" --- RenderPaint::color -> %u", value);
    CGFloat color [] = {
        ((float)((value & 0xFF0000) >> 16))/0xFF,
        ((float)((value & 0xFF00) >> 8))/0xFF,
        ((float)(value & 0xFF))/0xFF,
        ((float)((value & 0xFF000000) >> 24))/0xFF
    };
    cgColor = CGColorCreate(baseSpace, color);
}

void RiveRenderPaint::thickness(float value) {
//    NSLog(@" --- RenderPaint::thickness %.1f", value);
    paintThickness = value;
}

void RiveRenderPaint::join(StrokeJoin value) {
//    NSLog(@" --- RenderPaint::join");
    switch(value) {
        case StrokeJoin::miter:
            strokeJoin = RiveStrokeJoin::Miter;
            break;
        case StrokeJoin::round:
            strokeJoin = RiveStrokeJoin::Round;
            break;
        case StrokeJoin::bevel:
            strokeJoin = RiveStrokeJoin::Bevel;
            break;
        default:
            strokeJoin = RiveStrokeJoin::None;
            break;
    }
}

void RiveRenderPaint::cap(StrokeCap value) {
//    NSLog(@" --- RenderPaint::cap");
    switch (value) {
        case StrokeCap::butt:
            strokeCap = RiveStrokeCap::Butt;
            break;
        case StrokeCap::round:
            strokeCap = RiveStrokeCap::Round;
            break;
        case StrokeCap::square:
            strokeCap = RiveStrokeCap::Square;
            break;
        default:
            strokeCap = RiveStrokeCap::None;
            break;
    }
}

void RiveRenderPaint::blendMode(BlendMode value) {
//    NSLog(@" --- RenderPaint::blendMode -> %d", value);
    switch (value) {
        case BlendMode::srcOver:
            currentBlendMode = RiveBlendMode::SrcOver;
            break;
        case BlendMode::screen:
            currentBlendMode = RiveBlendMode::Screen;
            break;
        case BlendMode::overlay:
            currentBlendMode = RiveBlendMode::Overlay;
            break;
        case BlendMode::darken:
            currentBlendMode = RiveBlendMode::Darken;
            break;
        case BlendMode::lighten:
            currentBlendMode = RiveBlendMode::Lighten;
            break;
        case BlendMode::colorDodge:
            currentBlendMode = RiveBlendMode::ColorDodge;
            break;
        case BlendMode::colorBurn:
            currentBlendMode = RiveBlendMode::ColorBurn;
            break;
        case BlendMode::hardLight:
            currentBlendMode = RiveBlendMode::HardLight;
            break;
        case BlendMode::softLight:
            currentBlendMode = RiveBlendMode::SoftLight;
            break;
        case BlendMode::difference:
            currentBlendMode = RiveBlendMode::Difference;
            break;
        case BlendMode::exclusion:
            currentBlendMode = RiveBlendMode::Exclusion;
            break;
        case BlendMode::multiply:
            currentBlendMode = RiveBlendMode::Multiply;
            break;
        case BlendMode::hue:
            currentBlendMode = RiveBlendMode::Hue;
            break;
        case BlendMode::saturation:
            currentBlendMode = RiveBlendMode::Saturation;
            break;
        case BlendMode::color:
            currentBlendMode = RiveBlendMode::Color;
            break;
        case BlendMode::luminosity:
            currentBlendMode = RiveBlendMode::Luminosity;
            break;
        default:
            break;
    }
}

void RiveRenderPaint::linearGradient(float sx, float sy, float ex, float ey) {
//    NSLog(@" --- RenderPaint::linearGradient (%.1f,%.1f), (%.1f,%.1f)", sx, sy, ex, ey);
    gradientType = RiveGradient::Linear;
    gradientStart = CGPointMake(sx, sy);
    gradientEnd = CGPointMake(ex, ey);
    
    // clear out the stops
    stops.clear();
    colorStops.clear();
    
}
void RiveRenderPaint::radialGradient(float sx, float sy, float ex, float ey) {
//    NSLog(@" --- RenderPaint::radialGradient");
    gradientType = RiveGradient::Radial;
    gradientStart = CGPointMake(sx, sy);
    gradientEnd = CGPointMake(ex, ey);
    
    // clear out the stops
    stops.clear();
    colorStops.clear();
}

void RiveRenderPaint::addStop(unsigned int color, float stop) {
//    NSLog(@" --- RenderPaint::addStop - color %i at %.01f", color, stop);
    colorStops.emplace_back(((float)((color & 0xFF0000) >> 16))/0xFF);
    colorStops.emplace_back(((float)((color & 0xFF00) >> 8))/0xFF);
    colorStops.emplace_back(((float)(color & 0xFF))/0xFF);
    colorStops.emplace_back(((float)((color & 0xFF000000) >> 24))/0xFF);
    stops.emplace_back(stop);
}
void RiveRenderPaint::completeGradient() {
//    NSLog(@" --- RenderPaint::completeGradient");
    if (gradient != NULL) {
        CGGradientRelease(gradient); gradient = NULL;
    }
    gradient = CGGradientCreateWithColorComponents(baseSpace, &colorStops[0], &stops[0], stops.size());
}

/*
 * Render path
 */

RiveRenderPath::RiveRenderPath() {
    path = [[UIBezierPath alloc] init];
//    NSLog(@"INITIALIZING A NEW RENDER PATH");
}

void RiveRenderPath::close() {
    // NSLog(@" --- RenderPath::close");
    [path closePath];
}

void RiveRenderPath::reset() {
//    NSLog(@" --- RenderPath::reset");
    path = [[UIBezierPath alloc] init];
    // [path removeAllPoints];
}

void RiveRenderPath::addPath(CommandPath* path, const Mat2D& transform) {
//    NSLog(@" --- RenderPath::addPath");
    UIBezierPath *addPath = reinterpret_cast<RiveRenderPath *>(path)->getBezierPath();
    
    CGAffineTransform affineTransform = CGAffineTransformMake(transform.xx(),
                                                              transform.xy(),
                                                              transform.yx(),
                                                              transform.yy(),
                                                              transform.tx(),
                                                              transform.ty());
    
    UIBezierPath *clonePath = [addPath copy];
    
    [clonePath applyTransform:affineTransform];
    [this->path appendPath:clonePath];
}
    
void RiveRenderPath::fillRule(FillRule value) {
//    NSLog(@" --- RenderPath::fillRule");
    m_FillRule = value;
}
    
void RiveRenderPath::moveTo(float x, float y) {
//    NSLog(@" --- RenderPath::moveTo x %.1f, y %.1f", x, y);
    [path moveToPoint:CGPointMake(x, y)];
}

void RiveRenderPath::lineTo(float x, float y) {
//    NSLog(@" --- RenderPath::lineTo x %.1f, y %.1f", x, y);
    if (isnan(x) || isnan(y)) {
        NSLog(@"Received NaN in lineTo!!!!");
        return;
    }
    [path addLineToPoint:CGPointMake(x, y)];
}
    
void RiveRenderPath::cubicTo(float ox, float oy, float ix, float iy, float x, float y) {
//    NSLog(@" --- call to RenderPath::cubicTo %.1f, %.1f, %.1f, %.1f, %.1f, %.1f, ", ox, oy, ix, iy, x, y);
    [path addCurveToPoint:CGPointMake(x, y)
                controlPoint1:CGPointMake(ox, oy)
                controlPoint2:CGPointMake(ix, iy)
    ];
}

// Renderer

// Implement save by creating a sublayer
void RiveRenderer::save() {
//    NSLog(@" --- Renderer::save");
    CGContextSaveGState(ctx);
}

// Implement restore by moving back up to the parent layer. If the parent
// layer is ctx, then there's been a restore without a save
void RiveRenderer::restore() {
//    NSLog(@" -- Renderer::restore");
    CGContextRestoreGState(ctx);
}

void RiveRenderer::drawPath(RenderPath* path, RenderPaint* paint) {

    RiveRenderPaint *rivePaint = reinterpret_cast<RiveRenderPaint *>(paint);
    RiveRenderPath *rivePath = reinterpret_cast<RiveRenderPath *>(path);
    
//    NSLog(@" --- Renderer::drawPath path for type %d", rivePaint->paintStyle);
    
    // Apply the stroke join
    if (rivePaint->strokeJoin != RiveStrokeJoin::None) {
        switch(rivePaint->strokeJoin) {
            case RiveStrokeJoin::Miter:
                CGContextSetLineJoin(ctx, kCGLineJoinMiter);
                break;
            case RiveStrokeJoin::Round:
                CGContextSetLineJoin(ctx, kCGLineJoinRound);
                break;
            case RiveStrokeJoin::Bevel:
                CGContextSetLineJoin(ctx, kCGLineJoinBevel);
                break;
            default:
                break;
        }
    }
    
    // Apply the strokeCap
    if (rivePaint->strokeCap != RiveStrokeCap::None) {
        switch (rivePaint->strokeCap) {
            case RiveStrokeCap::Butt:
                CGContextSetLineCap(ctx, kCGLineCapButt);
                break;
            case RiveStrokeCap::Round:
                CGContextSetLineCap(ctx, kCGLineCapRound);
                break;
            case RiveStrokeCap::Square:
                CGContextSetLineCap(ctx, kCGLineCapSquare);
                break;
            default:
                break;
        }
    }
        
    // Apply the blend mode
    if (rivePaint->currentBlendMode != RiveBlendMode::None) {
        switch (rivePaint->currentBlendMode) {
            case RiveBlendMode::SrcOver:
                CGContextSetBlendMode(ctx, kCGBlendModeNormal);
                break;
            case RiveBlendMode::Screen:
                CGContextSetBlendMode(ctx, kCGBlendModeScreen);
                break;
            case RiveBlendMode::Overlay:
                CGContextSetBlendMode(ctx, kCGBlendModeOverlay);
                break;
            case RiveBlendMode::Darken:
                CGContextSetBlendMode(ctx, kCGBlendModeDarken);
                break;
            case RiveBlendMode::Lighten:
                CGContextSetBlendMode(ctx, kCGBlendModeLighten);
                break;
            case RiveBlendMode::ColorDodge:
                CGContextSetBlendMode(ctx, kCGBlendModeColorDodge);
                break;
            case RiveBlendMode::ColorBurn:
                CGContextSetBlendMode(ctx, kCGBlendModeColorBurn);
                break;
            case RiveBlendMode::HardLight:
                CGContextSetBlendMode(ctx, kCGBlendModeHardLight);
                break;
            case RiveBlendMode::SoftLight:
                CGContextSetBlendMode(ctx, kCGBlendModeSoftLight);
                break;
            case RiveBlendMode::Difference:
                CGContextSetBlendMode(ctx, kCGBlendModeDifference);
                break;
            case RiveBlendMode::Exclusion:
                CGContextSetBlendMode(ctx, kCGBlendModeExclusion);
                break;
            case RiveBlendMode::Multiply:
                CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
                break;
            case RiveBlendMode::Hue:
                CGContextSetBlendMode(ctx, kCGBlendModeHue);
                break;
            case RiveBlendMode::Saturation:
                CGContextSetBlendMode(ctx, kCGBlendModeSaturation);
                break;
            case RiveBlendMode::Color:
                CGContextSetBlendMode(ctx, kCGBlendModeColor);
                break;
            case RiveBlendMode::Luminosity:
                CGContextSetBlendMode(ctx, kCGBlendModeLuminosity);
                break;
            default:
                break;
        }
    }
        
    // Add the path and then paint it appropriately
    CGPathRef cgPath = rivePath->getBezierPath().CGPath;
    CGContextAddPath(ctx, cgPath);
    
    // If fill or stroke set, draw appropriately
    if (rivePaint->cgColor != NULL) {
        switch (rivePaint->paintStyle) {
            case RivePaintStyle::Stroke:
//                NSLog(@"Painting stroke");
                CGContextSetStrokeColorWithColor(ctx, rivePaint->cgColor);
                CGContextSetLineWidth(ctx, rivePaint->paintThickness);
                CGContextDrawPath(ctx, kCGPathStroke);
                break;
            case RivePaintStyle::Fill:
//                NSLog(@"Painting fill");
                CGContextSetFillColorWithColor(ctx, rivePaint->cgColor);
                CGContextDrawPath(ctx, kCGPathFill);
                break;
            case RivePaintStyle::None:
                break;
            default:
                break;
        }
    } else {
//        NSLog(@"Color is null!!!");
    }
    
    // Draw gradient
    if (rivePaint->gradientType != RiveGradient::None) {
//        NSLog(@"Drawing a gradient");
//        CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, &rivePaint->colorStops[0], &rivePaint->stops[0], rivePaint->stops.size());
        
        // If the path is a stroke, then convert the path to a stroked path to prevent the gradient from filling the path
        if (rivePaint->paintStyle == RivePaintStyle::Stroke) {
            CGContextSetLineWidth(ctx, rivePaint->paintThickness);
            CGContextReplacePathWithStrokedPath(ctx);
        }
        CGContextClip(ctx);
            
        if (rivePaint->gradientType == RiveGradient::Linear) {
            CGContextDrawLinearGradient(ctx, rivePaint->gradient, rivePaint->gradientStart, rivePaint->gradientEnd,  0x3);
        } else if (rivePaint->gradientType == RiveGradient:: Radial) {
            // Calculate the end radius
            float dx = rivePaint->gradientEnd.x - rivePaint->gradientStart.x;
            float dy = rivePaint->gradientEnd.y - rivePaint->gradientStart.y;
            float endRadius = sqrt(dx*dx + dy*dy);
            CGContextDrawRadialGradient(ctx, rivePaint->gradient, rivePaint->gradientStart, 0, rivePaint->gradientStart, endRadius, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        }

        if (rivePaint->paintStyle == RivePaintStyle::Fill) {
            CGContextDrawPath(ctx, kCGPathFill);
        } else if (rivePaint->paintStyle == RivePaintStyle::Stroke) {
            CGContextDrawPath(ctx, kCGPathStroke);
        }
    }
}

void RiveRenderer::clipPath(RenderPath* path) {
    const CGPath *clipPath = reinterpret_cast<RiveRenderPath *>(path)->getBezierPath().CGPath;
//    NSLog(@" --- Renderer::clipPath %@", clipPath);
    
    CGContextAddPath(ctx, clipPath);
    CGContextClip(ctx);
}

void RiveRenderer::transform(const Mat2D& transform) {
//    NSLog(@" --- Renderer::transform %.1f, %.1f, %.1f, %.1f, %.1f, %.1f",
//        transform.xx(),
//        transform.xy(),
//        transform.yx(),
//        transform.yy(),
//        transform.tx(),
//        transform.ty());
    
    CGContextConcatCTM(ctx, CGAffineTransformMake(transform.xx(),
                                                  transform.xy(),
                                                  transform.yx(),
                                                  transform.yy(),
                                                  transform.tx(),
                                                  transform.ty()));
}

/*
 * makeRenderPaint & makeRenderPath implementations
 */

namespace rive {
    RenderPaint* makeRenderPaint() { return new RiveRenderPaint(); }

    RenderPath* makeRenderPath() { return new RiveRenderPath(); }
}
