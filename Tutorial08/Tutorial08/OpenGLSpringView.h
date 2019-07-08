//
//  OpenGLSpringView.h
//  Tutorial08
//
//  Created by heyonly on 2019/6/19.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface OpenGLSpringView : GLKView
- (void)updateImage:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
