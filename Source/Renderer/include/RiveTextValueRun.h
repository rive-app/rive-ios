//
//  RiveTextValueRun.h
//  RiveRuntime
//
//  Created by Zach Plata on 7/27/23.
//  Copyright © 2023 Rive. All rights reserved.
//

#ifndef rive_text_value_run_h
#define rive_text_value_run_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * TextValueRun
 */
DEPRECATED_MSG_ATTRIBUTE("The legacy text run API is deprecated. Use Data "
                         "Binding string properties instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#view-model-instance-properties")
@interface RiveTextValueRun : NSObject
- (NSString*)text;
- (void)setText:(NSString*)newValue;
@end

NS_ASSUME_NONNULL_END

#endif /* rive_text_value_run_h */
