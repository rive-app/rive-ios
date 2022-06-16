//
//  RiveScene.hpp
//  RiveRuntime
//
//  Created by Zachary Duncan on 6/16/22.
//  Copyright © 2022 Rive. All rights reserved.
//

#ifndef RiveScene_hpp
#define RiveScene_hpp

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RiveScene : NSObject

- (NSString *)name;
- (CGRect)bounds;
- (bool)advanceBy:(double)elapsedSeconds;

@end

NS_ASSUME_NONNULL_END

#endif /* RiveScene_hpp */
