//
//  RiveStateMachine.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//


#ifndef rive_state_machine_h
#define rive_state_machine_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RiveStateMachineInstance;
@class RiveStateMachineInput;

/*
 * RiveStateMachine
 */
@interface RiveStateMachine : NSObject
- (NSString *)name;
- (NSInteger)layerCount;
- (NSInteger)inputCount;
- (RiveStateMachineInstance *)instanceWithArtboard:(RiveArtboard *)artboard;
- (NSArray<NSString *> *)inputNames;
- (RiveStateMachineInput * __nullable)inputFromIndex:(NSInteger)index error:(NSError**)error;
- (RiveStateMachineInput * __nullable)inputFromName:(NSString*)name error:(NSError**)error;
@end

NS_ASSUME_NONNULL_END

#endif /* rive_state_machine_h */

