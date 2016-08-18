//
//  ViewController.m
//  CustomCamera
//
//  Created by 蜘蜘纺 on 16/7/7.
//  Copyright © 2016年 吴绍叶. All rights reserved.
//

#import "ViewController.h"
#import "CustomCameraVC.h"

@interface ViewController ()
{
    UIButton *btn;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    btn=[[UIButton alloc] init];
    btn.frame=CGRectMake(60., self.view.frame.size.height-80, self.view.frame.size.width-120, 60);
    [btn setTitle:@"Open" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
}

- (void)btnClick {
    
    
    CustomCameraVC *vc = [[CustomCameraVC alloc] init];
//    vc.delegate = self;
    [self presentViewController:vc animated:YES completion:nil];
    
}

@end
