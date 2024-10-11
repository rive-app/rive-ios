//
//  CoreGraphicsRenderer.hpp
//  CoreGraphicsRenderer
//
//  Created by Matt Sullivan on 9/11/20.
//  Copyright © 2020 Rive. All rights reserved.
//

#ifndef rive_renderer_hpp
#define rive_renderer_hpp

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <vector>
#import "rive/renderer.hpp"

namespace rive
{

/*
 * RenderPaint
 */

enum class CoreGraphicsGradient
{
    None,
    Linear,
    Radial
};

enum class CoreGraphicsPaintStyle
{
    None,
    Stroke,
    Fill
};

enum class CoreGraphicsStrokeJoin
{
    None,
    Miter,
    Round,
    Bevel
};

enum class CoreGraphicsStrokeCap
{
    None,
    Butt,
    Round,
    Square
};

enum class CoreGraphicsBlendMode : unsigned int
{
    None = 0,
    SrcOver = static_cast<int>(BlendMode::srcOver),
    Screen = static_cast<int>(BlendMode::screen),
    Overlay = static_cast<int>(BlendMode::overlay),
    Darken = static_cast<int>(BlendMode::darken),
    Lighten = static_cast<int>(BlendMode::lighten),
    ColorDodge = static_cast<int>(BlendMode::colorDodge),
    ColorBurn = static_cast<int>(BlendMode::colorBurn),
    HardLight = static_cast<int>(BlendMode::hardLight),
    SoftLight = static_cast<int>(BlendMode::softLight),
    Difference = static_cast<int>(BlendMode::difference),
    Exclusion = static_cast<int>(BlendMode::exclusion),
    Multiply = static_cast<int>(BlendMode::multiply),
    Hue = static_cast<int>(BlendMode::hue),
    Saturation = static_cast<int>(BlendMode::saturation),
    Color = static_cast<int>(BlendMode::color),
    Luminosity = static_cast<int>(BlendMode::luminosity)
};

class CoreGraphicsRenderPaint : public RenderPaint
{
private:
public:
    CGColorRef cgColor = NULL;
    CoreGraphicsPaintStyle paintStyle = CoreGraphicsPaintStyle::None;
    CoreGraphicsStrokeJoin strokeJoin = CoreGraphicsStrokeJoin::None;
    CoreGraphicsStrokeCap strokeCap = CoreGraphicsStrokeCap::None;
    CoreGraphicsBlendMode currentBlendMode;
    float paintThickness;

    // Gradient data
    CoreGraphicsGradient gradientType = CoreGraphicsGradient::None;
    CGGradientRef gradient = NULL;
    CGPoint gradientStart;
    CGPoint gradientEnd;
    std::vector<CGFloat> colorStops;
    std::vector<CGFloat> stops;

    CoreGraphicsRenderPaint();
    ~CoreGraphicsRenderPaint();

    void color(unsigned int value) override;
    void style(RenderPaintStyle value) override;
    void thickness(float value) override;
    void join(StrokeJoin value) override;
    void cap(StrokeCap value) override;
    void blendMode(BlendMode value) override;
};

/*
 * RenderPath
 */

enum class CoreGraphicsPathCommandType
{
    MoveTo,
    LineTo,
    CubicTo,
    Reset,
    Close
};

struct CoreGraphicsPathCommand
{
    CoreGraphicsPathCommandType command;
    float x;
    float y;
    float inX;
    float inY;
    float outX;
    float outY;
};

class CoreGraphicsRenderPath : public RenderPath
{
private:
    CGMutablePathRef path;
    FillRule m_FillRule;

public:
    CoreGraphicsRenderPath();
    ~CoreGraphicsRenderPath();

    CGMutablePathRef getPath() { return path; }
    FillRule getFillRule() { return m_FillRule; }

    void rewind() override;
    void addRenderPath(RenderPath* path, const Mat2D& transform) override;
    void fillRule(FillRule value) override;
    void moveTo(float x, float y) override;
    void lineTo(float x, float y) override;
    void cubicTo(float ox, float oy, float ix, float iy, float x, float y)
        override;
    void close() override;
};

/*
 * Renderer
 */

class CoreGraphicsRenderer : public Renderer
{
private:
    CGContextRef ctx;

public:
    CoreGraphicsRenderer(CGContextRef context) : ctx(context) {}
    ~CoreGraphicsRenderer();

    void save() override;
    void restore() override;
    void transform(const Mat2D& transform) override;
    void drawPath(RenderPath* path, RenderPaint* paint) override;
    void clipPath(RenderPath* path) override;
};
} // namespace rive

#endif /* rive_renderer_hpp */
