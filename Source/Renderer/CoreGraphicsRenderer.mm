//
//  CoreGraphicsRenderer.m
//  CoreGraphicsRenderer
//
//  Created by Matt Sullivan on 9/11/20.
//  Copyright © 2020 Rive. All rights reserved.
//

#include "CoreGraphicsRenderer.hpp"
#include "rive/renderer.hpp"

using namespace rive;

// Base color space used by the renderer
const CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();

/*
 * Render paint
 */

CoreGraphicsRenderPaint::CoreGraphicsRenderPaint()
{
    // NSLog(@"INITIALIZING A NEW RENDER PAINT");
}

CoreGraphicsRenderPaint::~CoreGraphicsRenderPaint()
{
    //    NSLog(@"Releasing paint resources");
    CGColorRelease(cgColor);
    CGGradientRelease(gradient);
}

void CoreGraphicsRenderPaint::style(RenderPaintStyle value)
{
    //    NSLog(@" --- RenderPaint::style");
    switch (value)
    {
        case RenderPaintStyle::fill:
            paintStyle = CoreGraphicsPaintStyle::Fill;
            break;
        case RenderPaintStyle::stroke:
            paintStyle = CoreGraphicsPaintStyle::Stroke;
            break;
    }
}

void CoreGraphicsRenderPaint::color(unsigned int value)
{
    //     NSLog(@" --- RenderPaint::color -> %u", value);
    CGFloat color[] = {((float)((value & 0xFF0000) >> 16)) / 0xFF,
                       ((float)((value & 0xFF00) >> 8)) / 0xFF,
                       ((float)(value & 0xFF)) / 0xFF,
                       ((float)((value & 0xFF000000) >> 24)) / 0xFF};
    CGColorRelease(cgColor);
    cgColor = CGColorCreate(baseSpace, color);
}

void CoreGraphicsRenderPaint::thickness(float value)
{
    //    NSLog(@" --- RenderPaint::thickness %.1f", value);
    paintThickness = value;
}

void CoreGraphicsRenderPaint::join(StrokeJoin value)
{
    //    NSLog(@" --- RenderPaint::join");
    switch (value)
    {
        case StrokeJoin::miter:
            strokeJoin = CoreGraphicsStrokeJoin::Miter;
            break;
        case StrokeJoin::round:
            strokeJoin = CoreGraphicsStrokeJoin::Round;
            break;
        case StrokeJoin::bevel:
            strokeJoin = CoreGraphicsStrokeJoin::Bevel;
            break;
        default:
            strokeJoin = CoreGraphicsStrokeJoin::None;
            break;
    }
}

void CoreGraphicsRenderPaint::cap(StrokeCap value)
{
    //    NSLog(@" --- RenderPaint::cap");
    switch (value)
    {
        case StrokeCap::butt:
            strokeCap = CoreGraphicsStrokeCap::Butt;
            break;
        case StrokeCap::round:
            strokeCap = CoreGraphicsStrokeCap::Round;
            break;
        case StrokeCap::square:
            strokeCap = CoreGraphicsStrokeCap::Square;
            break;
        default:
            strokeCap = CoreGraphicsStrokeCap::None;
            break;
    }
}

void CoreGraphicsRenderPaint::blendMode(BlendMode value)
{
    //    NSLog(@" --- RenderPaint::blendMode -> %d", value);
    switch (value)
    {
        case BlendMode::srcOver:
            currentBlendMode = CoreGraphicsBlendMode::SrcOver;
            break;
        case BlendMode::screen:
            currentBlendMode = CoreGraphicsBlendMode::Screen;
            break;
        case BlendMode::overlay:
            currentBlendMode = CoreGraphicsBlendMode::Overlay;
            break;
        case BlendMode::darken:
            currentBlendMode = CoreGraphicsBlendMode::Darken;
            break;
        case BlendMode::lighten:
            currentBlendMode = CoreGraphicsBlendMode::Lighten;
            break;
        case BlendMode::colorDodge:
            currentBlendMode = CoreGraphicsBlendMode::ColorDodge;
            break;
        case BlendMode::colorBurn:
            currentBlendMode = CoreGraphicsBlendMode::ColorBurn;
            break;
        case BlendMode::hardLight:
            currentBlendMode = CoreGraphicsBlendMode::HardLight;
            break;
        case BlendMode::softLight:
            currentBlendMode = CoreGraphicsBlendMode::SoftLight;
            break;
        case BlendMode::difference:
            currentBlendMode = CoreGraphicsBlendMode::Difference;
            break;
        case BlendMode::exclusion:
            currentBlendMode = CoreGraphicsBlendMode::Exclusion;
            break;
        case BlendMode::multiply:
            currentBlendMode = CoreGraphicsBlendMode::Multiply;
            break;
        case BlendMode::hue:
            currentBlendMode = CoreGraphicsBlendMode::Hue;
            break;
        case BlendMode::saturation:
            currentBlendMode = CoreGraphicsBlendMode::Saturation;
            break;
        case BlendMode::color:
            currentBlendMode = CoreGraphicsBlendMode::Color;
            break;
        case BlendMode::luminosity:
            currentBlendMode = CoreGraphicsBlendMode::Luminosity;
            break;
        default:
            break;
    }
}

/*
 * Render path
 */

CoreGraphicsRenderPath::CoreGraphicsRenderPath()
{
    //    NSLog(@"INITIALIZING A NEW RENDER PATH");
    path = CGPathCreateMutable();
}

CoreGraphicsRenderPath::~CoreGraphicsRenderPath()
{
    //    NSLog(@"Releasing path resources");
    CGPathRelease(path);
}

void CoreGraphicsRenderPath::close()
{
    // NSLog(@" --- RenderPath::close");
    CGPathCloseSubpath(path);
}

void CoreGraphicsRenderPath::rewind()
{
    //    NSLog(@" --- RenderPath::reset");
    CGPathRelease(path);
    path = CGPathCreateMutable();
}

void CoreGraphicsRenderPath::addRawPath(const RawPath& rawPath)
{
    auto pts = rawPath.points();
    auto vbs = rawPath.verbs();
    auto p = pts.data();
    for (auto v : vbs)
    {
        switch ((PathVerb)v)
        {
            case PathVerb::move:
                CGPathMoveToPoint(path, nullptr, p[0].x, p[0].y);
                p += 1;
                break;
            case PathVerb::line:
                CGPathAddLineToPoint(path, nullptr, p[0].x, p[0].y);
                p += 1;
                break;
            case PathVerb::quad:
                CGPathAddQuadCurveToPoint(
                    path, nullptr, p[0].x, p[0].y, p[1].x, p[1].y);
                p += 2;
                break;
            case PathVerb::cubic:
                CGPathAddCurveToPoint(path,
                                      nullptr,
                                      p[0].x,
                                      p[0].y,
                                      p[1].x,
                                      p[1].y,
                                      p[2].x,
                                      p[2].y);
                p += 3;
                break;
            case PathVerb::close:
                CGPathCloseSubpath(path);
                break;
        }
    }
    assert(p == pts.end());
}

void CoreGraphicsRenderPath::addRenderPath(RenderPath* path,
                                           const Mat2D& transform)
{
    //    NSLog(@" --- RenderPath::addPath");
    CGMutablePathRef pathToAdd =
        reinterpret_cast<CoreGraphicsRenderPath*>(path)->getPath();
    CGAffineTransform affineTransform = CGAffineTransformMake(transform.xx(),
                                                              transform.xy(),
                                                              transform.yx(),
                                                              transform.yy(),
                                                              transform.tx(),
                                                              transform.ty());
    CGPathAddPath(this->path, &affineTransform, pathToAdd);
}

void CoreGraphicsRenderPath::fillRule(FillRule value)
{
    //    NSLog(@" --- RenderPath::fillRule");
    m_FillRule = value;
}

void CoreGraphicsRenderPath::moveTo(float x, float y)
{
    //    NSLog(@" --- RenderPath::moveTo x %.1f, y %.1f", x, y);
    CGPathMoveToPoint(path, NULL, x, y);
}

void CoreGraphicsRenderPath::lineTo(float x, float y)
{
    //    NSLog(@" --- RenderPath::lineTo x %.1f, y %.1f", x, y);
    if (isnan(x) || isnan(y))
    {
        //        NSLog(@"Received NaN in lineTo!!!!");
        return;
    }
    CGPathAddLineToPoint(path, NULL, x, y);
}

void CoreGraphicsRenderPath::cubicTo(
    float ox, float oy, float ix, float iy, float x, float y)
{
    //    NSLog(@" --- call to RenderPath::cubicTo %.1f, %.1f, %.1f, %.1f, %.1f,
    //    %.1f, ", ox, oy, ix, iy, x, y);
    CGPathAddCurveToPoint(path, NULL, ox, oy, ix, iy, x, y);
}

/*
 * Renderer
 */

CoreGraphicsRenderer::~CoreGraphicsRenderer()
{
    //    NSLog(@"Releasing renderer c++");
}

void CoreGraphicsRenderer::save()
{
    //    NSLog(@" --- Renderer::save");
    CGContextSaveGState(ctx);
}

void CoreGraphicsRenderer::restore()
{
    //    NSLog(@" -- Renderer::restore");
    CGContextRestoreGState(ctx);
}

void CoreGraphicsRenderer::drawPath(RenderPath* path, RenderPaint* paint)
{
    //        NSLog(@" --- Renderer::drawPath path for type %d",
    //        rivePaint->paintStyle);
    CoreGraphicsRenderPaint* rivePaint =
        reinterpret_cast<CoreGraphicsRenderPaint*>(paint);
    CoreGraphicsRenderPath* rivePath =
        reinterpret_cast<CoreGraphicsRenderPath*>(path);

    // Apply the stroke join
    if (rivePaint->strokeJoin != CoreGraphicsStrokeJoin::None)
    {
        switch (rivePaint->strokeJoin)
        {
            case CoreGraphicsStrokeJoin::Miter:
                CGContextSetLineJoin(ctx, kCGLineJoinMiter);
                break;
            case CoreGraphicsStrokeJoin::Round:
                CGContextSetLineJoin(ctx, kCGLineJoinRound);
                break;
            case CoreGraphicsStrokeJoin::Bevel:
                CGContextSetLineJoin(ctx, kCGLineJoinBevel);
                break;
            default:
                break;
        }
    }

    // Apply the strokeCap
    if (rivePaint->strokeCap != CoreGraphicsStrokeCap::None)
    {
        switch (rivePaint->strokeCap)
        {
            case CoreGraphicsStrokeCap::Butt:
                CGContextSetLineCap(ctx, kCGLineCapButt);
                break;
            case CoreGraphicsStrokeCap::Round:
                CGContextSetLineCap(ctx, kCGLineCapRound);
                break;
            case CoreGraphicsStrokeCap::Square:
                CGContextSetLineCap(ctx, kCGLineCapSquare);
                break;
            default:
                break;
        }
    }

    // Apply the blend mode
    if (rivePaint->currentBlendMode != CoreGraphicsBlendMode::None)
    {
        switch (rivePaint->currentBlendMode)
        {

            case CoreGraphicsBlendMode::SrcOver:
                CGContextSetBlendMode(ctx, kCGBlendModeNormal);
                break;
            case CoreGraphicsBlendMode::Screen:
                CGContextSetBlendMode(ctx, kCGBlendModeScreen);
                break;
            case CoreGraphicsBlendMode::Overlay:
                CGContextSetBlendMode(ctx, kCGBlendModeOverlay);
                break;
            case CoreGraphicsBlendMode::Darken:
                CGContextSetBlendMode(ctx, kCGBlendModeDarken);
                break;
            case CoreGraphicsBlendMode::Lighten:
                CGContextSetBlendMode(ctx, kCGBlendModeLighten);
                break;
            case CoreGraphicsBlendMode::ColorDodge:
                CGContextSetBlendMode(ctx, kCGBlendModeColorDodge);
                break;
            case CoreGraphicsBlendMode::ColorBurn:
                CGContextSetBlendMode(ctx, kCGBlendModeColorBurn);
                break;
            case CoreGraphicsBlendMode::HardLight:
                CGContextSetBlendMode(ctx, kCGBlendModeHardLight);
                break;
            case CoreGraphicsBlendMode::SoftLight:
                CGContextSetBlendMode(ctx, kCGBlendModeSoftLight);
                break;
            case CoreGraphicsBlendMode::Difference:
                CGContextSetBlendMode(ctx, kCGBlendModeDifference);
                break;
            case CoreGraphicsBlendMode::Exclusion:
                CGContextSetBlendMode(ctx, kCGBlendModeExclusion);
                break;
            case CoreGraphicsBlendMode::Multiply:
                CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
                break;
            case CoreGraphicsBlendMode::Hue:
                CGContextSetBlendMode(ctx, kCGBlendModeHue);
                break;
            case CoreGraphicsBlendMode::Saturation:
                CGContextSetBlendMode(ctx, kCGBlendModeSaturation);
                break;
            case CoreGraphicsBlendMode::Color:
                CGContextSetBlendMode(ctx, kCGBlendModeColor);
                break;
            case CoreGraphicsBlendMode::Luminosity:
                CGContextSetBlendMode(ctx, kCGBlendModeLuminosity);
                break;
            default:
                break;
        }
    }

    // Add the path and paint it
    CGPathRef cgPath = rivePath->getPath();
    CGContextAddPath(ctx, cgPath);

    // If fill or stroke set, draw appropriately
    if (rivePaint->cgColor != NULL)
    {
        switch (rivePaint->paintStyle)
        {
            case CoreGraphicsPaintStyle::Stroke:
                CGContextSetStrokeColorWithColor(ctx, rivePaint->cgColor);
                CGContextSetLineWidth(ctx, rivePaint->paintThickness);
                CGContextDrawPath(ctx, kCGPathStroke);
                break;
            case CoreGraphicsPaintStyle::Fill:
                CGContextSetFillColorWithColor(ctx, rivePaint->cgColor);
                CGContextDrawPath(ctx, kCGPathFill);
                break;
            case CoreGraphicsPaintStyle::None:
                break;
        }
    }

    // Draw gradient
    if (rivePaint->gradientType != CoreGraphicsGradient::None)
    {
        // If the path is a stroke, then convert the path to a stroked path to
        // prevent the gradient from filling the path
        if (rivePaint->paintStyle == CoreGraphicsPaintStyle::Stroke)
        {
            CGContextSetLineWidth(ctx, rivePaint->paintThickness);
            CGContextReplacePathWithStrokedPath(ctx);
        }

        // Clip the gradient
        if (!CGContextIsPathEmpty(ctx))
            CGContextClip(ctx);

        if (rivePaint->gradientType == CoreGraphicsGradient::Linear)
        {
            CGContextDrawLinearGradient(ctx,
                                        rivePaint->gradient,
                                        rivePaint->gradientStart,
                                        rivePaint->gradientEnd,
                                        0x3);
        }
        else if (rivePaint->gradientType == CoreGraphicsGradient::Radial)
        {
            // Calculate the end radius
            float dx = rivePaint->gradientEnd.x - rivePaint->gradientStart.x;
            float dy = rivePaint->gradientEnd.y - rivePaint->gradientStart.y;
            float endRadius = sqrt(dx * dx + dy * dy);
            CGContextDrawRadialGradient(ctx,
                                        rivePaint->gradient,
                                        rivePaint->gradientStart,
                                        0,
                                        rivePaint->gradientStart,
                                        endRadius,
                                        kCGGradientDrawsBeforeStartLocation |
                                            kCGGradientDrawsAfterEndLocation);
        }

        // Now draw the path, clipping the gradient
        if (rivePaint->paintStyle == CoreGraphicsPaintStyle::Fill)
        {
            CGContextDrawPath(ctx, kCGPathFill);
        }
        else if (rivePaint->paintStyle == CoreGraphicsPaintStyle::Stroke)
        {
            CGContextDrawPath(ctx, kCGPathStroke);
        }
    }
}

void CoreGraphicsRenderer::clipPath(RenderPath* path)
{
    //        NSLog(@" --- Renderer::clipPath %@", clipPath);
    const CGPath* clipPath =
        reinterpret_cast<CoreGraphicsRenderPath*>(path)->getPath();
    CGContextAddPath(ctx, clipPath);
    if (!CGContextIsPathEmpty(ctx))
        CGContextClip(ctx);
}

void CoreGraphicsRenderer::transform(const Mat2D& transform)
{
    //    NSLog(@" --- Renderer::transform %.1f, %.1f, %.1f, %.1f, %.1f, %.1f",
    //        transform.xx(),
    //        transform.xy(),
    //        transform.yx(),
    //        transform.yy(),
    //        transform.tx(),
    //        transform.ty());

    CGContextConcatCTM(ctx,
                       CGAffineTransformMake(transform.xx(),
                                             transform.xy(),
                                             transform.yx(),
                                             transform.yy(),
                                             transform.tx(),
                                             transform.ty()));
}

/*
 * makeRenderPaint & makeRenderPath implementations
 */

namespace rive
{
RenderPath* makeRenderPath() { return new CoreGraphicsRenderPath(); }
} // namespace rive
