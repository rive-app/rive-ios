//
//  RivePrivateHeaders.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 13/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

#ifndef RivePrivateHeaders_h
#define RivePrivateHeaders_h

#import "rive/file.hpp"
#import "rive/artboard.hpp"
#import "rive/animation/animation.hpp"
#import "rive/animation/linear_animation.hpp"
#import "rive/animation/linear_animation_instance.hpp"
#import "rive/animation/state_machine.hpp"
#import "rive/animation/state_machine_instance.hpp"
#import "rive/animation/state_machine_input.hpp"
#import "rive/animation/state_machine_bool.hpp"
#import "rive/animation/state_machine_number.hpp"
#import "rive/animation/state_machine_trigger.hpp"
#import "rive/animation/state_machine_input_instance.hpp"
#import "rive/animation/layer_state.hpp"
#import "rive/animation/entry_state.hpp"
#import "rive/animation/any_state.hpp"
#import "rive/animation/exit_state.hpp"
#import "rive/animation/animation_state.hpp"
#import "rive/text/text_value_run.hpp"
#import "rive/event.hpp"
#import "rive/assets/image_asset.hpp"
#import "rive/assets/font_asset.hpp"
#import "rive/assets/audio_asset.hpp"
#import "rive/assets/file_asset.hpp"
#import "rive/file_asset_loader.hpp"
#import "rive/viewmodel/runtime/viewmodel_instance_runtime.hpp"
#import "rive/viewmodel/runtime/viewmodel_runtime.hpp"

#include "rive/open_url_event.hpp"
#include "rive/custom_property_boolean.hpp"
#include "rive/custom_property_string.hpp"
#include "rive/custom_property_number.hpp"

// MARK: - Feature Flags

#define RIVE_ENABLE_REFERENCE_COUNTING false

NS_ASSUME_NONNULL_BEGIN

// MARK: - Public Interfaces

/*
 * RiveStateMachineInstance interface
 */
@interface RiveStateMachineInstance ()
- (instancetype)initWithStateMachine:
    (std::unique_ptr<rive::StateMachineInstance>)stateMachine;
@end

/*
 * RiveSMIInput interface
 */
@interface RiveSMIInput ()
- (instancetype)initWithSMIInput:(const rive::SMIInput*)riveSMIInput;
@end

/*
 * SMITrigger interface
 */
@interface RiveSMITrigger ()
@end

/*
 * SMINumber interface
 */
@interface RiveSMINumber ()
@end

/*
 * SMIBool interface
 */
@interface RiveSMIBool ()
@end

/**
 * RiveEvent interface
 */
@interface RiveEvent ()
- (instancetype)initWithRiveEvent:(const rive::Event*)riveEvent
                            delay:(float)delay;
@end

/*
 * RiveTextValueRun interface
 */
@interface RiveTextValueRun ()
- (instancetype)initWithTextValueRun:
    (const rive::TextValueRun*)riveTextValueRun;
@end

/*
 * RiveLinearAnimationInstance interface
 */
@interface RiveLinearAnimationInstance ()
- (instancetype)initWithAnimation:
    (std::unique_ptr<rive::LinearAnimationInstance>)riveAnimation;
@end

/*
 * RiveArtboard interface
 */
@interface RiveArtboard ()
- (rive::ArtboardInstance*)artboardInstance;
- (instancetype)initWithArtboard:
    (std::unique_ptr<rive::ArtboardInstance>)riveArtboard;
@end

/*
 * RiveRenderer interface
 */
@interface RiveRenderer ()
@property(nonatomic, readonly) rive::Renderer* renderer;
- (rive::Renderer*)renderer;
@end

/*
 * RiveLayerState interface
 */
@interface RiveLayerState ()
- (instancetype)initWithLayerState:(const rive::LayerState*)layerState;
@end

#endif /* RivePrivateHeaders_h */

/*
 * RiveImageAsset
 */
@interface RiveImageAsset ()
- (instancetype)initWithFileAsset:(const rive::ImageAsset*)fileAsset;
@end

/*
 * RiveFontAsset
 */
@interface RiveFontAsset ()
- (instancetype)initWithFileAsset:(const rive::FontAsset*)fileAsset;
@end

/*
 * RiveAudioAsset
 */
@interface RiveAudioAsset ()
- (instancetype)initWithFileAsset:(const rive::AudioAsset*)fileAsset;
@end

/*
 * RiveFileAsset
 */
@interface RiveFactory ()
- (instancetype)initWithFactory:(rive::Factory*)factory;
@end

@interface RiveFont ()
- (instancetype)initWithFont:(rive::rcp<rive::Font>)font;
- (rive::rcp<rive::Font>)instance;
@end

@interface RiveRenderImage ()
- (instancetype)initWithImage:(rive::rcp<rive::RenderImage>)image;
- (rive::rcp<rive::RenderImage>)instance;
@end

@interface RiveAudio ()
- (instancetype)initWithAudio:(rive::rcp<rive::AudioSource>)audio;
- (rive::rcp<rive::AudioSource>)instance;
@end

@interface RiveDataBindingViewModel ()
- (instancetype)initWithViewModel:(rive::ViewModelRuntime*)viewModel;
@end

@protocol RiveDataBindingViewModelInstancePropertyDelegate
- (void)valuePropertyDidAddListener:
    (RiveDataBindingViewModelInstanceProperty*)value;
- (void)valuePropertyDidRemoveListener:
            (RiveDataBindingViewModelInstanceProperty*)listener
                               isEmpty:(BOOL)isEmpty;
@end

@interface RiveDataBindingViewModelInstance ()
@property(nonatomic, readonly) rive::ViewModelInstanceRuntime* instance;
- (instancetype)initWithInstance:(rive::ViewModelInstanceRuntime*)instance;
- (void)cacheProperty:(RiveDataBindingViewModelInstanceProperty*)value
             withPath:(NSString*)path;
@end

@interface RiveDataBindingViewModelInstanceProperty ()
@property(nonatomic, weak) id<RiveDataBindingViewModelInstancePropertyDelegate>
    valueDelegate;
@property(nonatomic, readonly) NSDictionary<NSUUID*, id>* listeners;
- (instancetype)initWithValue:(rive::ViewModelInstanceValueRuntime*)value;
- (NSUUID*)addListener:(id)listener;
- (void)removeListener:(NSUUID*)listener;
- (void)handleListeners;
@end

@interface RiveDataBindingViewModelInstanceStringProperty ()
- (instancetype)initWithString:(rive::ViewModelInstanceStringRuntime*)string;
@end

@interface RiveDataBindingViewModelInstanceNumberProperty ()
- (instancetype)initWithNumber:(rive::ViewModelInstanceNumberRuntime*)number;
@end

@interface RiveDataBindingViewModelInstanceBooleanProperty ()
- (instancetype)initWithBoolean:(rive::ViewModelInstanceBooleanRuntime*)boolean;
@end

@interface RiveDataBindingViewModelInstanceColorProperty ()
- (instancetype)initWithColor:(rive::ViewModelInstanceColorRuntime*)color;
@end

@interface RiveDataBindingViewModelInstanceEnumProperty ()
- (instancetype)initWithEnum:(rive::ViewModelInstanceEnumRuntime*)e;
@end

@interface RiveDataBindingViewModelInstanceTriggerProperty ()
- (instancetype)initWithTrigger:(rive::ViewModelInstanceTriggerRuntime*)trigger;
@end

@interface RiveDataBindingViewModelInstancePropertyData ()
- (instancetype)initWithData:(rive::PropertyData)data;
@end

NS_ASSUME_NONNULL_END
