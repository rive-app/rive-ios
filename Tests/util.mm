//
//  util.m
//  RiveRuntimeTests
//
//  Created by Maxwell Talbot on 10/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

#import "Rive.h"
#import "util.h"

@implementation Util

+ (RiveFile*)loadTestFile:(NSString*)name error:(NSError**)error
{
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    NSString* path = [bundle pathForResource:name ofType:@"riv"];

    NSData* nsData = [NSData dataWithContentsOfFile:path];
    Byte* bytes = (Byte*)malloc(nsData.length);
    memcpy(bytes, [nsData bytes], nsData.length);
    RiveFile* file = [[RiveFile alloc] initWithBytes:bytes byteLength:nsData.length error:error];
    return file;
}

@end
