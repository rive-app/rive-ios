//
//  RiveDataBindingViewModel.h
//  RiveRuntime
//
//  Created by David Skuza on 1/13/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RiveDataBindingViewModelInstance;
@class RiveDataBindingViewModelInstancePropertyData;

/// An object that represents a View Model of a Rive file.
@interface RiveDataBindingViewModel : NSObject

/// The name of the view model.
@property(nonatomic, readonly) NSString* name;

/// The number of instances in the view model.
@property(nonatomic, readonly) NSUInteger instanceCount;

/// An array of names of all instances in the view model.
@property(nonatomic, readonly) NSArray<NSString*>* instanceNames;

/// The number of all properties in the view model.
@property(nonatomic, readonly) NSUInteger propertyCount;

/// An array of property data of all properties in the view model.
@property(nonatomic, readonly)
    NSArray<RiveDataBindingViewModelInstancePropertyData*>* properties;

/// Creates a new instance to bind from a given index.
///
/// The index of an instance starts at 0, where 0 is
/// the first instance that appears in the "Data Bind" panel's instances
/// dropdown.
///
/// - Note: A strong reference to this instance must be maintained if it is
/// being bound to a state machine or artboard, or for observability. Fetching a
/// new instance from the same model, if not bound, will not update its
/// properties when properties are updated.
///
/// - Parameter index: The index of an instance within the view model.
- (nullable RiveDataBindingViewModelInstance*)createInstanceFromIndex:
    (NSUInteger)index NS_SWIFT_NAME(createInstance(fromIndex:));

/// Creates a new instance to bind from a given name.
///
/// The name of an instance has to match the name of
/// an instance in the "Data Bind" panel's instances dropdown, where the
/// instance has been exported.
///
/// - Note: A strong reference to this instance must be maintained if it is
/// being bound to a state machine or artboard, or for observability. Fetching a
/// new instance from the same model, if not bound, will not update its
/// properties when properties are updated.
///
/// - Parameter name: The name of an instance within the view model.
- (nullable RiveDataBindingViewModelInstance*)createInstanceFromName:
    (NSString*)name NS_SWIFT_NAME(createInstance(fromName:));

/// Creates a new default instance to bind from the view model.
///
/// This is the instance marked as "Default" in the "Data Bind" instances
/// dropdown when an artboard is selected.
///
/// - Note: A strong reference to this instance must be maintained if it is
/// being bound to a state machine or artboard, or for observability. Fetching a
/// new instance from the same model, if not bound, will not update its
/// properties when properties are updated.
- (nullable RiveDataBindingViewModelInstance*)createDefaultInstance;

/// Creates a new instance with Rive default values from the view model to bind
/// to an artboard and/or state machine.
///
/// *Default values*
/// - *String*: ""
/// - *Number*: 0
/// - *Boolean*: false
/// - *Color*: ARGB(0, 0, 0, 0)
/// - *Enum*: An enum's first value
///
/// - Note: A strong reference to this instance must be maintained if it is
/// being bound to a state machine or artboard, or for observability. Fetching a
/// new instance from the same model, if not bound, will not update its
/// properties when properties are updated.
- (nullable RiveDataBindingViewModelInstance*)createInstance;

@end

NS_ASSUME_NONNULL_END
