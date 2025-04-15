//
//  WeakContainer.h
//  RiveRuntime
//
//  Created by David Skuza on 3/13/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WeakContainer<WeakType> : NSObject

@property(nonatomic, nullable, weak) WeakType object;

@end

NS_ASSUME_NONNULL_END
