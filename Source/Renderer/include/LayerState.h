//
//  RiveFile.h
//  RiveRuntime
//
//  Created by Matt Sullivan on 8/30/20.
//  Copyright © 2020 Rive. All rights reserved.
//

#ifndef layer_state_h
#define layer_state_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RiveLinearAnimation;

/*
 * RiveLayerState
 */
DEPRECATED_MSG_ATTRIBUTE("The legacy state observation API is deprecated. Use "
                         "Data Binding properties instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#observing-state-machine-state")
@interface RiveLayerState : NSObject

- (const void*)rive_layer_state;
- (bool)isEntryState;
- (bool)isExitState;
- (bool)isAnyState;
- (bool)isAnimationState;
- (NSString*)name;

@end

/*
 * RiveExitState
 */
DEPRECATED_MSG_ATTRIBUTE("The legacy state observation API is deprecated. Use "
                         "Data Binding properties instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#observing-state-machine-state")
@interface RiveExitState : RiveLayerState
- (NSString*)name;
@end

/*
 * RiveEntryState
 */
DEPRECATED_MSG_ATTRIBUTE("The legacy state observation API is deprecated. Use "
                         "Data Binding properties instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#observing-state-machine-state")
@interface RiveEntryState : RiveLayerState
- (NSString*)name;
@end

/*
 * RiveAnyState
 */
DEPRECATED_MSG_ATTRIBUTE("The legacy state observation API is deprecated. Use "
                         "Data Binding properties instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#observing-state-machine-state")
@interface RiveAnyState : RiveLayerState
- (NSString*)name;
@end

/*
 * RiveAnimationState
 */
DEPRECATED_MSG_ATTRIBUTE("The legacy state observation API is deprecated. Use "
                         "Data Binding properties instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#observing-state-machine-state")
@interface RiveAnimationState : RiveLayerState
- (NSString*)name;
@end

/*
 * RiveUnknownState
 * This catches new states that haven't been added to iOS runtime yet
 */
DEPRECATED_MSG_ATTRIBUTE("The legacy state observation API is deprecated. Use "
                         "Data Binding properties instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#observing-state-machine-state")
@interface RiveUnknownState : RiveLayerState
- (NSString*)name;
@end

NS_ASSUME_NONNULL_END

#endif /* layer_state_h */
