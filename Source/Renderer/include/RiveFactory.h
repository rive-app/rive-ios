//
//  RiveFactory.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 08/11/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

#ifndef RiveFactory_h
#define RiveFactory_h

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIFont.h>
#else
#import <AppKit/NSFont.h>
#endif

@class RiveFont;

NS_ASSUME_NONNULL_BEGIN

DEPRECATED_MSG_ATTRIBUTE("The legacy image API is deprecated. Use Image from "
                         "the concurrency runtime instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#loading-referenced-assets")
@interface RiveRenderImage : NSObject
- (nullable instancetype)initWithData:(NSData*)data;
@end

DEPRECATED_MSG_ATTRIBUTE("The legacy audio API is deprecated. Use Audio from "
                         "the concurrency runtime instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#loading-referenced-assets")
@interface RiveAudio : NSObject
@end

/*
 * RiveFactory
 */
DEPRECATED_MSG_ATTRIBUTE("The legacy asset decoding API is deprecated. Use "
                         "Worker decoding APIs instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#loading-referenced-assets")
@interface RiveFactory : NSObject
- (RiveFont*)decodeFont:(NSData*)data;
#if TARGET_OS_IPHONE || TARGET_OS_VISION || TARGET_OS_TV
- (nullable RiveFont*)decodeUIFont:(UIFont*)data NS_SWIFT_NAME(decodeFont(_:));
#else
- (nullable RiveFont*)decodeNSFont:(NSFont*)data NS_SWIFT_NAME(decodeFont(_:));
#endif
- (RiveRenderImage*)decodeImage:(NSData*)data;
- (nullable RiveAudio*)decodeAudio:(NSData*)data;
@end

NS_ASSUME_NONNULL_END

#endif /* RiveFactory_h */
