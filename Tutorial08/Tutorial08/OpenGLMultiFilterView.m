//
//  OpenGLMultiFilterView.m
//  Tutorial08
//
//  Created by heyonly on 2019/6/19.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "OpenGLMultiFilterView.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "OpenGLUtils.h"
typedef struct
{
    float position[4];
    float textureCoordinate[2];
} CustomVertex;

enum
{
    ATTRIBUTE_POSITION = 0,
    ATTRIBUTE_INPUT_TEXTURE_COORDINATE,
    TEMP_ATTRIBUTE_POSITION,
    TEMP_ATTRIBUTE_INPUT_TEXTURE_COORDINATE,
    NUM_ATTRIBUTES
};
GLint glViewAttributes[NUM_ATTRIBUTES];

enum
{
    UNIFORM_INPUT_IMAGE_TEXTURE = 0,
    TEMP_UNIFORM_INPUT_IMAGE_TEXTURE,
    UNIFORM_TEMPERATURE,
    UNIFORM_SATURATION,
    NUM_UNIFORMS
};
GLint glViewUniforms[NUM_UNIFORMS];

@interface OpenGLMultiFilterView ()
{
    EAGLContext         *_context;
    CAEAGLLayer         *_eaglLayer;
    
    GLuint              _programHandle;
    
    GLuint              _colorRenderBuffer;
    GLuint              _frameBuffer;
    
    GLuint              _imageTexture;
    
    GLuint              _textureSlot;
    GLuint              _positionSlot;
    GLuint              _textureCoordsSlot;
    
    GLuint              _tempetatureProgramHandle;
    GLuint              _tempFrameBuffer;
    GLuint              _tempColorRenderBuffer;
    GLuint              _tempTexture;
    
    GLuint              _tempPositionSlot;
    GLuint              _tempTextureSlot;
    GLuint              _TempTextureCoordSlot;
    GLuint              _temperatureSlot;
    
    
    
    GLuint              _mosFrameBuffer;
    GLuint              _mosaicProgramHandle;
    GLuint              _mosTextureSlot;
    GLuint              _mosTexture;
    GLuint              _mosPositionSlot;
    GLuint              _mosTextureCoordsSlot;
    
    
    
    
    CGFloat             _temperature;
}
@end

@implementation OpenGLMultiFilterView
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _temperature = 1.0;
    }
    return self;
}
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

- (void)setupFrameBuffer {
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
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

- (void)setupLuminanceProgram {
    NSString *vertexFile = [[NSBundle mainBundle] pathForResource:@"VertexShader.glsl" ofType:nil];
    NSString *fragmentFile = [[NSBundle mainBundle] pathForResource:@"FragmentShader.glsl" ofType:nil];
    _programHandle = [OpenGLUtils programWithVertexShader:vertexFile FragmentShaderFile:fragmentFile];
    
    glUseProgram(_programHandle);
    
    _positionSlot = glGetAttribLocation(_programHandle, "vPosition");
    _textureCoordsSlot = glGetAttribLocation(_programHandle, "textureCoordsIn");
    _textureSlot = glGetUniformLocation(_programHandle, "inputImageTexture");
    
}

- (void)setupWarmProgram {
    NSString *vertexFile = [[NSBundle mainBundle] pathForResource:@"VertexShader.glsl" ofType:nil];
    NSString *fragmentFile = [[NSBundle mainBundle] pathForResource:@"Tempetature.fsh" ofType:nil];
    
    _tempetatureProgramHandle = [OpenGLUtils programWithVertexShader:vertexFile FragmentShaderFile:fragmentFile];
    glUseProgram(_tempetatureProgramHandle);
    
    _tempPositionSlot = glGetAttribLocation(_tempetatureProgramHandle, "vPosition");
    _TempTextureCoordSlot = glGetAttribLocation(_tempetatureProgramHandle, "textureCoordsIn");
    _tempTextureSlot = glGetUniformLocation(_tempetatureProgramHandle, "inputImageTexture");
    _temperatureSlot = glGetUniformLocation(_tempetatureProgramHandle, "temperature");
}

- (void)setupMosaicProgram {
    NSString *vertexFile = [[NSBundle mainBundle] pathForResource:@"VertexShader.glsl" ofType:nil];
    NSString *fragmentFile = [[NSBundle mainBundle] pathForResource:@"mosaic.glsl" ofType:nil];
    
    _mosaicProgramHandle = [OpenGLUtils programWithVertexShader:vertexFile FragmentShaderFile:fragmentFile];
    
    _mosTextureSlot = glGetUniformLocation(_mosaicProgramHandle, "inputImageTexture");
    _mosPositionSlot = glGetAttribLocation(_mosaicProgramHandle, "vPosition");
    _mosTextureCoordsSlot = glGetUniformLocation(_mosaicProgramHandle, "textureCoordsIn");
}

- (void)setupMosFramebuffer {
    glGenTextures(1, &_mosTexture);
    glBindTexture(GL_TEXTURE_2D, _mosTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, self.frame.size.width, self.frame.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    glGenFramebuffers(1, &_mosFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _mosFrameBuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _mosTexture, 0);
}

- (void)setupTemp {
    glGenFramebuffers(1, &_tempFrameBuffer);
    
    glActiveTexture(GL_TEXTURE1);
    glGenTextures(1, &_tempTexture);
    glBindTexture(GL_TEXTURE_2D, _tempTexture);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, self.frame.size.width, self.frame.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _tempFrameBuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _tempTexture, 0);
}

- (void)render {
    
    glUseProgram(_mosaicProgramHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _tempFrameBuffer);
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    glClearColor(0, 0, 1.0, 1);
    glClear(GL_COLOR_BUFFER_BIT);

    glVertexAttribPointer(_mosPositionSlot, 4, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), 0);
    glEnableVertexAttribArray(_mosPositionSlot);
    glVertexAttribPointer(_mosTextureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), (GLvoid*)(sizeof(float) * 4));
    glEnableVertexAttribArray(_mosTextureCoordsSlot);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _imageTexture);
    glUniform1f(_mosTextureSlot, 1);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glUseProgram(_programHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);

    glClearColor(1.0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);

    glVertexAttribPointer(_positionSlot, 4, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), 0);
    glEnableVertexAttribArray(_positionSlot);

    glVertexAttribPointer(_textureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), (GLvoid*)(sizeof(GLfloat) * 4));
    glEnableVertexAttribArray(_textureCoordsSlot);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _mosTexture);
    glUniform1f(_textureSlot, 0);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
   
    

    [_context presentRenderbuffer:GL_RENDERBUFFER];
}


- (void)layoutSubviews {
    [self setupLayer];
    [self setupContext];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    
    [self setupMosFramebuffer];
    
    [self setupLuminanceProgram];
//    [self setupWarmProgram];
    [self setupMosaicProgram];
    [self setupVBOs];
//    [self setupTemp];
    [self setupTexture];
    
    [self render];
}
@end
