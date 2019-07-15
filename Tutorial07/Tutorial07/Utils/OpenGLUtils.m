//
//  OpenGLUtils.m
//  Tutorial08
//
//  Created by heyonly on 2019/6/19.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "OpenGLUtils.h"



@implementation OpenGLUtils
+ (GLuint)programWithVertexShader:(NSString *)vertexShaderFile FragmentShaderFile:(NSString *)fragmentShaderFile {
    GLuint vertexShader = [OpenGLUtils compileShaderWithFileName:vertexShaderFile type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [OpenGLUtils compileShaderWithFileName:fragmentShaderFile type:GL_FRAGMENT_SHADER];
    
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    glLinkProgram(program);
    
    GLint linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"program链接失败：%@", messageString);
        exit(1);
    }
    return program;
}
+ (GLuint)compileShaderWithFileName:(NSString *)filename type:(GLuint)type {
    const char* shaderStringUTF8 = [[NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil] UTF8String];
    
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &shaderStringUTF8, NULL);
    glCompileShader(shader);
    
    GLint success;
    char infoLog[512];
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(shader, 512, NULL, infoLog);
        NSLog(@"%s",infoLog);
    }
    
    return shader;
    
}

+ (void *)setupTextureWithImage:(UIImage *)image {
    
    size_t width = CGImageGetWidth(image.CGImage);
    size_t height = CGImageGetHeight(image.CGImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    void *imageData = malloc(height * width * 4);
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, CGRectMake(0, 0, width, height));
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image.CGImage);
    CGContextRelease(context);
    
    return imageData;
}
@end
