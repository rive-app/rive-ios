//
//  RiveStateMachineInstance.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//


#ifndef rive_state_machine_instance_h
#define rive_state_machine_instance_h

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@class RiveStateMachine;
@class RiveSMIInput;
@class RiveSMIBool;
@class RiveSMITrigger;
@class RiveSMINumber;
@class RiveLayerState;

/*
 * RiveStateMachineInstance
 */
@interface RiveStateMachineInstance : NSObject
- (NSString* )name;
- (bool)advance:(RiveArtboard *)artboard by: (double)elapsedSeconds;
- (const RiveStateMachine *)stateMachine;
- (const RiveSMIBool *)getBool:(NSString*)name;
- (const RiveSMITrigger *)getTrigger:(NSString*)name;
- (const RiveSMINumber *)getNumber:(NSString*)name;
- (NSArray<NSString *> *)inputNames;
- (NSInteger)inputCount;
- (RiveSMIInput *)inputFromIndex:(NSInteger)index;
- (RiveSMIInput *)inputFromName:(NSString*)name;
- (NSInteger)stateChangedCount;
- (RiveLayerState *)stateChangedFromIndex:(NSInteger)index;
- (NSArray<NSString *> *)stateChanges;

@end

NS_ASSUME_NONNULL_END

#endif /* rive_state_machine_instance_h */
