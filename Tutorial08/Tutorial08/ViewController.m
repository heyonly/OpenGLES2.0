//
//  ViewController.m
//  Tutorial08
//
//  Created by heyonly on 2019/7/17.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    EAGLContext                 *_context;
    
}
@property (nonatomic, strong) GLKBaseEffect *baseEffect;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    GLKView *view = (GLKView *)self.view;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:view.context];
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.light0.enabled = GL_TRUE;
    
    self.baseEffect.light0.ambientColor = GLKVector4Make(
                                                         0.6f, // Red
                                                         0.6f, // Green
                                                         0.6f, // Blue
                                                         1.0f);// Alpha
    self.baseEffect.light0.position = GLKVector4Make(
                                                     1.0f,
                                                     0.8f,
                                                     0.4f,
                                                     0.0f);
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
}
@end
