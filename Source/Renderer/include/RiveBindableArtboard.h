//
//  RiveBindableArtboard.h
//  RiveRuntime
//
//  Created by David Skuza on 7/14/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

DEPRECATED_MSG_ATTRIBUTE("The legacy bindable artboard API is deprecated. Use "
                         "Artboard from the concurrency runtime instead. See "
                         "https://rive.app/docs/runtimes/apple/"
                         "migrating-from-legacy#bindable-artboards")
@interface RiveBindableArtboard : NSObject

@property(nonatomic, readonly) NSString* name;

@end

NS_ASSUME_NONNULL_END
