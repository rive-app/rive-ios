//
//  RiveStateMachineInput.mm
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>

/*
 * RiveStateMachineInput
 */
@implementation RiveStateMachineInput {
     const rive::StateMachineInput *instance;
}

- (const rive::StateMachineInput *)getInstance {
    return instance;
}

// Creates a new RiveSMINumber from a cpp SMINumber
- (instancetype)initWithStateMachineInput:(const rive::StateMachineInput *)stateMachineInput {
    if (self = [super init]) {
        instance = stateMachineInput;
        return self;
    } else {
        return nil;
    }
}

- (bool)isBoolean {
    return instance->is<rive::StateMachineBool>();
}

- (bool)isTrigger{
    return instance->is<rive::StateMachineTrigger>();
}

- (bool)isNumber{
    return instance->is<rive::StateMachineNumber>();
};

- (NSString *)name{
    std::string str = ((const rive::StateMachineInput *)instance)->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

@end

/*
 * RiveStateMachineInput
 */
@implementation RiveStateMachineBoolInput

- (bool)value {
    return ((const rive::StateMachineBool *)[self getInstance])->value();
}

@end
 
/*
 * RiveStateMachineInput
 */
@implementation RiveStateMachineTriggerInput

@end
 
/*
 * RiveStateMachineInput
 */
@implementation RiveStateMachineNumberInput

- (float)value {
    return ((const rive::StateMachineNumber*)[self getInstance])->value();
}

@end
