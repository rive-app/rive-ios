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
- (bool)advanceBy: (double)elapsedSeconds;
- (const RiveStateMachine *)stateMachine;
- (const RiveSMIBool *)getBool:(NSString*)name;
- (const RiveSMITrigger *)getTrigger:(NSString*)name;
- (const RiveSMINumber *)getNumber:(NSString*)name;
- (NSArray<NSString *> *)inputNames;
- (NSInteger)inputCount;
- (RiveSMIInput * __nullable)inputFromIndex:(NSInteger)index error:(NSError**)error;
- (RiveSMIInput * __nullable)inputFromName:(NSString*)name error:(NSError**)error;
- (NSInteger)stateChangedCount;
- (RiveLayerState * __nullable)stateChangedFromIndex:(NSInteger)index error:(NSError**)error;
- (NSArray<NSString *> *)stateChanges;

@end

NS_ASSUME_NONNULL_END

#endif /* rive_state_machine_instance_h */
