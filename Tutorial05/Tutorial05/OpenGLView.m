//
//  OpenGLView.m
//  Tutorial05
//
//  Created by heyonly on 2019/6/10.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "OpenGLView.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>


@interface OpenGLView ()
{
    CAEAGLLayer         *_eaglLayer;
    EAGLContext         *_context;
    
    GLuint              _colorRenderBuffer;
    GLuint              _frameBuffer;
    GLuint              _programHandle;
    
    GLuint              _projectionSlot;
    GLuint              _modelViewSlot;
    GLuint              _positionSlot;
    GLuint              _texture;
    GLuint              _textureCoordSlot;
}
@end

@implementation OpenGLView
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES;
    _eaglLayer.drawableProperties = @{
                                      kEAGLDrawablePropertyRetainedBacking:@(NO),
                                      kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8,
                                      };
}

- (void)setupContext {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!_context) {
        NSLog(@"alloc context Failed!");
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"set current context Failed!!");
    }
}

- (void)setupColorRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

- (void)setupFrameBuffer {
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void)setupProgram {
    NSString *vertexFile = [[NSBundle mainBundle] pathForResource:@"VertexShader" ofType:@"glsl"];
    
    NSString *fragmentFile = [[NSBundle mainBundle] pathForResource:@"FragmentShader" ofType:@"glsl"];
    
    const char *vertexStringUTF8 = [[NSString stringWithContentsOfFile:vertexFile encoding:NSUTF8StringEncoding error:nil] UTF8String];
    const char *fragmentStringUTF8 = [[NSString stringWithContentsOfFile:fragmentFile encoding:NSUTF8StringEncoding error:nil] UTF8String];
    
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexStringUTF8, NULL);
    glCompileShader(vertexShader);
    
    GLint success = 0;
    char infoLog[512];
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(vertexShader, 512, NULL, infoLog);
        NSLog(@"compile vertex shader Failed: %s",infoLog);
    }
    
    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentStringUTF8, NULL);
    glCompileShader(fragmentShader);
    
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(fragmentShader, 512, NULL, infoLog);
        NSLog(@"compile fragment shader Failed: %s",infoLog);
    }
    
    _programHandle = glCreateProgram();
    glAttachShader(_programHandle, vertexShader);
    glAttachShader(_programHandle, fragmentShader);
    glLinkProgram(_programHandle);
    
    glGetProgramiv(_programHandle, GL_LINK_STATUS, &success);
    if (!success) {
        glGetProgramInfoLog(_programHandle, 512, NULL, infoLog);
        NSLog(@"link program Failed: %s",infoLog);
    }
    
    glUseProgram(_programHandle);
    
    _projectionSlot = glGetUniformLocation(_programHandle, "projection");
    _modelViewSlot = glGetUniformLocation(_programHandle, "modelView");
    _positionSlot = glGetAttribLocation(_programHandle, "vPosition");
    _textureCoordSlot = glGetAttribLocation(_programHandle, "textureCoordsIn");
    
    _texture = glGetUniformLocation(_programHandle, "aTexture");
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
}

- (void)setupTexture {
    CGImageRef cgImageRef = [UIImage imageNamed:@"timg.jpeg"].CGImage;
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    
    CGRect rect = CGRectMake(0, 0, width, height);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *data = malloc(width * height * 4);
    CGContextRef context = CGBitmapContextCreate(data, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, cgImageRef);
    
    glEnable(GL_TEXTURE_2D);
//    GLuint tt;
//    glGenTextures(1, &tt);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    CGContextRelease(context);
    free(data);
}

- (void)render4Index {
    GLfloat vertexes[] = {
        // 第一个三角形           // 纹理
        -0.5f, 0.5f, 0.0f,      0.0f, 1.0f, // 左上
        -0.5f, -0.5f, 0.0f,     0.0f, 0.0f, // 左下
        0.5f, -0.5f, 0.0f,      1.0f, 0.0f, // 右下
        0.5f, 0.5f, 0.0f,       1.0f, 1.0f // 右上
    };
    
    
    GLbyte indexes[] = {
        
        0, 1, 2,
        0, 2, 3
    };
    GLuint bufferVBO;
    glGenBuffers(1,&bufferVBO);
    glBindBuffer(GL_ARRAY_BUFFER, bufferVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexes), vertexes, GL_STATIC_DRAW);
    
    GLuint bufferIndex;
    glGenBuffers(1, &bufferIndex);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, bufferIndex);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexes), indexes, GL_STATIC_DRAW);
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, 0);
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_textureCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat*)NULL + 3);
    glEnableVertexAttribArray(_textureCoordSlot);
    
    glClearColor(0.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    glDrawElements(GL_TRIANGLES, sizeof(indexes)/sizeof(indexes[0]), GL_UNSIGNED_BYTE, 0);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)layoutSubviews {
    [self setupLayer];
    [self setupContext];
    [self setupColorRenderBuffer];
    [self setupFrameBuffer];
    [self setupProgram];
    [self setupTexture];
    [self render4Index];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
