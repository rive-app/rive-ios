//
//  RiveView.h
//  RiveRuntime
//
//  Created by Matt Sullivan on 4/29/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#ifndef RiveView_h
#define RiveView_h

#import "Rive.h"
#import <UIKit/UIKit.h>

 NS_ASSUME_NONNULL_BEGIN

 @interface RiveView : UIView

 - (void)updateArtboard:(RiveArtboard*)artboard;

 @end

NS_ASSUME_NONNULL_END

#endif /* RiveView_h */
