//
//  OpenGLUtils.m
//  Tutorial07
//
//  Created by heyonly on 2019/6/22.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "OpenGLUtils.h"

@implementation OpenGLUtils
+ (GLuint)programWithVertexFile:(NSString *)vertexFile fragmentFile:(NSString *)fragmentFile {
    NSString *vertexShaderString = [NSString stringWithContentsOfFile:vertexFile encoding:NSUTF8StringEncoding error:nil];
    GLuint vertexShader = [OpenGLUtils shaderWithString:vertexShaderString type:GL_VERTEX_SHADER];
    
    NSString *fragmentShaderString = [NSString stringWithContentsOfFile:fragmentFile encoding:NSUTF8StringEncoding error:nil];
    GLuint fragmentShader = [OpenGLUtils shaderWithString:fragmentShaderString type:GL_FRAGMENT_SHADER];
    
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    glLinkProgram(program);
    
    GLint success;
    GLchar infoLog[512];
    glGetProgramiv(program, GL_LINK_STATUS, &success);
    if (!success) {
        glGetProgramInfoLog(program, 512, NULL, infoLog);
        glDeleteProgram(program);
        return 0;
    }
    
    return program;
}

+ (GLuint)shaderWithString:(NSString *)shaderString type:(GLuint)type {
    const char* shaderStringUTF8 = [shaderString UTF8String];
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &shaderStringUTF8, NULL);
    glCompileShader(shader);
    GLint success;
    GLchar infoLog[512];
    
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(shader, 512, NULL, infoLog);
        NSLog(@"compile shader Failed: %s",infoLog);
        glDeleteShader(shader);
        return 0;
    }
    return shader;
    
}
@end
