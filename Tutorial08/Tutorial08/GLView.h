//
//  GLView.h
//  OpenGLESDemo
//
//  Created by Yue on 17/1/13.
//  Copyright © 2017年 Yue. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLView : UIView
{


}

@property (nonatomic, assign) CGFloat temperature;
@property (nonatomic, assign) CGFloat saturation;

- (void)layoutGLViewWithImage:(UIImage *)image;

@end
