//
//  RiveSMIInput.mm
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>

/*
 * RiveSMIInput
 */
@implementation RiveSMIInput {
     const rive::SMIInput *instance; // note: we do NOT own this, so don't delete it
}

- (const rive::SMIInput *)getInstance {
    return instance;
}

// Creates a new RiveSMINumber from a cpp SMINumber
- (instancetype)initWithSMIInput:(const rive::SMIInput *)stateMachineInput {
    if (self = [super init]) {
        instance = stateMachineInput;
        return self;
    } else {
        return nil;
    }
}

- (bool)isBoolean {
    return instance->input()->is<rive::StateMachineBool>();
}

- (bool)isTrigger {
    return instance->input()->is<rive::StateMachineTrigger>();
}

- (bool)isNumber {
    return instance->input()->is<rive::StateMachineNumber>();
};

- (NSString *)name {
    std::string str = ((const rive::SMIInput *)instance)->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

@end


/*
 * RiveSMITrigger
 */
@implementation RiveSMITrigger

- (void) fire {
    ((rive::SMITrigger *)[self getInstance])->fire();
}

@end

/*
 * RiveSMIBool
 */
@implementation RiveSMIBool

- (void) setValue:(bool)newValue {
    ((rive::SMIBool *)[self getInstance])->value(newValue);
}

- (bool) value{
    return ((rive::SMIBool *)[self getInstance])->value();
}

@end

/*
 * RiveSMINumber
 */
@implementation RiveSMINumber

- (void) setValue:(float)newValue {
    ((rive::SMINumber *)[self getInstance])->value(newValue);
}
- (float) value {
    return ((rive::SMINumber *)[self getInstance])->value();
}

@end
