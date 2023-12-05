//
//  util.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 10/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

#ifndef util_h
#define util_h

NS_ASSUME_NONNULL_BEGIN

@interface Util : NSObject
+ (RiveFile*)loadTestFile:(NSString*)name error:(NSError**)error;
+ (NSData*)loadTestData:(NSString*)name;
@end

@interface TestSessionDownloadTask : NSURLSessionDownloadTask
@end

@interface TestSession : NSURLSession
- (NSMutableArray*)getUrls;
@end

NS_ASSUME_NONNULL_END

#endif /* util_h */
