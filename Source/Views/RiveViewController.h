//
//  RiveViewController.h
//  RiveRuntime
//
//  Created by Matt Sullivan on 4/29/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#ifndef RiveViewController_h
#define RiveViewController_h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

 @interface RiveViewController : UIViewController

 -(instancetype)initWithResource:(NSString *)resource withExtension:(NSString *)extension;

 @end

 NS_ASSUME_NONNULL_END

#endif /* RiveViewController_h */
