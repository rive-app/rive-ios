//
//  RiveRenderer.hpp
//  RiveRuntime
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

enum class RiveGradient
{
    None,
    Linear,
    Radial
};

enum class RivePaintStyle
{
    None,
    Stroke,
    Fill
};

enum class RiveStrokeJoin
{
    None,
    Miter,
    Round,
    Bevel
};

enum class RiveStrokeCap
{
    None,
    Butt,
    Round,
    Square
};

enum class RiveBlendMode : unsigned int
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

class RiveRenderPaint : public RenderPaint
{
private:
public:
    CGColorRef cgColor = NULL;
    RivePaintStyle paintStyle = RivePaintStyle::None;
    RiveStrokeJoin strokeJoin = RiveStrokeJoin::None;
    RiveStrokeCap strokeCap = RiveStrokeCap::None;
    RiveBlendMode currentBlendMode;
    float paintThickness;

    // Gradient data
    RiveGradient gradientType = RiveGradient::None;
    CGGradientRef gradient = NULL;
    CGPoint gradientStart;
    CGPoint gradientEnd;
    std::vector<CGFloat> colorStops;
    std::vector<CGFloat> stops;

    RiveRenderPaint();
    ~RiveRenderPaint();

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

enum class RivePathCommandType
{
    MoveTo,
    LineTo,
    CubicTo,
    Reset,
    Close
};

struct RivePathCommand
{
    RivePathCommandType command;
    float x;
    float y;
    float inX;
    float inY;
    float outX;
    float outY;
};

class RiveRenderPath : public RenderPath
{
private:
    CGMutablePathRef path;
    FillRule m_FillRule;

public:
    RiveRenderPath();
    ~RiveRenderPath();

    CGMutablePathRef getPath() { return path; }
    FillRule getFillRule() { return m_FillRule; }

    void reset() override;
    void addRenderPath(RenderPath* path, const Mat2D& transform) override;
    void fillRule(FillRule value) override;
    void moveTo(float x, float y) override;
    void lineTo(float x, float y) override;
    void cubicTo(float ox, float oy, float ix, float iy, float x, float y) override;
    void close() override;
};

/*
 * Renderer
 */

class RiveRenderer : public Renderer
{
private:
    CGContextRef ctx;

public:
    RiveRenderer(CGContextRef context) : ctx(context) {}
    ~RiveRenderer();

    void save() override;
    void restore() override;
    void transform(const Mat2D& transform) override;
    void drawPath(RenderPath* path, RenderPaint* paint) override;
    void clipPath(RenderPath* path) override;
};
} // namespace rive

#endif /* rive_renderer_hpp */
