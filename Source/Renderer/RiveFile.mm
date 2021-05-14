//
//  RiveFile.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//


#import <Rive.h>
#import <RivePrivateHeaders.h>

/*
 * RiveFile
 */
@implementation RiveFile {
    rive::File* riveFile;
}

+ (uint)majorVersion { return UInt8(rive::File::majorVersion); }
+ (uint)minorVersion { return UInt8(rive::File::minorVersion); }

- (nullable instancetype)initWithBytes:(UInt8 *)bytes byteLength:(UInt64)length {
    if (self = [super init]) {
        rive::BinaryReader reader = rive::BinaryReader(bytes, length);
        rive::ImportResult result = rive::File::import(reader, &riveFile);
        if (result == rive::ImportResult::success) {
            return self;
        }
        else if(result == rive::ImportResult::unsupportedVersion){
            @throw [[RiveException alloc] initWithName:@"UnsupportedVersion" reason:@"Unsupported Rive File Version." userInfo:nil];
            
        }
        else if(result == rive::ImportResult::malformed){
            @throw [[RiveException alloc] initWithName:@"Malformed" reason:@"Malformed Rive File." userInfo:nil];
        }
        else {
            @throw [[RiveException alloc] initWithName:@"Unknown" reason:@"Unknown error loading file." userInfo:nil];
        }
    }
    return nil;
}

- (RiveArtboard *)artboard {
    rive::Artboard *artboard = riveFile->artboard();
    if (artboard == nullptr) {
        @throw [[RiveException alloc] initWithName:@"NoArtboardsFound" reason: @"No Artboards Found." userInfo:nil];
    }
    else {
        return [[RiveArtboard alloc] initWithArtboard: artboard];
    }
    
}

- (NSInteger)artboardCount {
    return riveFile->artboardCount();
}

- (RiveArtboard *)artboardFromIndex:(NSInteger)index {
    if (index >= [self artboardCount]) {
        @throw [[RiveException alloc] initWithName:@"NoArtboardFound" reason:[NSString stringWithFormat: @"No Artboard Found at index %ld.", index] userInfo:nil];
    }
    return [[RiveArtboard alloc]
            initWithArtboard: reinterpret_cast<rive::Artboard *>(riveFile->artboard(index))];
}

- (RiveArtboard *)artboardFromName:(NSString *)name {
    std::string stdName = std::string([name UTF8String]);
    rive::Artboard *artboard = riveFile->artboard(stdName);
    if (artboard == nullptr) {
        @throw [[RiveException alloc] initWithName:@"NoArtboardFound" reason:[NSString stringWithFormat: @"No Artboard Found with name %@.", name] userInfo:nil];
    } else {
        return [[RiveArtboard alloc] initWithArtboard: artboard];
    }
}

- (NSArray *)artboardNames {
    NSMutableArray *artboardNames = [NSMutableArray array];
    
    for (NSUInteger i=0; i<[self artboardCount]; i++) {
        NSString* name = [[self artboardFromIndex: i] name];
        [artboardNames addObject:name];
    }
    return artboardNames;
}

@end
