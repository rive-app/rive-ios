//
//  RiveUIEnums.h
//  RiveRuntime
//
//  Created by David Skuza on 9/16/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#ifndef RiveEnums_h
#define RiveEnums_h

#import <Foundation/Foundation.h>

/// Defines how an artboard should be fitted within its container bounds.
///
/// The fit is applied during rendering and also affects how pointer events are
/// transformed from screen coordinates to artboard coordinates.
typedef NS_ENUM(NSInteger, RiveConfigurationFit) {
    /// Scales the artboard to fill the entire container, potentially cropping.
    /// The artboard maintains its aspect ratio.
    RiveConfigurationFitFill = 0,

    /// Scales the artboard to fit entirely within the container without
    /// cropping.
    /// The artboard maintains its aspect ratio and may have letterboxing.
    RiveConfigurationFitContain,

    /// Scales the artboard to cover the entire container, potentially cropping.
    /// Similar to Fill but may crop differently based on aspect ratio.
    RiveConfigurationFitCover,

    /// Scales the artboard to fit the container width, height may be cropped.
    /// The artboard's width matches the container width.
    RiveConfigurationFitFitWidth,

    /// Scales the artboard to fit the container height, width may be cropped.
    /// The artboard's height matches the container height.
    RiveConfigurationFitFitHeight,

    /// No scaling is applied. The artboard is drawn at its original size.
    /// May be clipped if the container is smaller than the artboard.
    RiveConfigurationFitNone,

    /// Scales down only if the artboard is larger than the container.
    /// If the artboard is smaller, it's drawn at original size (like None).
    RiveConfigurationFitScaleDown,

    /// Uses the layout constraints defined in the Rive file.
    /// The artboard respects layout rules and may resize based on constraints.
    RiveConfigurationFitLayout
};

/// Defines how an artboard should be aligned within its container when there's
/// extra space.
///
/// Alignment is used in conjunction with fit modes to position the artboard
/// when the fit mode results in the artboard being smaller than the container
/// (e.g., with RiveConfigurationFitContain or RiveConfigurationFitScaleDown).
///
/// The alignment affects both rendering and pointer event coordinate
/// transformation.
typedef NS_ENUM(NSInteger, RiveConfigurationAlignment) {
    /// Aligns the artboard to the top-left corner of the container.
    RiveConfigurationAlignmentTopLeft = 0,

    /// Aligns the artboard to the top-center of the container.
    RiveConfigurationAlignmentTopCenter,

    /// Aligns the artboard to the top-right corner of the container.
    RiveConfigurationAlignmentTopRight,

    /// Aligns the artboard to the center-left of the container.
    RiveConfigurationAlignmentCenterLeft,

    /// Aligns the artboard to the center of the container (both horizontally
    /// and vertically).
    RiveConfigurationAlignmentCenter,

    /// Aligns the artboard to the center-right of the container.
    RiveConfigurationAlignmentCenterRight,

    /// Aligns the artboard to the bottom-left corner of the container.
    RiveConfigurationAlignmentBottomLeft,

    /// Aligns the artboard to the bottom-center of the container.
    RiveConfigurationAlignmentBottomCenter,

    /// Aligns the artboard to the bottom-right corner of the container.
    RiveConfigurationAlignmentBottomRight
};

/// Error codes that can be returned by the renderer when drawing operations
/// fail.
///
/// These errors indicate invalid parameters or state when attempting to draw
/// Rive content. They are typically delivered via error callbacks in drawing
/// operations.
typedef NS_ENUM(NSInteger, RendererError) {
    /// The provided size is invalid (e.g., zero width or height).
    RendererErrorInvalidSize = 1,

    /// The renderer instance is invalid or has been deallocated.
    RendererErrorInvalidRenderer,

    /// The artboard handle is invalid or the artboard has been deleted.
    RendererErrorInvalidArtboard,

    /// The state machine handle is invalid or the state machine has been
    /// deleted.
    RendererErrorInvalidStateMachine,
};

/// Data types used for view model instance properties.
///
/// This enum maps to the C++ rive::DataType enum values via a conversion
/// function.
typedef NS_ENUM(NSInteger, RiveViewModelInstanceDataType) {
    /// None.
    RiveViewModelInstanceDataTypeNone,

    /// String.
    RiveViewModelInstanceDataTypeString,

    /// Number.
    RiveViewModelInstanceDataTypeNumber,

    /// Boolean.
    RiveViewModelInstanceDataTypeBoolean,

    /// Color.
    RiveViewModelInstanceDataTypeColor,

    /// List.
    RiveViewModelInstanceDataTypeList,

    /// Enum.
    RiveViewModelInstanceDataTypeEnum,

    /// Trigger.
    RiveViewModelInstanceDataTypeTrigger,

    /// View Model.
    RiveViewModelInstanceDataTypeViewModel,

    /// Integer.
    RiveViewModelInstanceDataTypeInteger,

    /// Symbol list index.
    RiveViewModelInstanceDataTypeSymbolListIndex,

    /// Asset Image.
    RiveViewModelInstanceDataTypeAssetImage,

    /// Asset Font.
    RiveViewModelInstanceDataTypeAssetFont,

    /// Artboard.
    RiveViewModelInstanceDataTypeArtboard,

    /// Special case, this type is used to indicate it uses the input type.
    RiveViewModelInstanceDataTypeInput,
    /// Any type (used for type checking).
    RiveViewModelInstanceDataTypeAny
};

/// The type of semantic action to fire on a semantic node.
typedef NS_ENUM(NSInteger, RiveSemanticActionType) {
    /// Primary activation (click/press).
    RiveSemanticActionTypeTap = 0,
    /// Step up / increment.
    RiveSemanticActionTypeIncrease = 1,
    /// Step down / decrement.
    RiveSemanticActionTypeDecrease = 2,
} NS_SWIFT_NAME(SemanticActionType);

/// The semantic role of an accessibility node.
typedef NS_ENUM(NSInteger, RiveSemanticRole) {
    RiveSemanticRoleNone = 0,
    RiveSemanticRoleButton = 1,
    RiveSemanticRoleLink = 2,
    RiveSemanticRoleCheckbox = 3,
    RiveSemanticRoleSwitchControl = 4,
    RiveSemanticRoleSlider = 5,
    RiveSemanticRoleTextField = 6,
    RiveSemanticRoleText = 7,
    RiveSemanticRoleImage = 8,
    RiveSemanticRoleGroup = 9,
    RiveSemanticRoleList = 10,
    RiveSemanticRoleListItem = 11,
    RiveSemanticRoleTab = 12,
    RiveSemanticRoleTabList = 13,
    RiveSemanticRoleDialog = 14,
    RiveSemanticRoleAlertDialog = 15,
    RiveSemanticRoleRadioGroup = 16,
    RiveSemanticRoleRadioButton = 17,
} NS_SWIFT_NAME(SemanticRole);

/// Bitmask of semantic traits declaring what capabilities a node has.
///
/// Traits solve the tristate problem: a state flag is only meaningful when its
/// corresponding trait is set. Without the trait, the state is not applicable.
typedef NS_OPTIONS(NSUInteger, RiveSemanticTrait) {
    RiveSemanticTraitNone = 0,
    RiveSemanticTraitExpandable = 1u << 0,
    RiveSemanticTraitSelectable = 1u << 1,
    RiveSemanticTraitCheckable = 1u << 2,
    RiveSemanticTraitToggleable = 1u << 3,
    RiveSemanticTraitRequirable = 1u << 4,
    RiveSemanticTraitEnablable = 1u << 5,
    RiveSemanticTraitFocusable = 1u << 6,
} NS_SWIFT_NAME(SemanticTrait);

/// Bitmask of semantic state flags.
///
/// Bits 0-7 are trait-gated: only meaningful when the corresponding
/// SemanticTrait is set. Bits 8-13 are non-trait states (always applicable).
typedef NS_OPTIONS(NSUInteger, RiveSemanticState) {
    RiveSemanticStateNone = 0,
    // Trait-gated
    RiveSemanticStateExpanded = 1u << 0,
    RiveSemanticStateSelected = 1u << 1,
    RiveSemanticStateChecked = 1u << 2,
    RiveSemanticStateMixed = 1u << 3,
    RiveSemanticStateToggled = 1u << 4,
    RiveSemanticStateRequired = 1u << 5,
    RiveSemanticStateDisabled = 1u << 6,
    RiveSemanticStateFocused = 1u << 7,
    // Non-trait
    RiveSemanticStateHidden = 1u << 8,
    RiveSemanticStateLiveRegion = 1u << 9,
    RiveSemanticStateReadOnly = 1u << 10,
    RiveSemanticStateModal = 1u << 11,
    RiveSemanticStateObscured = 1u << 12,
    RiveSemanticStateMultiline = 1u << 13,
} NS_SWIFT_NAME(SemanticState);

#endif /* RiveEnums_h */
