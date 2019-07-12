//
//  ViewController.m
//  Tutorial05
//
//  Created by heyonly on 2019/7/11.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "ViewController.h"
#import "OpenGLKView.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet OpenGLKView *openGLKView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.openGLKView = (OpenGLKView *)self.view;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {

    [self.openGLKView render];
}

@end
