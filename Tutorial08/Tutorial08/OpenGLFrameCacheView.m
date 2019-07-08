//
//  OpenGLFrameCacheView.m
//  Tutorial08
//
//  Created by heyonly on 2019/6/20.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "OpenGLFrameCacheView.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "OpenGLUtils.h"
#import <AVFoundation/AVFoundation.h>
typedef struct
{
    float position[4];
    float textureCoordinate[2];
} CustomVertex;

@interface OpenGLFrameCacheView ()
{
    EAGLContext                 *_context;
    CAEAGLLayer                 *_eaglLayer;
    
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
    GLuint                       _temperatureSlot;
    
    float                        _temperature;
    float                        _saturation;
    
}
@end
@implementation OpenGLFrameCacheView
+ (Class)layerClass {
    return [CAEAGLLayer class];
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _temperature = 1.0;
        _saturation = 0.0;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _temperature = 0.5;
        _saturation = 0.8;
    }
    return self;
}

- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES;
}

- (void)setupContext {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context) {
        NSLog(@"alloc context failed!!");
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"set current context Failed!!");
    }
}

- (void)setupRenderBuffer {
    if (_colorRenderBuffer) {
        glDeleteRenderbuffers(1, &_colorRenderBuffer);
        _colorRenderBuffer = 0;
    }
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

- (void)setupFrameBuffer {
    if (_frameBuffer0) {
        glDeleteFramebuffers(1, &_frameBuffer0);
        _frameBuffer0 = 0;
    }
    glGenFramebuffers(1, &_frameBuffer0);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer0);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void)setupSaturationProgram {
    NSString *vertexFile = [[NSBundle mainBundle] pathForResource:@"VertexShader.glsl" ofType:nil];
    NSString *fragmentFile = [[NSBundle mainBundle] pathForResource:@"Saturation.fsh" ofType:nil];
    
    _saturationProgram = [OpenGLUtils programWithVertexShader:vertexFile FragmentShaderFile:fragmentFile];
    glUseProgram(_saturationProgram);
    _satTextureSlot = glGetUniformLocation(_saturationProgram, "inputImageTexture");
    _satPositionSlot = glGetAttribLocation(_saturationProgram, "vPosition");
    _satTextureCoordsSlot = glGetAttribLocation(_saturationProgram, "textureCoordsIn");
    _satSaturationSlot = glGetUniformLocation(_saturationProgram, "saturation");
    glEnableVertexAttribArray(_satPositionSlot);
    glEnableVertexAttribArray(_satTextureCoordsSlot);
}

- (void)setupTemperatureProgram {
    NSString *vertexFile = [[NSBundle mainBundle] pathForResource:@"VertexShader.glsl" ofType:nil];
    NSString *fragmentFile = [[NSBundle mainBundle] pathForResource:@"Tempetature.fsh" ofType:nil];
    _temperatureProgram = [OpenGLUtils programWithVertexShader:vertexFile FragmentShaderFile:fragmentFile];
    glUseProgram(_temperatureProgram);
    _tempTextureSlot = glGetUniformLocation(_temperatureProgram, "inputImageTexture");
    _tempPositionSlot = glGetAttribLocation(_temperatureProgram, "vPosition");
    _tempTextureCoordsSlot = glGetAttribLocation(_temperatureProgram, "textureCoordsIn");
    
    _temperatureSlot = glGetUniformLocation(_temperatureProgram, "temperature");
    glEnableVertexAttribArray(_tempPositionSlot);
    glEnableVertexAttribArray(_tempTextureCoordsSlot);
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

- (void)setupImageTexture {
    UIImage *image = [UIImage imageNamed:@"timg.jpeg"];
    
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
    
    glGenTextures(1, &_imageTexture);
    glBindTexture(GL_TEXTURE_2D, _imageTexture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLint)width, (GLint)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);

    free(imageData);
 
}

- (void)setupFrameBuffer1 {
    glGenTextures(1, &_nullTexture);
    glBindTexture(GL_TEXTURE_2D, _nullTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, self.frame.size.width, self.frame.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    
    
    glGenFramebuffers(1, &_frameBuffer1);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer1);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _nullTexture, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)render {
#if 1
    glUseProgram(_saturationProgram);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer0);
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    glClearColor(0, 0, 1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _imageTexture);
    glUniform1i(_satTextureSlot, 1);
    glUniform1f(_satSaturationSlot, _saturation);

    glEnableVertexAttribArray(_satPositionSlot);
    glVertexAttribPointer(_satPositionSlot, 4, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), 0);
    glEnableVertexAttribArray(_satTextureCoordsSlot);
    glVertexAttribPointer(_satTextureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), (GLvoid*)(sizeof(GLfloat) * 4));

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
#else
    
    glUseProgram(_temperatureProgram);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer0);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    glClearColor(0, 1, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _imageTexture);
    glUniform1i(_tempTextureSlot, 0);
    glUniform1f(_temperatureSlot, _temperature);
    glEnableVertexAttribArray(_tempPositionSlot);
    glVertexAttribPointer(_tempPositionSlot, 4, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), 0);

    glEnableVertexAttribArray(_tempTextureCoordsSlot);
    glVertexAttribPointer(_tempTextureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), (GLvoid*)(sizeof(GLfloat) * 4));

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
#endif
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)layoutSubviews {
    [self setupLayer];
    [self setupContext];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self setupFrameBuffer1];
    [self setupSaturationProgram];
    [self setupTemperatureProgram];
    
    
    [self setupImageTexture];
    [self setupVBOs];
    
    [self render];
}

- (void)updateSaturation:(float)value {
    _saturation = value;
    [self render];
}

- (void)updateTemperature:(float)value {
    _temperature = value;
    [self render];
}
@end
