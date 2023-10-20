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
#include "rive/open_url_event.hpp"
#include "rive/custom_property_boolean.hpp"
#include "rive/custom_property_string.hpp"
#include "rive/custom_property_number.hpp"

// MARK: - Feature Flags

#define RIVE_ENABLE_REFERENCE_COUNTING false

// MARK: - Public Interfaces

/*
 * RiveStateMachineInstance interface
 */
@interface RiveStateMachineInstance ()
- (instancetype)initWithStateMachine:(std::unique_ptr<rive::StateMachineInstance>)stateMachine;
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
- (instancetype)initWithRiveEvent:(const rive::Event*)riveEvent delay:(float)delay;
@end

/*
 * RiveTextValueRun interface
 */
@interface RiveTextValueRun ()
- (instancetype)initWithTextValueRun:(const rive::TextValueRun*)riveTextValueRun;
@end

/*
 * RiveLinearAnimationInstance interface
 */
@interface RiveLinearAnimationInstance ()
- (instancetype)initWithAnimation:(std::unique_ptr<rive::LinearAnimationInstance>)riveAnimation;
@end

/*
 * RiveArtboard interface
 */
@interface RiveArtboard ()
- (rive::ArtboardInstance*)artboardInstance;
- (instancetype)initWithArtboard:(std::unique_ptr<rive::ArtboardInstance>)riveArtboard;
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
