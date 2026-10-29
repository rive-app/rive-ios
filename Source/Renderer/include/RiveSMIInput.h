//
//  RiveSMIInput.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#ifndef rive_smi_input_h
#define rive_smi_input_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * SMIInput
 */
DEPRECATED_MSG_ATTRIBUTE("The legacy state machine input API is deprecated. "
                         "Use Data Binding properties instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#state-machine-inputs")
@interface RiveSMIInput : NSObject
- (NSString*)name;
- (bool)isBoolean;
- (bool)isTrigger;
- (bool)isNumber;
@end

/*
 * SMITrigger
 */
DEPRECATED_MSG_ATTRIBUTE("The legacy state machine input API is deprecated. "
                         "Use Data Binding properties instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#state-machine-inputs")
@interface RiveSMITrigger : RiveSMIInput
- (void)fire;
@end

/*
 * SMIBool
 */
DEPRECATED_MSG_ATTRIBUTE("The legacy state machine input API is deprecated. "
                         "Use Data Binding properties instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#state-machine-inputs")
@interface RiveSMIBool : RiveSMIInput
- (bool)value;
- (void)setValue:(bool)newValue;
@end

/*
 * SMINumber
 */
DEPRECATED_MSG_ATTRIBUTE("The legacy state machine input API is deprecated. "
                         "Use Data Binding properties instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#state-machine-inputs")
@interface RiveSMINumber : RiveSMIInput
- (float)value;
- (void)setValue:(float)newValue;
@end

NS_ASSUME_NONNULL_END

#endif /* rive_smi_input_h */
