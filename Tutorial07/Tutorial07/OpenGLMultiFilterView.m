//
//  OpenGLMultiFilterView.m
//  Tutorial07
//
//  Created by heyonly on 2019/7/15.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "OpenGLMultiFilterView.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "Utils/OpenGLUtils.h"
@interface OpenGLMultiFilterView ()
{
    EAGLContext         *_context;
    CAEAGLLayer         *_eaglLayer;
    
    GLuint              _programHandle0;
    GLuint              _programHandle1;
    
    GLuint              _colorRenderBuffer;
    GLuint              _frameBuffer0;
    GLuint              _frameBuffer1;
    
    GLuint              _imageTexture;
    GLuint              _nullTexture;
    
    GLuint              _positionSlot0;
    GLuint              _positionSlot1;
    
    GLuint              _imageTextureSlot;
    GLuint              _nullTextureSlot;
    
    
    GLuint              _textureCoordsSlot0;
    GLuint              _textureCoordsSlot1;
    
}

@end

@implementation OpenGLMultiFilterView
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES;
    _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

- (void)setupContext {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!_context) {
        NSLog(@"alloc context Failed!!");
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"setup current context Failed!!");
    }
}

- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

- (void)setupFrameBuffer0 {
    glGenFramebuffers(1, &_frameBuffer0);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer0);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void)setupNullTexture {
    glGenTextures(1, &_nullTexture);
    glBindTexture(GL_TEXTURE_2D, _nullTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, self.frame.size.width, self.frame.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)setupFramebuffer1 {
    glGenFramebuffers(1, &_frameBuffer1);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer1);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _nullTexture, 0);
}

- (void)setupTexture {
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
    
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &_imageTexture);
    glBindTexture(GL_TEXTURE_2D, _imageTexture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLint)width, (GLint)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    glBindTexture(GL_TEXTURE_2D, 0);
    free(imageData);
}


- (void)setupMosaicProgram {
    NSString *vertexFile = [[NSBundle mainBundle] pathForResource:@"vert.glsl" ofType:nil];
    NSString *fragmentFile = [[NSBundle mainBundle] pathForResource:@"mosaic.glsl" ofType:nil];
    
    _programHandle1 = [OpenGLUtils programWithVertexShader:vertexFile FragmentShaderFile:fragmentFile];
    
    _nullTextureSlot = glGetUniformLocation(_programHandle1, "inputImageTexture");
    _positionSlot1 = glGetAttribLocation(_programHandle1, "vPosition");
    _textureCoordsSlot1 = glGetUniformLocation(_programHandle1, "textureCoordsIn");
}

- (void)setupLuminanceProgram {
    NSString *vertexFile = [[NSBundle mainBundle] pathForResource:@"vert.glsl" ofType:nil];
    NSString *fragmentFile = [[NSBundle mainBundle] pathForResource:@"frag.glsl" ofType:nil];
    _programHandle0 = [OpenGLUtils programWithVertexShader:vertexFile FragmentShaderFile:fragmentFile];
    
    glUseProgram(_programHandle0);
    
    _positionSlot0 = glGetAttribLocation(_programHandle0, "vPosition");
    _textureCoordsSlot0 = glGetAttribLocation(_programHandle0, "textureCoordsIn");
    _imageTextureSlot = glGetUniformLocation(_programHandle0, "inputImageTexture");
}

- (void)setupVbo0 {
    GLfloat vertices[] = {
        0.5f,  0.5f, 0.0f, 1.0f, 0.0f,   // 右上
        0.5f, -0.5f, 0.0f, 1.0f, 1.0f,   // 右下
        -0.5f, -0.5f, 0.0f, 0.0f, 1.0f,  // 左下
        -0.5f,  0.5f, 0.0f, 0.0f, 0.0f   // 左上
    };
    
    // 创建VBO
    GLuint  vbo;
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(_positionSlot0);
    glVertexAttribPointer(_positionSlot0, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, NULL);
    
    glEnableVertexAttribArray(_textureCoordsSlot0);
    glVertexAttribPointer(_textureCoordsSlot0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, NULL+sizeof(GL_FLOAT)*3);
}


- (void)setupVbo1 {
    GLfloat vertices[] = {
        1.0f,  1.0f, 0.0f, 1.0f, 1.0f,   // 右上
        1.0f, -1.0f, 0.0f, 1.0f, 0.0f,   // 右下
        -1.0f, -1.0f, 0.0f, 0.0f, 0.0f,  // 左下
        -1.0f,  1.0f, 0.0f, 0.0f, 1.0f   // 左上
    };
    
    // 创建VBO
    GLuint  vbo;
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(_positionSlot1);
    glVertexAttribPointer(_positionSlot1, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, NULL);
    
    glEnableVertexAttribArray(_textureCoordsSlot1);
    glVertexAttribPointer(_textureCoordsSlot1, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, NULL+sizeof(GL_FLOAT)*3);
}

- (void)render {
    glUseProgram(_programHandle1);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer1);
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _imageTexture);
    glUniform1i(_imageTextureSlot, 1);
    
    // 索引数组
    unsigned int indices1[] = {0,1,2,3,2,0};
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, indices1);
    
    
    glUseProgram(_programHandle0);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer0);
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _nullTexture);
    glUniform1i(_nullTextureSlot, 0);
    
    // 索引数组
    unsigned int indices0[] = {0,1,2,3,2,0};
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, indices0);
    
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)layoutSubviews {
    [self setupLayer];
    [self setupContext];
    [self setupRenderBuffer];
    [self setupFrameBuffer0];
    [self setupTexture];
    [self setupNullTexture];
    [self setupFramebuffer1];
    
    [self setupMosaicProgram];
    [self setupLuminanceProgram];
    [self setupVbo0];
    [self setupVbo1];
    [self render];
}

@end
