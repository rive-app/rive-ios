//
//  RiveConfiguration_Private.hh
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

#ifndef RiveConfiguration_Private_hh
#define RiveConfiguration_Private_hh

#import <RiveRuntime/RiveEnums.h>

#include "rive/layout.hpp"

inline rive::Fit RiveConfigurationFitCppValue(RiveConfigurationFit fit)
{
    switch (fit)
    {
        case RiveConfigurationFitFill:
            return rive::Fit::fill;
        case RiveConfigurationFitContain:
            return rive::Fit::contain;
        case RiveConfigurationFitCover:
            return rive::Fit::cover;
        case RiveConfigurationFitFitWidth:
            return rive::Fit::fitWidth;
        case RiveConfigurationFitFitHeight:
            return rive::Fit::fitHeight;
        case RiveConfigurationFitNone:
            return rive::Fit::none;
        case RiveConfigurationFitScaleDown:
            return rive::Fit::scaleDown;
        case RiveConfigurationFitLayout:
            return rive::Fit::layout;
    }

    NSCAssert(NO, @"Unexpected RiveConfigurationFit value: %ld", (long)fit);
    return rive::Fit::contain;
}

inline rive::Alignment RiveConfigurationAlignmentCppValue(
    RiveConfigurationAlignment alignment)
{
    switch (alignment)
    {
        case RiveConfigurationAlignmentTopLeft:
            return rive::Alignment::topLeft;
        case RiveConfigurationAlignmentTopCenter:
            return rive::Alignment::topCenter;
        case RiveConfigurationAlignmentTopRight:
            return rive::Alignment::topRight;
        case RiveConfigurationAlignmentCenterLeft:
            return rive::Alignment::centerLeft;
        case RiveConfigurationAlignmentCenter:
            return rive::Alignment::center;
        case RiveConfigurationAlignmentCenterRight:
            return rive::Alignment::centerRight;
        case RiveConfigurationAlignmentBottomLeft:
            return rive::Alignment::bottomLeft;
        case RiveConfigurationAlignmentBottomCenter:
            return rive::Alignment::bottomCenter;
        case RiveConfigurationAlignmentBottomRight:
            return rive::Alignment::bottomRight;
    }

    NSCAssert(NO,
              @"Unexpected RiveConfigurationAlignment value: %ld",
              (long)alignment);
    return rive::Alignment::center;
}

#endif /* RiveConfiguration_Private_hh */
