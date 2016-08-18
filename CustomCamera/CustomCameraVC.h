//
//  CustomCameraVC.h
//  yiliao
//
//  Created by 蜘蜘纺 on 16/7/5.
//  Copyright © 2016年 GT. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CustomCameraVCDelegate <NSObject>

@optional
- (void)photoCapViewController:(UIViewController *)viewController didFinishDismissWithImage:(UIImage *)image;

@end

@interface CustomCameraVC : UIViewController <CustomCameraVCDelegate>

@property(nonatomic,weak) id<CustomCameraVCDelegate> delegate;

- (void)photoCapViewController:(UIViewController *)viewController didFinishDismissWithImage:(UIImage *)image;


@end
