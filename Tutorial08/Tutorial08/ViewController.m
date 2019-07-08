//
//  ViewController.m
//  Tutorial08
//
//  Created by heyonly on 2019/6/19.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "ViewController.h"
#import "OpenGLFrameCacheView.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()
@property (strong, nonatomic) OpenGLFrameCacheView *frameCacheView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    UIImage *image = [UIImage imageNamed:@"timg.jpeg"];
//    CGRect frame = AVMakeRectWithAspectRatioInsideRect(image.size, self.view.bounds);
//
//    self.frameCacheView = [[OpenGLFrameCacheView alloc] initWithFrame:frame];
//    self.frameCacheView.contentScaleFactor = image.size.width / frame.size.width;
//    [self.view addSubview:self.frameCacheView];
}
- (IBAction)slideChangeValue:(UISlider *)sender {
    [self.frameCacheView updateSaturation:sender.value];
}

- (IBAction)temperatureValueChange:(UISlider *)sender {
    [self.frameCacheView updateTemperature:sender.value];
}

@end
