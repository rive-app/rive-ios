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
            self.isLoaded = true;
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
        self.isLoaded = true;
        return self;
    }
    return nil;
}

/*
 * Creates a RiveFile from a binary resource
 */
- (nullable instancetype)initWithResource:(NSString *)resourceName withExtension:(NSString *)extension {
    NSString *filepath = [[NSBundle mainBundle] pathForResource:resourceName ofType:extension];
    NSURL *fileUrl = [NSURL fileURLWithPath:filepath];
    NSData *fileData = [NSData dataWithContentsOfURL:fileUrl];
    UInt8 *bytePtr = (UInt8 *)[fileData bytes];
    
    return [self initWithBytes:bytePtr byteLength:fileData.length];
}

/*
 * Creates a RiveFile from a binary resource, and assumes the resource extension is '.riv'
 */
- (nullable instancetype)initWithResource:(NSString *)resourceName {
    return [self initWithResource:resourceName withExtension:@"riv"];
}

/*
 * Creates a RiveFile from an HTTP url
 */
- (nullable instancetype)initWithHttpUrl:(NSString *)url withDelegate:(id<RiveFileDelegate>)delegate {
    self.isLoaded = false;
    if (self = [super init]) {
        self.delegate = delegate;
        // Set up the http download task
        NSURL *URL = [NSURL URLWithString:url];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:
                              [NSURLSessionConfiguration defaultSessionConfiguration]];
        NSURLSessionTask  *task = [session downloadTaskWithURL:URL
           completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (!error) {
                // Load the data into the reader
                NSData *data = [NSData dataWithContentsOfURL: location];
                UInt8 *bytes = (UInt8 *)[data bytes];
                rive::BinaryReader reader = [self getReader:bytes byteLength:[data length]];
                [self import:reader];
                self.isLoaded = true;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([[NSThread currentThread] isMainThread]) {
                        if ([self.delegate respondsToSelector:@selector(riveFileDidLoad:)]) {
                            [self.delegate riveFileDidLoad:self];
                        }
                    }
                });
            }
        }];

        // Kick off the http download
        [task resume];
        
        // Return the as yet uninitialized RiveFile
        return self;
    }

    return nil;
}

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

/// Clean up rive file
- (void)dealloc {
    delete riveFile;
}

@end
