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

NS_ASSUME_NONNULL_BEGIN

@interface RiveFont : NSObject
@end

@interface RiveRenderImage : NSObject
@end

@interface RiveAudio : NSObject
@end

/*
 * RiveFactory
 */
@interface RiveFactory : NSObject
- (RiveFont*)decodeFont:(NSData*)data;
- (RiveRenderImage*)decodeImage:(NSData*)data;
- (RiveAudio*)decodeAudio:(NSData*)data;
@end

NS_ASSUME_NONNULL_END

#endif /* RiveFactory_h */
