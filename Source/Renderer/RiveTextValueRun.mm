//
//  RiveTextValueRun.m
//
//
//  Created by Zach Plata on 7/27/23.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>

/*
 * RiveTextValueRun
 */
@implementation RiveTextValueRun
{
    const rive::TextValueRun*
        instance; // note: we do NOT own this, so don't delete it
}

- (const rive::TextValueRun*)getInstance
{
    return instance;
}

// Creates a new RiveTextValueRun from a cpp TextValueRun
- (instancetype)initWithTextValueRun:(const rive::TextValueRun*)textRun
{
    if (self = [super init])
    {
        instance = textRun;
        return self;
    }
    else
    {
        return nil;
    }
}

- (void)setText:(NSString*)textValue
{
    std::string stdName = std::string([textValue UTF8String]);
    ((rive::TextValueRun*)[self getInstance])->text(stdName);
}

- (NSString*)text
{
    std::string str = ((const rive::TextValueRun*)instance)->text();
    return [NSString stringWithCString:str.c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

@end
