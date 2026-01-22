//
//  RiveFile.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <RenderContext.h>
#import <RenderContextManager.h>
#import <RiveFileAssetLoader.h>
#import <CDNFileAssetLoader.h>
#import <RiveRuntime/RiveRuntime-Swift.h>

#import <FileAssetLoaderAdapter.hpp>

/*
 * RiveFile
 */
@implementation RiveFile
{
    rive::rcp<rive::File> riveFile;
    rive::rcp<rive::FileAssetLoader> fileAssetLoader;
    RenderContext* _renderContext;
}

+ (uint)majorVersion
{
    return UInt8(rive::File::majorVersion);
}
+ (uint)minorVersion
{
    return UInt8(rive::File::minorVersion);
}

- (nullable instancetype)initWithByteArray:(NSArray*)array
                                   loadCdn:(bool)cdn
                                     error:(NSError**)error
{
    if (self = [super init])
    {
        UInt8* bytes;
        @try
        {
            if (array.count > SIZE_MAX / sizeof(UInt64)) {
                return nil;
            }

            bytes = (UInt8*)calloc(array.count, sizeof(UInt64));

            [array enumerateObjectsUsingBlock:^(
                       NSNumber* number, NSUInteger index, BOOL* stop) {
              bytes[index] = number.unsignedIntValue;
            }];
            BOOL ok = [self import:bytes
                        byteLength:array.count
                           loadCdn:cdn
                             error:error];
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

- (nullable instancetype)initWithByteArray:(NSArray*)array
                                   loadCdn:(bool)cdn
                         customAssetLoader:(LoadAsset)customAssetLoader
                                     error:(NSError**)error
{
    if (self = [super init])
    {
        UInt8* bytes;
        @try
        {
            bytes = (UInt8*)calloc(array.count, sizeof(UInt64));

            [array enumerateObjectsUsingBlock:^(
                       NSNumber* number, NSUInteger index, BOOL* stop) {
              bytes[index] = number.unsignedIntValue;
            }];
            BOOL ok = [self import:bytes
                        byteLength:array.count
                           loadCdn:cdn
                 customAssetLoader:customAssetLoader
                             error:error];
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

// QUESTION: deprecate? init with NSData feels like its all we need?
- (nullable instancetype)initWithBytes:(UInt8*)bytes
                            byteLength:(UInt64)length
                               loadCdn:(bool)cdn
                                 error:(NSError**)error
{
    if (self = [super init])
    {
        BOOL ok = [self import:bytes byteLength:length loadCdn:cdn error:error];
        if (!ok)
        {
            return nil;
        }
        self.isLoaded = true;
        return self;
    }
    return nil;
}
- (nullable instancetype)initWithBytes:(UInt8*)bytes
                            byteLength:(UInt64)length
                               loadCdn:(bool)cdn
                     customAssetLoader:(LoadAsset)customAssetLoader
                                 error:(NSError**)error
{
    if (self = [super init])
    {
        BOOL ok = [self import:bytes
                    byteLength:length
                       loadCdn:cdn
             customAssetLoader:customAssetLoader
                         error:error];
        if (!ok)
        {
            return nil;
        }
        self.isLoaded = true;
        return self;
    }
    return nil;
}

- (nullable instancetype)initWithData:(NSData*)data
                              loadCdn:(bool)cdn
                                error:(NSError**)error
{
    UInt8* bytes = (UInt8*)[data bytes];
    return [self initWithBytes:bytes
                    byteLength:data.length
                       loadCdn:cdn
                         error:error];
}
- (nullable instancetype)initWithData:(NSData*)data
                              loadCdn:(bool)cdn
                    customAssetLoader:(LoadAsset)customAssetLoader
                                error:(NSError**)error
{
    UInt8* bytes = (UInt8*)[data bytes];
    return [self initWithBytes:bytes
                    byteLength:data.length
                       loadCdn:cdn
             customAssetLoader:customAssetLoader
                         error:error];
}

/*
 * Creates a RiveFile from a binary resource
 */
- (nullable instancetype)initWithResource:(NSString*)resourceName
                            withExtension:(NSString*)extension
                                  loadCdn:(bool)cdn
                                    error:(NSError**)error
{
    // QUESTION: good ideas on how we can combine a few of these into following
    // the same path better?
    //    there's a lot of copy pasta here.

    [RiveLogger logLoadingFromResource:[NSString stringWithFormat:@"%@.%@",
                                                                  resourceName,
                                                                  extension]];
    NSString* filepath = [[NSBundle mainBundle] pathForResource:resourceName
                                                         ofType:extension];
    NSURL* fileUrl = [NSURL fileURLWithPath:filepath];
    NSData* fileData = [NSData dataWithContentsOfURL:fileUrl];

    return [self initWithData:fileData loadCdn:cdn error:error];
}

/*
 * Creates a RiveFile from a binary resource, and assumes the resource extension
 * is '.riv'
 */
- (nullable instancetype)initWithResource:(NSString*)resourceName
                                  loadCdn:(bool)cdn
                                    error:(NSError**)error
{
    return [self initWithResource:resourceName
                    withExtension:@"riv"
                          loadCdn:cdn
                            error:error];
}

- (nullable instancetype)
     initWithResource:(nonnull NSString*)resourceName
              loadCdn:(bool)cdn
    customAssetLoader:(nonnull LoadAsset)customAssetLoader
                error:(NSError* __autoreleasing _Nullable* _Nullable)error
{
    return [self initWithResource:resourceName
                    withExtension:@"riv"
                          loadCdn:cdn
                customAssetLoader:customAssetLoader
                            error:error];
}

- (nullable instancetype)
     initWithResource:(nonnull NSString*)resourceName
        withExtension:(nonnull NSString*)extension
              loadCdn:(bool)cdn
    customAssetLoader:(nonnull LoadAsset)customAssetLoader
                error:(NSError* __autoreleasing _Nullable* _Nullable)error
{
    [RiveLogger logLoadingFromResource:[NSString stringWithFormat:@"%@.%@",
                                                                  resourceName,
                                                                  extension]];
    NSString* filepath = [[NSBundle mainBundle] pathForResource:resourceName
                                                         ofType:extension];
    NSURL* fileUrl = [NSURL fileURLWithPath:filepath];
    NSData* fileData = [NSData dataWithContentsOfURL:fileUrl];
    return [self initWithData:fileData
                      loadCdn:cdn
            customAssetLoader:customAssetLoader
                        error:error];
}

/*
 * Creates a RiveFile from an HTTP url
 */
- (nullable instancetype)initWithHttpUrl:(NSString*)url
                                 loadCdn:(bool)loadCdn
                            withDelegate:(id<RiveFileDelegate>)delegate
{
    return [self initWithHttpUrl:url
                         loadCdn:loadCdn
               customAssetLoader:^bool(
                   RiveFileAsset* asset, NSData* data, RiveFactory* factory) {
                 return false;
               }
                    withDelegate:delegate];
}

- (nullable instancetype)initWithHttpUrl:(nonnull NSString*)url
                                 loadCdn:(bool)cdn
                       customAssetLoader:(nonnull LoadAsset)customAssetLoader
                            withDelegate:(nonnull id<RiveFileDelegate>)delegate
{
    [RiveLogger logLoadingFromResource:url];
    self.isLoaded = false;
    if (self = [super init])
    {
        self.delegate = delegate;
        // Set up the http download task
        NSURL* URL = [NSURL URLWithString:url];

        // TODO: we are still adding 8MB of memory when we load our first http
        // url.
        NSURLSessionTask* task = [[NSURLSession sharedSession]
            downloadTaskWithURL:URL
              completionHandler:^(
                  NSURL* location, NSURLResponse* response, NSError* error) {
                if (!error)
                {
                    // Load the data into the reader
                    NSData* data = [NSData dataWithContentsOfURL:location];
                    UInt8* bytes = (UInt8*)[data bytes];
                    // TODO: Do something with this error the proper way with
                    // delegates.
                    NSError* error = nil;
                    [self import:bytes
                               byteLength:[data length]
                                  loadCdn:true
                        customAssetLoader:customAssetLoader
                                    error:&error];
                    self.isLoaded = true;
                    [RiveLogger logLoadedFromURL:URL];
                    dispatch_async(dispatch_get_main_queue(), ^{
                      if (error)
                      {
                          if ([self.delegate respondsToSelector:@selector
                                             (riveFileDidError:)])
                          {
                              [self.delegate riveFileDidError:error];
                          }
                      }
                      else
                      {
                          if ([self.delegate respondsToSelector:@selector
                                             (riveFileDidLoad:error:)])
                          {
                              NSError* error = nil;
                              [self.delegate riveFileDidLoad:self error:&error];
                          }
                      }
                    });
                }
                else
                {
                    NSString* message = [NSString
                        stringWithFormat:@"Failed to load file from URL %@: %@",
                                         URL.absoluteString,
                                         error.localizedDescription];
                    [RiveLogger logFile:nil error:message];
                    dispatch_async(dispatch_get_main_queue(), ^{
                      if ([self.delegate
                              respondsToSelector:@selector(riveFileDidError:)])
                      {
                          [self.delegate riveFileDidError:error];
                      }
                    });
                }
              }];

        // Kick off the http download
        [task resume];
        return self;
    }

    return nil;
}

- (BOOL)import:(UInt8*)bytes
    byteLength:(UInt64)length
       loadCdn:(bool)loadCdn
         error:(NSError**)error
{
    return [self import:bytes
               byteLength:length
                  loadCdn:loadCdn
        customAssetLoader:^bool(
            RiveFileAsset* asset, NSData* data, RiveFactory* factory) {
          return false;
        }
                    error:error];
}
- (BOOL)import:(UInt8*)bytes
           byteLength:(UInt64)length
              loadCdn:(bool)loadCdn
    customAssetLoader:(LoadAsset)custom
                error:(NSError**)error
{
    rive::ImportResult result;
    _renderContext = [[RenderContextManager shared] newDefaultContext];
    assert(_renderContext);
    rive::Factory* factory = [_renderContext factory];

    FallbackFileAssetLoader* fallbackLoader =
        [[FallbackFileAssetLoader alloc] init];

    CustomFileAssetLoader* customAssetLoader =
        [[CustomFileAssetLoader alloc] initWithLoader:custom];
    [fallbackLoader addLoader:customAssetLoader];

    if (loadCdn)
    {
        CDNFileAssetLoader* cdnLoader = [[CDNFileAssetLoader alloc] init];
        [fallbackLoader addLoader:cdnLoader];
    }

    fileAssetLoader =
        rive::make_rcp<rive::FileAssetLoaderAdapter>(fallbackLoader);

    auto file = rive::File::import(
        rive::Span(bytes, length), factory, &result, fileAssetLoader.get());
    if (result == rive::ImportResult::success)
    {
        riveFile = file;
        return true;
    }

    switch (result)
    {
        case rive::ImportResult::unsupportedVersion:
        {
            NSString* message = @"Unsupported Rive File Version";
            [RiveLogger logFile:nil error:message];
            *error = [NSError errorWithDomain:RiveErrorDomain
                                         code:RiveUnsupportedVersion
                                     userInfo:@{
                                         NSLocalizedDescriptionKey : message,
                                         @"name" : @"UnsupportedVersion"
                                     }];
            break;
        }
        case rive::ImportResult::malformed:
        {
            NSString* message = @"Malformed Rive File.";
            [RiveLogger logFile:nil error:message];
            *error = [NSError errorWithDomain:RiveErrorDomain
                                         code:RiveMalformedFile
                                     userInfo:@{
                                         NSLocalizedDescriptionKey : message,
                                         @"name" : @"Malformed"
                                     }];
            break;
        }
        default:
        {
            NSString* message = @"Unknown error loading file.";
            [RiveLogger logFile:nil error:message];
            *error = [NSError errorWithDomain:RiveErrorDomain
                                         code:RiveUnknownError
                                     userInfo:@{
                                         NSLocalizedDescriptionKey : message,
                                         @"name" : @"Unknown"
                                     }];
            break;
        }
    }
    return false;
}

- (RiveArtboard*)artboard:(NSError**)error
{
    auto artboard = riveFile->artboardDefault();
    if (artboard == nullptr)
    {
        NSString* message = @"No Artboards Found.";
        [RiveLogger logFile:nil error:message];
        *error = [NSError errorWithDomain:RiveErrorDomain
                                     code:RiveNoArtboardsFound
                                 userInfo:@{
                                     NSLocalizedDescriptionKey : message,
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
        NSString* message = [NSString
            stringWithFormat:@"No Artboard Found at index %ld.", (long)index];
        [RiveLogger logFile:nil error:message];
        *error = [NSError errorWithDomain:RiveErrorDomain
                                     code:RiveNoArtboardFound
                                 userInfo:@{
                                     NSLocalizedDescriptionKey : message,
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
        NSString* message = [NSString
            stringWithFormat:@"No Artboard Found with name %@.", name];
        [RiveLogger logFile:nil error:message];
        *error = [NSError errorWithDomain:RiveErrorDomain
                                     code:RiveNoArtboardFound
                                 userInfo:@{
                                     NSLocalizedDescriptionKey : message,
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
        RiveArtboard* artboard = [self artboardFromIndex:i error:nil];
        if (artboard != nil)
        {
            [artboardNames addObject:[artboard name]];
        }
    }
    return artboardNames;
}

#pragma mark - Data Binding

- (NSUInteger)viewModelCount
{
    return riveFile->viewModelCount();
}

- (nullable id)viewModelAtIndex:(NSUInteger)index
{
    auto viewModel = riveFile->viewModelByIndex(index);
    if (viewModel == nullptr)
    {
        [RiveLogger logFileViewModelAtIndex:index found:NO];
        return nil;
    }
    [RiveLogger logFileViewModelAtIndex:index found:YES];
    return [[RiveDataBindingViewModel alloc] initWithViewModel:viewModel];
}

- (nullable id)viewModelNamed:(NSString*)name
{
    auto viewModel = riveFile->viewModelByName(std::string([name UTF8String]));
    if (viewModel == nullptr)
    {
        [RiveLogger logFileViewModelWithName:name found:NO];
        return nil;
    }
    [RiveLogger logFileViewModelWithName:name found:YES];
    return [[RiveDataBindingViewModel alloc] initWithViewModel:viewModel];
}

- (RiveDataBindingViewModel*)defaultViewModelForArtboard:(RiveArtboard*)artboard
{
    auto viewModel =
        riveFile->defaultArtboardViewModel(artboard.artboardInstance);
    if (viewModel == nullptr)
    {
        [RiveLogger logFileDefaultViewModelForArtboard:artboard found:NO];
        return nil;
    }
    [RiveLogger logFileDefaultViewModelForArtboard:artboard found:YES];
    return [[RiveDataBindingViewModel alloc] initWithViewModel:viewModel];
}

- (RiveBindableArtboard*)
    bindableArtboardWithName:(NSString*)name
                       error:(NSError* __autoreleasing _Nullable*)error
{
    std::string stdName = std::string([name UTF8String]);
    auto bindableArtboard = riveFile->bindableArtboardNamed(stdName);
    if (bindableArtboard == nullptr)
    {
        NSString* message = [NSString
            stringWithFormat:@"No Bindable Artboard Found with name %@.", name];
        [RiveLogger logFile:nil error:message];
        *error = [NSError errorWithDomain:RiveErrorDomain
                                     code:RiveNoArtboardFound
                                 userInfo:@{
                                     NSLocalizedDescriptionKey : message,
                                     @"name" : @"NoArtboardFound"
                                 }];
        return nil;
    }
    return [[RiveBindableArtboard alloc]
        initWithBindableArtboard:bindableArtboard];
}

- (RiveBindableArtboard*)defaultBindableArtboard:
    (NSError* __autoreleasing _Nullable*)error
{
    auto bindableArtboard = riveFile->bindableArtboardDefault();
    if (bindableArtboard == nullptr)
    {
        NSString* message = @"No Default Bindable Artboard Found.";
        [RiveLogger logFile:nil error:message];
        *error = [NSError errorWithDomain:RiveErrorDomain
                                     code:RiveNoArtboardFound
                                 userInfo:@{
                                     NSLocalizedDescriptionKey : message,
                                     @"name" : @"NoArtboardFound"
                                 }];
        return nil;
    }
    return [[RiveBindableArtboard alloc]
        initWithBindableArtboard:bindableArtboard];
}

/// Clean up rive file
- (void)dealloc
{
    riveFile = nullptr;
    fileAssetLoader = nullptr;
}

@end
