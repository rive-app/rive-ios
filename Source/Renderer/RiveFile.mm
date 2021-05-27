//
//  RiveFile.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//


#import <Rive.h>
#import <RivePrivateHeaders.h>

@interface RiveFile ()

- (rive::BinaryReader) getReader:(UInt8 *)bytes byteLength:(UInt64)length;
- (void) import:(rive::BinaryReader)reader;

@end

/*
 * RiveFile
 */
@implementation RiveFile {
    rive::File* riveFile;
}

- (rive::BinaryReader) getReader:(UInt8 *)bytes byteLength:(UInt64)length {
    return rive::BinaryReader(bytes, length);
}


+ (uint)majorVersion { return UInt8(rive::File::majorVersion); }
+ (uint)minorVersion { return UInt8(rive::File::minorVersion); }

- (void) import:(rive::BinaryReader)reader {
    rive::ImportResult result = rive::File::import(reader, &riveFile);
    if (result == rive::ImportResult::success) {
        return;
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

- (nullable instancetype)initWithByteArray:(NSArray *)array {
    if (self = [super init]) {
        UInt8* bytes;
        @try {
            bytes = (UInt8*)calloc(array.count, sizeof(UInt64));
            
            [array enumerateObjectsUsingBlock:^(NSNumber* number, NSUInteger index, BOOL* stop){
                bytes[index] = number.unsignedIntValue;
            }];
            rive::BinaryReader reader = [self getReader:bytes byteLength:array.count];
            [self import:reader];
        }
        @finally {
            free(bytes);
        }
        
        return self;
    }
    return nil;
}

- (nullable instancetype)initWithBytes:(UInt8 *)bytes byteLength:(UInt64)length {
    if (self = [super init]) {
        rive::BinaryReader reader = [self getReader:bytes byteLength:length];
        [self import:reader];
        return self;
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
