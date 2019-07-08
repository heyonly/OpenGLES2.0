//
//  GLView.m
//  OpenGLESDemo
//
//  Created by Yue on 17/1/13.
//  Copyright © 2017年 Yue. All rights reserved.
//

#import "GLView.h"
#import "OpenGLUtils.h"
@import OpenGLES;

typedef struct
{
    float position[4];
    float textureCoordinate[2];
} CustomVertex;


@interface GLView ()
{
    CAEAGLLayer             *_eaglLayer;
    EAGLContext             *_context;

    
    
    GLuint                      _frameBuffer0;
    GLuint                      _colorRenderBuffer;
    
    GLuint                      _frameBuffer1;
    
    GLuint                      _saturationProgram;
    GLuint                      _temperatureProgram;
    
    GLuint                      _imageTexture;
    GLuint                      _nullTexture;
    
    GLuint                      _satPositionSlot;
    GLuint                      _satTextureCoordsSlot;
    GLuint                      _satTextureSlot;
    GLuint                      _satSaturationSlot;
    
    GLuint                      _tempPositionSlot;
    GLuint                      _tempTextureCoordsSlot;
    GLuint                      _tempTextureSlot;
    
    GLuint                      _temperatureSlot;

}

@end

@implementation GLView

#pragma mark - Life Cycle
- (void)dealloc {
    if (_frameBuffer0) {
        glDeleteFramebuffers(1, &_frameBuffer0);
        _frameBuffer0 = 0;
    }
    if (_colorRenderBuffer) {
        glDeleteRenderbuffers(1, &_colorRenderBuffer);
        _colorRenderBuffer = 0;
    }
    _context = nil;
}

#pragma mark - Override
// 想要显示 OpenGL 的内容, 需要把它缺省的 layer 设置为一个特殊的 layer(CAEAGLLayer).
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

#pragma mark - Setup
- (void)setup {
    [self setupData];
    [self setupLayer];
    [self setupContext];
    [self setupRenderBuffer];
    [self setupFrameBuffer0];
    [self compileShaders];
    [self compileTempShaders];
    [self setupVBOs];
    [self setupFrameBuffer1];
}

- (void)setupData {
    _temperature = 0.5;
    _saturation = 0.5;
}

- (void)setupLayer {
    // 用于显示的layer
    _eaglLayer = (CAEAGLLayer *)self.layer;
    //  CALayer默认是透明的，而透明的层对性能负荷很大。所以将其关闭。
    _eaglLayer.opaque = YES;
}

- (void)setupContext {
    if (!_context) {
        // 创建GL环境上下文
        // EAGLContext 管理所有通过 OpenGL 进行 Draw 的信息.
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    NSAssert(_context && [EAGLContext setCurrentContext:_context], @"初始化GL环境失败");
}

- (void)setupRenderBuffer {
    // 释放旧的 renderbuffer
    if (_colorRenderBuffer) {
        glDeleteRenderbuffers(1, &_colorRenderBuffer);
        _colorRenderBuffer = 0;
    }
    // 生成renderbuffer ( renderbuffer = 用于展示的窗口 )
    glGenRenderbuffers(1, &_colorRenderBuffer);
    // 绑定renderbuffer
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    // GL_RENDERBUFFER 的内容存储到实现 EAGLDrawable 协议的 CAEAGLLayer
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

- (void)setupFrameBuffer0 {
    // 释放旧的 framebuffer
    if (_frameBuffer0) {
        glDeleteFramebuffers(1, &_frameBuffer0);
        _frameBuffer0 = 0;
    }
    // 生成 framebuffer ( framebuffer = 画布 )
    glGenFramebuffers(1, &_frameBuffer0);
    // 绑定 fraembuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer0);
    // framebuffer 不对绘制的内容做存储, 所以这一步是将 framebuffer 绑定到 renderbuffer ( 绘制的结果就存在 renderbuffer )
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void)setupVBOs {
    static const CustomVertex vertices[] =
    {
        { .position = { -1.0, -1.0, 0, 1 }, .textureCoordinate = { 0.0, 0.0 } },
        { .position = {  1.0, -1.0, 0, 1 }, .textureCoordinate = { 1.0, 0.0 } },
        { .position = { -1.0,  1.0, 0, 1 }, .textureCoordinate = { 0.0, 1.0 } },
        { .position = {  1.0,  1.0, 0, 1 }, .textureCoordinate = { 1.0, 1.0 } }
    };
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
}

- (void)setupTextureWithImage:(UIImage *)image {
    size_t width = CGImageGetWidth(image.CGImage);
    size_t height = CGImageGetHeight(image.CGImage);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc( height * width * 4 );
    
    CGContextRef context = CGBitmapContextCreate(imageData,
                                                 width,
                                                 height,
                                                 8,
                                                 4 * width,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGColorSpaceRelease( colorSpace );
    CGContextClearRect( context, CGRectMake( 0, 0, width, height ) );
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM (context, 1.0,-1.0);
    CGContextDrawImage( context, CGRectMake( 0, 0, width, height ), image.CGImage );
    CGContextRelease(context);

    glGenTextures(1, &_imageTexture);
    glBindTexture(GL_TEXTURE_2D, _imageTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_RGBA,
                 (GLint)width,
                 (GLint)height,
                 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 imageData);
    free(imageData);
}

- (void)setupFrameBuffer1 {
    glGenFramebuffers(1, &_frameBuffer1);

    glGenTextures(1, &_nullTexture);
    glBindTexture(GL_TEXTURE_2D, _nullTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, self.frame.size.width * self.contentScaleFactor, self.frame.size.height * self.contentScaleFactor, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer1);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _nullTexture, 0);
}

- (void)compileShaders {
    
    NSString *vertexShaderFile = [[NSBundle mainBundle] pathForResource:@"VertexShader.glsl" ofType:nil];
    NSString *fragmentShaderFile = [[NSBundle mainBundle] pathForResource:@"Tempetature.fsh" ofType:nil];
    _temperatureProgram = [OpenGLUtils programWithVertexShader:vertexShaderFile FragmentShaderFile:fragmentShaderFile];

    glUseProgram(_temperatureProgram);
    _tempPositionSlot = glGetAttribLocation(_temperatureProgram, "vPosition");
    _tempTextureCoordsSlot  = glGetAttribLocation(_temperatureProgram, "textureCoordsIn");
    _tempTextureSlot = glGetUniformLocation(_temperatureProgram, "inputImageTexture");
    
    _temperatureSlot = glGetUniformLocation(_temperatureProgram, "temperature");
    
    glEnableVertexAttribArray(_tempPositionSlot);
    glEnableVertexAttribArray(_tempTextureCoordsSlot);
}

- (void)compileTempShaders {
    
    NSString *vertexShaderFile = [[NSBundle mainBundle] pathForResource:@"VertexShader.glsl" ofType:nil];
    NSString *fragmentShaderFile = [[NSBundle mainBundle] pathForResource:@"Saturation.fsh" ofType:nil];
    
    _saturationProgram = [OpenGLUtils programWithVertexShader:vertexShaderFile FragmentShaderFile:fragmentShaderFile];

    glUseProgram(_saturationProgram);
    _satPositionSlot = glGetAttribLocation(_saturationProgram, "vPosition");
    _satTextureCoordsSlot  = glGetAttribLocation(_saturationProgram, "textureCoordsIn");
    _satTextureSlot = glGetUniformLocation(_saturationProgram, "inputImageTexture");
    _satSaturationSlot = glGetUniformLocation(_saturationProgram, "saturation");
    glEnableVertexAttribArray(_satPositionSlot);
    glEnableVertexAttribArray(_satTextureCoordsSlot);
}

- (void)render {
    // 绘制第一个滤镜
    glUseProgram(_saturationProgram);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer1);
    glViewport(0, 0, self.frame.size.width * self.contentScaleFactor, self.frame.size.height * self.contentScaleFactor);
    glClearColor(0, 0, 1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _imageTexture);
    
    glUniform1i(_satTextureSlot, 1);
    glUniform1f(_satSaturationSlot, _saturation);
    glVertexAttribPointer(_satPositionSlot, 4, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), 0);
    
    glVertexAttribPointer(_satTextureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), (GLvoid*)(sizeof(GLfloat) * 4));
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glUseProgram(_temperatureProgram);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer0);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    glViewport(0, 0, self.frame.size.width * self.contentScaleFactor, self.frame.size.height * self.contentScaleFactor);
    glClearColor(0, 1, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _nullTexture);
    glUniform1i(_tempTextureSlot, 0);
    glUniform1f(_temperatureSlot, _temperature);
    glVertexAttribPointer(_tempPositionSlot, 4, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), 0);


    glVertexAttribPointer(_tempTextureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), (GLvoid*)(sizeof(GLfloat) * 4));

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - Public
- (void)layoutGLViewWithImage:(UIImage *)image {
    [self setup];
    [self setupTextureWithImage:image];
    [self render];
}

- (void)layoutSubviews {
    UIImage *image = [UIImage imageNamed:@"timg.jpeg"];
    [self setup];
    [self setupTextureWithImage:image];
    [self render];
}

- (void)setTemperature:(CGFloat)temperature {
    _temperature = temperature;
    [self render];
}

- (void)setSaturation:(CGFloat)saturation {
    _saturation = saturation;
    [self render];
}

@end
