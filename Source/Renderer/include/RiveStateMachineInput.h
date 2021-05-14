//
//  RiveStateMachineInput.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//


#ifndef rive_state_machine_input_h
#define rive_state_machine_input_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * RiveStateMachineInput
 */
@interface RiveStateMachineInput : NSObject
- (bool)isBoolean;
- (bool)isTrigger;
- (bool)isNumber;
- (NSString *)name;
@end

/*
 * RiveStateMachineBoolInput
 */
@interface RiveStateMachineBoolInput : RiveStateMachineInput
- (bool)value;
@end

/*
 * RiveStateMachineTriggerInput
 */
@interface RiveStateMachineTriggerInput : RiveStateMachineInput
@end

/*
 * RiveStateMachineNumberInput
 */
@interface RiveStateMachineNumberInput : RiveStateMachineInput
- (float)value;
@end

NS_ASSUME_NONNULL_END

#endif /* rive_state_machine_input_h */

