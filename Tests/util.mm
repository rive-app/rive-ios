//
//  util.m
//  RiveRuntimeTests
//
//  Created by Maxwell Talbot on 10/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

#import "Rive.h"
#import "util.h"

NS_ASSUME_NONNULL_BEGIN

@implementation Util

+ (NSData*)loadTestData:(NSString*)name
{
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    NSString* path = [bundle pathForResource:name ofType:@"riv"];
    NSData* nsData = [NSData dataWithContentsOfFile:path];
    return nsData;
}

+ (RiveFile*)loadTestFile:(NSString*)name error:(NSError**)error
{
    NSData* nsData = [self loadTestData:name];
    RiveFile* file = [[RiveFile alloc] initWithData:nsData loadCdn:false error:error];
    return file;
}
@end

typedef void (^CompletionHandler)(NSURL* location, NSURLResponse* response, NSError* error);

@implementation TestSessionDownloadTask
{}

- (void)resume
{};

@end

@implementation TestSession
{
    NSMutableArray* urls;
}

- (instancetype)init
{
    TestSession* session = [super init];
    session->urls = [[NSMutableArray alloc] init];
    return session;
}

- (NSURLSessionDownloadTask*)downloadTaskWithURL:(NSURL*)url
                               completionHandler:(CompletionHandler)completionHandler
{
    [urls addObject:url];
    return [[TestSessionDownloadTask alloc] init];
}

- (void)finishTasksAndInvalidate
{}

- (nonnull NSMutableArray*)getUrls
{
    return urls;
}

@end

NS_ASSUME_NONNULL_END
