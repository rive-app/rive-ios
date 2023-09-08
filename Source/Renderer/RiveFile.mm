//
//  RiveFile.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <RenderContext.hh>
#import <RenderContextManager.h>

/*
 * RiveFile
 */
@implementation RiveFile
{
    std::unique_ptr<rive::File> riveFile;
}

+ (uint)majorVersion
{
    return UInt8(rive::File::majorVersion);
}
+ (uint)minorVersion
{
    return UInt8(rive::File::minorVersion);
}

- (nullable instancetype)initWithByteArray:(NSArray*)array error:(NSError**)error
{
    if (self = [super init])
    {
        UInt8* bytes;
        @try
        {
            bytes = (UInt8*)calloc(array.count, sizeof(UInt64));

            [array enumerateObjectsUsingBlock:^(NSNumber* number, NSUInteger index, BOOL* stop) {
              bytes[index] = number.unsignedIntValue;
            }];
            BOOL ok = [self import:bytes byteLength:array.count error:error];
            if (!ok)
            {
                return nil;
            }
            self.isLoaded = true;
        }
        @finally
        {
            free(bytes);
        }

        return self;
    }
    return nil;
}

- (nullable instancetype)initWithBytes:(UInt8*)bytes
                            byteLength:(UInt64)length
                                 error:(NSError**)error
{
    if (self = [super init])
    {
        BOOL ok = [self import:bytes byteLength:length error:error];
        if (!ok)
        {
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
- (nullable instancetype)initWithResource:(NSString*)resourceName
                            withExtension:(NSString*)extension
                                    error:(NSError**)error
{
    NSString* filepath = [[NSBundle mainBundle] pathForResource:resourceName ofType:extension];
    NSURL* fileUrl = [NSURL fileURLWithPath:filepath];
    NSData* fileData = [NSData dataWithContentsOfURL:fileUrl];
    UInt8* bytePtr = (UInt8*)[fileData bytes];
    return [self initWithBytes:bytePtr byteLength:fileData.length error:error];
}

/*
 * Creates a RiveFile from a binary resource, and assumes the resource extension is '.riv'
 */
- (nullable instancetype)initWithResource:(NSString*)resourceName error:(NSError**)error
{
    return [self initWithResource:resourceName withExtension:@"riv" error:error];
}

/*
 * Creates a RiveFile from an HTTP url
 */
- (nullable instancetype)initWithHttpUrl:(NSString*)url withDelegate:(id<RiveFileDelegate>)delegate
{
    self.isLoaded = false;
    if (self = [super init])
    {
        self.delegate = delegate;
        // Set up the http download task
        NSURL* URL = [NSURL URLWithString:url];
        // TODO: we are still adding 8MB of memory when we load our first http url.
        // note: Could use shared session.
        NSURLSession* session = [NSURLSession
            sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        NSURLSessionTask* task = [session
            downloadTaskWithURL:URL
              completionHandler:^(NSURL* location, NSURLResponse* response, NSError* error) {
                if (!error)
                {
                    // Load the data into the reader
                    NSData* data = [NSData dataWithContentsOfURL:location];
                    UInt8* bytes = (UInt8*)[data bytes];
                    // TODO: Do something with this error the proper way with delegates.
                    NSError* error = nil;
                    [self import:bytes byteLength:[data length] error:&error];
                    self.isLoaded = true;
                    dispatch_async(dispatch_get_main_queue(), ^{
                      if ([[NSThread currentThread] isMainThread])
                      {
                          if ([self.delegate respondsToSelector:@selector(riveFileDidLoad:error:)])
                          {
                              NSError* error = nil;
                              [self.delegate riveFileDidLoad:self error:&error];
                          }
                      }
                    });
                }
              }];

        // Kick off the http download
        [task resume];
        [session finishTasksAndInvalidate];

        // Return the as yet uninitialized RiveFile
        return self;
    }

    return nil;
}

- (BOOL)import:(UInt8*)bytes byteLength:(UInt64)length error:(NSError**)error
{
    rive::ImportResult result;
    RenderContext* renderContext = [[RenderContextManager shared] getDefaultContext];
    assert(renderContext);
    rive::Factory* factory = [renderContext factory];
    auto file = rive::File::import(rive::Span(bytes, length), factory, &result);
    if (result == rive::ImportResult::success)
    {
        riveFile = std::move(file);
        return true;
    }

    switch (result)
    {
        case rive::ImportResult::unsupportedVersion:
            *error =
                [NSError errorWithDomain:RiveErrorDomain
                                    code:RiveUnsupportedVersion
                                userInfo:@{
                                    NSLocalizedDescriptionKey : @"Unsupported Rive File Version",
                                    @"name" : @"UnsupportedVersion"
                                }];
            break;
        case rive::ImportResult::malformed:
            *error = [NSError errorWithDomain:RiveErrorDomain
                                         code:RiveMalformedFile
                                     userInfo:@{
                                         NSLocalizedDescriptionKey : @"Malformed Rive File.",
                                         @"name" : @"Malformed"
                                     }];
            break;
        default:
            *error = [NSError errorWithDomain:RiveErrorDomain
                                         code:RiveUnknownError
                                     userInfo:@{
                                         NSLocalizedDescriptionKey : @"Unknown error loading file.",
                                         @"name" : @"Unknown"
                                     }];
            break;
    }
    return false;
}

- (RiveArtboard*)artboard:(NSError**)error
{
    auto artboard = riveFile->artboardDefault();
    if (artboard == nullptr)
    {
        *error = [NSError errorWithDomain:RiveErrorDomain
                                     code:RiveNoArtboardsFound
                                 userInfo:@{
                                     NSLocalizedDescriptionKey : @"No Artboards Found.",
                                     @"name" : @"NoArtboardsFound"
                                 }];
        return nil;
    }
    else
    {
        return [[RiveArtboard alloc] initWithArtboard:std::move(artboard)];
    }
}

- (NSInteger)artboardCount
{
    return riveFile->artboardCount();
}

- (RiveArtboard*)artboardFromIndex:(NSInteger)index error:(NSError**)error
{
    auto artboard = riveFile->artboardAt(index);
    if (artboard == nullptr)
    {
        *error = [NSError
            errorWithDomain:RiveErrorDomain
                       code:RiveNoArtboardFound
                   userInfo:@{
                       NSLocalizedDescriptionKey : [NSString
                           stringWithFormat:@"No Artboard Found at index %ld.", (long)index],
                       @"name" : @"NoArtboardFound"
                   }];
        return nil;
    }
    return [[RiveArtboard alloc] initWithArtboard:std::move(artboard)];
}

- (RiveArtboard*)artboardFromName:(NSString*)name error:(NSError**)error
{
    std::string stdName = std::string([name UTF8String]);
    auto artboard = riveFile->artboardNamed(stdName);
    if (artboard == nullptr)
    {
        *error = [NSError errorWithDomain:RiveErrorDomain
                                     code:RiveNoArtboardFound
                                 userInfo:@{
                                     NSLocalizedDescriptionKey : [NSString
                                         stringWithFormat:@"No Artboard Found with name %@.", name],
                                     @"name" : @"NoArtboardFound"
                                 }];
        return nil;
    }
    else
    {
        return [[RiveArtboard alloc] initWithArtboard:std::move(artboard)];
    }
}

- (NSArray*)artboardNames
{
    NSMutableArray* artboardNames = [NSMutableArray array];

    for (NSUInteger i = 0; i < [self artboardCount]; i++)
    {
        [artboardNames addObject:[[self artboardFromIndex:i error:nil] name]];
    }
    return artboardNames;
}

/// Clean up rive file
- (void)dealloc
{
    riveFile.reset(nullptr);
}

@end
