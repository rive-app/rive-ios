//
//  RiveRenderer.h
//  RiveRuntime
//
//  Created by Matt Sullivan on 8/31/20.
//  Copyright © 2020 Rive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RiveRenderer : NSObject

-(instancetype) initWithContext:(UIBezierPath *) context;

@end

NS_ASSUME_NONNULL_END
