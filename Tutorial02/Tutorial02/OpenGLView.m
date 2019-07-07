//
//  OpenGLView.m
//  Tutorial02
//
//  Created by heyonly on 2019/7/7.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "OpenGLView.h"
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/ES2/gl.h>
#import "Utils/OpenGLUtils.h"
@interface OpenGLView ()
{
    CAEAGLLayer                     *_eaglLayer;
    EAGLContext                     *_context;
    GLuint                          _colorRenderBuffer;
    GLuint                          _framebuffer;
    
    GLuint                          _programHandle0;
    
    GLuint                          _positionSlot;
    GLuint                          _vertexColorSlot;
}

@end

@implementation OpenGLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES;
}

- (void)setupContext {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context) {
        NSLog(@"Failed to initialize context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current context!1");
        exit(1);
    }
}

- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    // 为 color renderbuffer 分配存储空间
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

- (void)setupFrameBuffer {
    glGenRenderbuffers(1, &_framebuffer);
    // 设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}
- (void)setupProgram {
    NSString *VertexFile = [[NSBundle mainBundle] pathForResource:@"VertexFile.glsl" ofType:nil];
    NSString *FragmentFile = [[NSBundle mainBundle] pathForResource:@"FragmentFile.glsl" ofType:nil];
    
    _programHandle0 = [OpenGLUtils programWithVertexFile:VertexFile fragmentFile:FragmentFile];
    glUseProgram(_programHandle0);//激活shader 程序
    
    _positionSlot = glGetAttribLocation(_programHandle0, "vPosition");//在ES3.0 中有另一种方式
    _vertexColorSlot = glGetAttribLocation(_programHandle0, "color");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_vertexColorSlot);
    
}

- (void)render {
    glClearColor(0.0, 1.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    GLfloat vertices[] = {
        0.0f,  0.5f, 0.0f,
        -0.5f, -0.5f, 0.0f,
        0.5f,  -0.5f, 0.0f };
    
    // Load the vertex data
    //
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices );
    glEnableVertexAttribArray(_positionSlot);
    
    //颜色数据
    static GLfloat colors[] = {
        0.0f, 1.0f, 1.0f,
        1.0f, 0.0f, 1.0f,
        1.0f, 1.0f, 0.0f
    };
    
    glVertexAttribPointer(_vertexColorSlot, 3, GL_FLOAT, GL_FALSE, 0, colors);
    glEnableVertexAttribArray(_vertexColorSlot);
    
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)layoutSubviews {
    [self setupLayer];
    [self setupContext];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self setupProgram];
    [self render];
}

- (void)destoryBuffers
{
    glDeleteRenderbuffers(1, &_colorRenderBuffer);
    _colorRenderBuffer = 0;
    
    glDeleteFramebuffers(1, &_framebuffer);
    _framebuffer = 0;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
