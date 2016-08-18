//
//  CustomCameraVC.m
//  yiliao
//
//  Created by 蜘蜘纺 on 16/7/5.
//  Copyright © 2016年 GT. All rights reserved.
//

#import "CustomCameraVC.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width

@interface CustomCameraVC ()<UIGestureRecognizerDelegate>

/** 取消按钮 */
@property (strong,nonatomic) UIButton *cancelButton;
/** 网格开关 */
@property (strong,nonatomic) UIButton *gridButton;
/** 九宫格View */
@property (strong,nonatomic) UIImageView *gridView;
/** 切换 前置摄像头/后置摄像头 */
@property (strong,nonatomic) UIButton *chooseCameraBtn;
/** 闪光灯 */
@property (strong, nonatomic) UIButton *flashButton;
/** 拍照 */
@property (strong,nonatomic) UIButton *snapButton;
/** 完成按钮 */
@property (strong,nonatomic) UIButton *doneButton;

//AVFoundation
@property (nonatomic) dispatch_queue_t sessionQueue;
/**
 *  AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
 */
@property (nonatomic, strong) AVCaptureSession* session;
/**
 *  输入设备
 */
@property (nonatomic, strong) AVCaptureDeviceInput* videoInput;
/**
 *  照片输出流
 */
@property (nonatomic, strong) AVCaptureStillImageOutput* stillImageOutput;
/**
 *  预览图层
 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer* previewLayer;
/**
 *  记录开始的缩放比例
 */
@property(nonatomic,assign)CGFloat beginGestureScale;
/**
 *  最后的缩放比例
 */
@property(nonatomic,assign)CGFloat effectiveScale;
@end

@implementation CustomCameraVC {
    
    BOOL isUsingFrontFacingCamera;
    BOOL isUsingGrid;
    
    UIView *_topView;
}

//- (BOOL)prefersStatusBarHidden
//{
//    return YES;
//}

- (void)viewDidLoad {
    [super viewDidLoad];

//    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    [self initAVCaptureSession];
    
    [self setUpGesture];
    
    isUsingFrontFacingCamera = NO;
    isUsingGrid = NO;

    self.effectiveScale = self.beginGestureScale = 1.0f;

}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    
    if (self.session) {
        
        [self.session startRunning];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [super viewDidDisappear:YES];
    
    if (self.session) {
        
        [self.session stopRunning];
    }
//    [[UIApplication sharedApplication] setStatusBarHidden:NO];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark private method
- (void)initAVCaptureSession{
    
    self.session = [[AVCaptureSession alloc] init];
    
    NSError *error;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [device lockForConfiguration:nil];
    //设置闪光灯为自动
    [device setFlashMode:AVCaptureFlashModeAuto];
    [device unlockForConfiguration];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //输出设置。AVVideoCodecJPEG   输出jpeg格式图片
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    NSLog(@"%f",SCREEN_WIDTH);
    self.previewLayer.frame = CGRectMake(0, 0,SCREEN_WIDTH, SCREEN_HEIGHT);
    [self.view.layer addSublayer:self.previewLayer];
    
    _topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 116)];
//    topView.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.500];
    _topView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_topView];
    
    // 高斯模糊效果
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *effectview = [[UIVisualEffectView alloc] initWithEffect:blur];
    effectview.alpha = 0.8f;
    effectview.frame = _topView.bounds;
    [_topView addSubview:effectview];
    
    // 三张图片imageView
    for (int i = 0; i < 3; i++) {
        UIImageView *_imageView = [[UIImageView alloc] init];
        int insertW = (SCREEN_WIDTH-300)/4;
        _imageView.frame = CGRectMake(i%3*(insertW+100)+insertW, 8, 100,100);
        //        _imageView.userInteractionEnabled = YES;
        //        _imageView.image;
        //        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageBtnClicked:)];
        //        [_imageView addGestureRecognizer:singleTap];
        _imageView.tag = 113+i;
        [_topView addSubview:_imageView];
        
        UIButton *deleteBtn = [[UIButton alloc] initWithFrame:CGRectMake(70, 0, 30, 30)];
        [deleteBtn setImage:[UIImage imageNamed:@"search_delete_off@3x"] forState:UIControlStateNormal];
        [_imageView addSubview:deleteBtn];
        
        CAShapeLayer *border = [CAShapeLayer layer];
        border.strokeColor = [UIColor colorWithWhite:0.800 alpha:1.000].CGColor;
        border.fillColor = nil;
        border.path = [UIBezierPath bezierPathWithRect:_imageView.bounds].CGPath;
        border.frame = _imageView.bounds;
        border.lineWidth = 2.f;
        _imageView.layer.masksToBounds = YES;
        _imageView.layer.cornerRadius = 8.f;
        border.lineCap = @"square";
        border.lineDashPattern = @[@6, @6];
        [_imageView.layer addSublayer:border];
        
    }
    _topView.hidden = YES;
    
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT-150, self.view.frame.size.width, 150)];
//    bottomView.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.500];
    bottomView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:bottomView];
    
    // 高斯模糊效果
    UIBlurEffect *blur2 = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *effectview2 = [[UIVisualEffectView alloc] initWithEffect:blur2];
    effectview2.alpha = 0.8f;
    effectview2.frame = bottomView.bounds;
    [bottomView addSubview:effectview2];
    
    // 拍照
    _snapButton = [[UIButton alloc] initWithFrame:CGRectMake((bottomView.frame.size.width/2)-(75/2), bottomView.frame.size.height - 13 - 75 , 75, 75)];
    [_snapButton setImage:[UIImage imageNamed:@"search_takephoto@3x"] forState:UIControlStateNormal];
    [_snapButton addTarget:self action:@selector(snapButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:_snapButton];
    
    // 取消
    _cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(30, _snapButton.frame.origin.x+30, 75, 75)];
    _cancelButton.contentMode = UIViewContentModeCenter;
    [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
//    [_cancelButton setImage:[UIImage imageNamed:@"search_photograph_close@3x"] forState:UIControlStateNormal];
    [_cancelButton addTarget:self action:@selector(cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:_cancelButton];
    
    // 完成
    _doneButton = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH-105, _cancelButton.frame.origin.x+30, 75, 75)];
    _doneButton.contentMode = UIViewContentModeCenter;
    [_doneButton setTitle:@"完成" forState:UIControlStateNormal];
    [bottomView addSubview:_doneButton];
    
    // 闪光灯
    _flashButton = [[UIButton alloc] initWithFrame:CGRectMake(bottomView.frame.size.width-60, 0, 60 , 60)];
    _flashButton.contentMode = UIViewContentModeCenter;
    [_flashButton setImage:[UIImage imageNamed:@"search_photograph_lamp_off@3x"] forState:UIControlStateNormal];
    [_flashButton addTarget:self action:@selector(flashButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:_flashButton];
    
    // 切换摄像头
    _chooseCameraBtn = [[UIButton alloc] initWithFrame:CGRectMake(bottomView.frame.size.width-120, 0, 60, 60)];
    _chooseCameraBtn.contentMode = UIViewContentModeCenter;
    [_chooseCameraBtn setImage:[UIImage imageNamed:@"search_photograph_Flip@3x"] forState:UIControlStateNormal];
    [_chooseCameraBtn addTarget:self action:@selector(chooseCameraButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:_chooseCameraBtn];
    
    
    //网格 九宫格
    _gridButton = [[UIButton alloc] initWithFrame:CGRectMake(bottomView.frame.size.width-180, 0, 60, 60)];
    _gridButton.contentMode = UIViewContentModeCenter;
    [_gridButton setImage:[UIImage imageNamed:@"search_photograph_grid@3x"] forState:UIControlStateNormal];
    [_gridButton addTarget:self action:@selector(gridButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:_gridButton];
    
    // 九宫格view
    _gridView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, SCREEN_HEIGHT-150)];
    _gridView.image = [UIImage imageNamed:@"search_grid@3x"];
    [self.view addSubview:_gridView];
    _gridView.hidden = YES;
}

- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}

#pragma mark -- 点击取消
- (void)cancelButtonClick {
    
    [self dismissViewControllerAnimated:YES completion:^{
//        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }];
}


#pragma mark -- 点击拍照
- (void)snapButtonClick {
    
    NSLog(@"takephotoClick...");
    [UIView animateWithDuration:3 animations:^{
        _topView.hidden = NO;
    }];

    AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    [stillImageConnection setVideoOrientation:avcaptureOrientation];
    [stillImageConnection setVideoScaleAndCropFactor:self.effectiveScale];
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                                    imageDataSampleBuffer,
                                                                    kCMAttachmentMode_ShouldPropagate);
        
        ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
        if (author == ALAuthorizationStatusRestricted || author == ALAuthorizationStatusDenied){
            //无权限
            
            return ;
        }
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageDataToSavedPhotosAlbum:jpegData metadata:(__bridge id)attachments completionBlock:^(NSURL *assetURL, NSError *error) {
            
            
        }];
        
    }];
}

#pragma mark - CustomCameraVCDelegate
- (void)photoCapViewController:(UIViewController *)viewController didFinishDismissWithImage:(UIImage *)image;
{
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        
////        for (int i = 0; i < image.count; i++) {
//
//                DLog(@"image---%@",image);
//                UIImageView *imageView = (UIImageView *)[self.view viewWithTag:113];
//                [imageView setImage:image];
////        }
//        
//    });
    dispatch_sync(dispatch_get_main_queue(), ^{
    
        NSLog(@"image---%@",image);
        UIImageView *imageView = (UIImageView *)[self.view viewWithTag:113];
        [imageView setImage:image];
        
        
    });
    
}

#pragma mark -- 闪光灯
- (void)flashButtonClick {
    
    NSLog(@"flashButtonClick");
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //修改前必须先锁定
    [device lockForConfiguration:nil];
    //必须判定是否有闪光灯，否则如果没有闪光灯会崩溃
    if ([device hasFlash]) {
        
        if (device.flashMode == AVCaptureFlashModeOff) {
            device.flashMode = AVCaptureFlashModeOn;
            NSLog(@"打开");
            [_flashButton setImage:[UIImage imageNamed:@"search_photograph_lamp_on@3x"] forState:UIControlStateNormal];
            
        } else if (device.flashMode == AVCaptureFlashModeOn) {
            
            device.flashMode = AVCaptureFlashModeAuto;
            NSLog(@"自动");
            [_flashButton setImage:[UIImage imageNamed:@"search_photograph_lamp_automatic@3x"] forState:UIControlStateNormal];
            
        } else if (device.flashMode == AVCaptureFlashModeAuto) {
            
            device.flashMode = AVCaptureFlashModeOff;
            NSLog(@"关闭");
            [_flashButton setImage:[UIImage imageNamed:@"search_photograph_lamp_off@3x"] forState:UIControlStateNormal];
        }
        
    } else {
        
        NSLog(@"设备不支持闪光灯");
    }
    [device unlockForConfiguration];

    
}

#pragma mark - 切换摄像头
- (void)chooseCameraButtonClick {
    
    _chooseCameraBtn.selected = !_chooseCameraBtn.selected;
    AVCaptureDevicePosition desiredPosition;
    if (isUsingFrontFacingCamera){
        desiredPosition = AVCaptureDevicePositionBack;
    }else{
        desiredPosition = AVCaptureDevicePositionFront;
    }
    
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            [self.previewLayer.session beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in self.previewLayer.session.inputs) {
                [[self.previewLayer session] removeInput:oldInput];
            }
            [self.previewLayer.session addInput:input];
            [self.previewLayer.session commitConfiguration];
            break;
        }
    }
    
    isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
    
}

#pragma mark - 九宫格
- (void)gridButtonClick {
    
    NSLog(@"gridButtonClick");
    _gridButton.selected = !_gridButton.selected;
    
    if (!_gridButton.selected){
        NSLog(@"不显示网格");
        _gridView.hidden = YES;
        
    }else{
        NSLog(@"显示网格");
        _gridView.hidden = NO;

        if (_topView.hidden == YES) {
            
            _gridView.image = [UIImage imageNamed:@"search_gridBig@3x"];
            
        } else {
            
            _gridView.frame = CGRectMake(0, 116, SCREEN_WIDTH, SCREEN_HEIGHT-116-150);
            _gridView.image = [UIImage imageNamed:@"search_grid@3x"];
        }

    }
    
}

#pragma mark - 创建手势
- (void)setUpGesture{
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    pinch.delegate = self;
    [self.view addGestureRecognizer:pinch];
}

#pragma mark gestureRecognizer delegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        self.beginGestureScale = self.effectiveScale;
    }
    return YES;
}

//缩放手势 用于调整焦距
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer{
    
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [recognizer numberOfTouches], i;
    for ( i = 0; i < numTouches; ++i ) {
        CGPoint location = [recognizer locationOfTouch:i inView:self.view];
        CGPoint convertedLocation = [self.previewLayer convertPoint:location fromLayer:self.previewLayer.superlayer];
        if ( ! [self.previewLayer containsPoint:convertedLocation] ) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    
    if ( allTouchesAreOnThePreviewLayer ) {
        
        self.effectiveScale = self.beginGestureScale * recognizer.scale;
        if (self.effectiveScale < 1.0){
            self.effectiveScale = 1.0;
        }
        
        NSLog(@"%f-------------->%f------------recognizerScale%f",self.effectiveScale,self.beginGestureScale,recognizer.scale);
        
        CGFloat maxScaleAndCropFactor = [[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
        
        NSLog(@"%f",maxScaleAndCropFactor);
        if (self.effectiveScale > maxScaleAndCropFactor)
            self.effectiveScale = maxScaleAndCropFactor;
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:.025];
        [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale)];
        [CATransaction commit];
        
    }
    
}




@end
