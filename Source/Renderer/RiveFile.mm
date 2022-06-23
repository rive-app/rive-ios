//
//  RiveFile.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>
#include "skia_factory.hpp"

// MARK: - Globals

static rive::SkiaFactory gFactory;
NSMutableArray<RiveFile*> *riveFileCache = [[NSMutableArray alloc] init];

// MARK: - RiveFile
 
@implementation RiveFile {
    rive::File* riveFile;
    NSInteger references;
}

+ (uint)majorVersion { return UInt8(rive::File::majorVersion); }
+ (uint)minorVersion { return UInt8(rive::File::minorVersion); }

- (nullable instancetype)initWithByteArray:(NSArray *)array error:(NSError**)error {
    if (self = [super init]) {
        // If we have already loaded this file we return the existing instance
        if (RiveFile *existingFile = [self registerFileWithKey:array]) {
            return existingFile;
        }
        
        UInt8* bytes;
        @try {
            bytes = (UInt8*)calloc(array.count, sizeof(UInt64));
            
            [array enumerateObjectsUsingBlock:^(NSNumber* number, NSUInteger index, BOOL* stop){
                bytes[index] = number.unsignedIntValue;
            }];
            BOOL ok = [self import:bytes byteLength:array.count error:error];
            if (!ok) {
                return nil;
            }
            self.isLoaded = true;
        }
        @finally {
            free(bytes);
        }
        
        return self;
    }
    return nil;
}

- (nullable instancetype)initWithBytes:(UInt8 *)bytes byteLength:(UInt64)length error:(NSError**)error {
    if (self = [super init]) {
        // If we have already loaded this file we return the existing instance
        auto data = [[NSData alloc] initWithBytes:bytes length:length];
        if (RiveFile *existingFile = [self registerFileWithKey:data]) {
            return existingFile;
        }
        
        BOOL ok = [self import:bytes byteLength:length error:error];
        if (!ok) {
            return nil;
        }
        self.isLoaded = true;
        return self;
    }
    return nil;
}

/*
 * Creates a RiveFile from a binary resource
 */
- (nullable instancetype)initWithName:(NSString *)fileName withExtension:(NSString *)extension error:(NSError**)error {
    NSString *filepath = [[NSBundle mainBundle] pathForResource:fileName ofType:extension];
    NSURL *fileUrl = [NSURL fileURLWithPath:filepath];
    NSData *fileData = [NSData dataWithContentsOfURL:fileUrl];
    UInt8 *bytePtr = (UInt8 *)[fileData bytes];
    return [self initWithBytes:bytePtr byteLength:fileData.length error:error];
}

/*
 * Creates a RiveFile from a binary resource, and assumes the resource extension is '.riv'
 */
- (nullable instancetype)initWithName:(NSString *)fileName error:(NSError**)error {
    return [self initWithName:fileName withExtension:@"riv" error:error];
}

/*
 * Creates a RiveFile from an HTTP url
 */
- (nullable instancetype)initWithWebURL:(NSString *)url withDelegate:(id<RiveFileDelegate>)delegate {
    self.isLoaded = false;
    
    if (self = [super init]) {
        // If we have already loaded this file we return the existing instance
        if (RiveFile *existingFile = [self registerFileWithKey:url]) {
            [self.delegate riveFileDidLoad:existingFile error:nil];
            return existingFile;
        }
        
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
                // TODO: Do something with this error the proper way with delegates.
                NSError* error = nil;
                [self import:bytes byteLength:[data length] error:&error];
                self.isLoaded = true;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([[NSThread currentThread] isMainThread]) {
                        if ([self.delegate respondsToSelector:@selector(riveFileDidLoad:error:)]) {
                            NSError * error = nil;
                            [self.delegate riveFileDidLoad:self error:&error];
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

/// Adds this instance to the riveFileCache if its uuid is not already being used by a file in the cache.
///
/// @Returns An existing RiveFile if one in the global riveFileCache matches this instance's _uuid property; nil if not
/// @param keyObject Any hashable NSObject which is used to make a unique id for this RiveFile.
/// @Discussion The keyObject should be something unique to the file like the file name, url, byte array, etc
- (nullable RiveFile *)registerFileWithKey:(NSObject *)keyObject {
    if (_uuid == 0) {
        _uuid = [keyObject hash];
    }
    
    for (NSInteger i = 0; i < [riveFileCache count]; i++) {
        RiveFile *file = [riveFileCache objectAtIndex:i];
        if ([file uuid] == _uuid) {
            file->references++;
            NSLog(@"> Cached RiveFile UUID: %lu, References: %ld", _uuid, (long)file->references);
            _uuid = 0;
            return file;
        }
    }
    
    references++;
    [riveFileCache addObject:self];
    NSLog(@"+ Cached RiveFiles: %lu, UUID: %lu", (unsigned long)[riveFileCache count], _uuid);
    
    // No RiveFile in the riveFileCache has a matching uuid
    return nil;
}

- (BOOL) import:(UInt8 *)bytes byteLength:(UInt64)length error:(NSError**)error {
    rive::ImportResult result;
    riveFile = rive::File::import(rive::Span(bytes, length), &gFactory, &result).release();
    if (result == rive::ImportResult::success) {
        return true;
    }

    switch (result) {
        case rive::ImportResult::unsupportedVersion:
            *error = [NSError errorWithDomain:RiveErrorDomain code:RiveUnsupportedVersion userInfo:@{NSLocalizedDescriptionKey: @"Unsupported Rive File Version", @"name": @"UnsupportedVersion"}];
            break;
        case rive::ImportResult::malformed:
            *error = [NSError errorWithDomain:RiveErrorDomain code:RiveMalformedFile userInfo:@{NSLocalizedDescriptionKey: @"Malformed Rive File.", @"name": @"Malformed"}];
            break;
        default:
            *error = [NSError errorWithDomain:RiveErrorDomain code:RiveUnknownError userInfo:@{NSLocalizedDescriptionKey: @"Unknown error loading file.", @"name": @"Unknown"}];
            break;
    }
    return false;
}

- (RiveArtboard *)artboard:(NSError**)error {
    auto artboard = riveFile->artboardDefault();
    if (artboard == nullptr) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoArtboardsFound userInfo:@{NSLocalizedDescriptionKey: @"No Artboards Found.", @"name": @"NoArtboardsFound"}];
        return nil;
    }
    else {
        return [[RiveArtboard alloc] initWithArtboard: artboard.release()];
    }
}

- (NSInteger)artboardCount {
    return riveFile->artboardCount();
}

- (RiveArtboard *)artboardFromIndex:(NSInteger)index error:(NSError**)error {
    auto artboard = riveFile->artboardAt(index);
    if (artboard == nullptr) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoArtboardFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No Artboard Found at index %ld.", (long)index], @"name": @"NoArtboardFound"}];
        return nil;
    }
    return [[RiveArtboard alloc] initWithArtboard: artboard.release()];
}

- (RiveArtboard *)artboardFromName:(NSString *)name error:(NSError**)error {
    std::string stdName = std::string([name UTF8String]);
    auto artboard = riveFile->artboardNamed(stdName);
    if (artboard == nullptr) {
        *error = [NSError errorWithDomain:RiveErrorDomain code:RiveNoArtboardFound userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"No Artboard Found with name %@.", name], @"name": @"NoArtboardFound"}];
        return nil;
    } else {
        return [[RiveArtboard alloc] initWithArtboard: artboard.release()];
    }
}

- (NSArray *)artboardNames {
    NSMutableArray *artboardNames = [NSMutableArray array];
    
    for (NSUInteger i=0; i<[self artboardCount]; i++) {
        [artboardNames addObject:[[self artboardFromIndex: i error:nil] name]];
    }
    return artboardNames;
}

/// Clean up rive file
- (void)dealloc {
    BOOL removed = false;
    BOOL duplicateCleanup = _uuid == 0; // magic number given to duplicates when registering
    
    if (!duplicateCleanup) {
        for (auto i = 0; i < riveFileCache.count; i++) {
            if (_uuid == riveFileCache[i].uuid) {
                RiveFile *cachedFile = [riveFileCache objectAtIndex:i];
                cachedFile->references--;
                NSLog(@"< Cached RiveFile UUID: %lu, References: %ld", _uuid, (long)cachedFile->references);
                
                if (cachedFile->references <= 0) {
                    [riveFileCache removeObject:cachedFile];
                    removed = true;
                    NSLog(@"- Cached RiveFiles: %lu, UUID: %lu", (unsigned long)[riveFileCache count], _uuid);
                }
                
                break;
            }
        }
    }
    
    if (!removed && !duplicateCleanup) {
        [NSException raise:@"UntrackedRiveFile" format:@"The _uuid property of the RiveFile being deallocated is not in the riveFileCache"];
    }
    
    delete riveFile;
}

@end
