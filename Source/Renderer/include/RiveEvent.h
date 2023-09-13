//
//  RiveEvent.h
//  RiveRuntime
//
//  Created by Zach Plata on 8/23/23.
//  Copyright © 2023 Rive. All rights reserved.
//

#ifndef rive_event_h
#define rive_event_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RiveEventReport: NSObject
- (float) secondsDelay;
@end

/*
 * RiveEvent
 */
@interface RiveEvent : NSObject
/// Name of the RiveEvent
- (NSString*)name;
/// Type of the RiveEvent
- (NSInteger)type;
/// Delay in seconds since the Event was actually fired (applicable in cases of Events fired off from timeline animations)
- (float) delay;
/// Dictionary of custom properties set on any event
- (NSDictionary<NSString*, id>*)properties;
@end

/*
 * RiveGeneralEvent
 */
@interface RiveGeneralEvent : RiveEvent
@end

/*
 * RiveOpenUrlEvent
 */
@interface RiveOpenUrlEvent: RiveEvent
/// URL of a link to open
- (NSString*)url;
/// Target value for a link to open with
- (NSString*)target;
@end

NS_ASSUME_NONNULL_END

#endif /* rive_event_h */
