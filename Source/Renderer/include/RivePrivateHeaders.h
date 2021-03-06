//
//  RivePrivateHeaders.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 13/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

#ifndef RivePrivateHeaders_h
#define RivePrivateHeaders_h

#import "file.hpp"
#import "artboard.hpp"
#import "animation.hpp"
#import "linear_animation.hpp"
#import "linear_animation_instance.hpp"
#import "state_machine.hpp"
#import "state_machine_instance.hpp"
#import "state_machine_input.hpp"
#import "state_machine_bool.hpp"
#import "state_machine_number.hpp"
#import "state_machine_trigger.hpp"
#import "state_machine_input_instance.hpp"
#import "layer_state.hpp"
#import <entry_state.hpp>
#import <any_state.hpp>
#import <exit_state.hpp>
#import <animation_state.hpp>

/*
 * RiveStateMachineInstance interface
 */
@interface RiveStateMachineInstance ()
- (instancetype)initWithStateMachine:(const rive::StateMachine *)stateMachine;
@end

/*
 * RiveStateMachine interface
 */
@interface RiveStateMachine ()
- (instancetype)initWithStateMachine:(const rive::StateMachine *)stateMachine;
@end

/*
 * RiveSMIInput interface
 */
@interface RiveSMIInput ()
- (instancetype)initWithSMIInput:(const rive::SMIInput *)riveSMIInput;
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


/*
 * RiveStateMachineInput interface
 */
@interface RiveStateMachineInput ()
- (instancetype)initWithStateMachineInput:(const rive::StateMachineInput *)riveStateMachineInput;
@end

/*
 * RiveLinearAnimationInstance interface
 */
@interface RiveLinearAnimationInstance ()
- (instancetype)initWithAnimation:(const rive::LinearAnimation *)riveAnimation;
@end

/*
 * RiveLinearAnimation interface
 */
@interface RiveLinearAnimation ()
- (instancetype) initWithAnimation:(const rive::LinearAnimation *)riveAnimation;
@end

/*
 * RiveArtboard interface
 */
@interface RiveArtboard ()
@property (nonatomic, readonly) rive::Artboard* artboard;
-(instancetype) initWithArtboard:(rive::Artboard *) riveArtboard;
@end

/*
 * RiveRenderer interface
 */
@interface RiveRenderer ()
@property (nonatomic, readonly) rive::Renderer* renderer;
-(rive::Renderer *) renderer;
@end


/*
 * RiveLayerState interface
 */
@interface RiveLayerState ()
- (instancetype) initWithLayerState:(const rive::LayerState *)layerState;
@end


#endif /* RivePrivateHeaders_h */
