//
//  OpenGLUtils.h
//  Tutorial08
//
//  Created by heyonly on 2019/6/19.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenGLUtils : NSObject
+ (GLuint)programWithVertexShader:(NSString *)vertexShaderFile FragmentShaderFile:(NSString *)fragmentShaderFile;
+ (GLuint)compileShaderWithFileName:(NSString *)filename type:(GLuint)type;
+ (void*)setupTextureWithImage:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
