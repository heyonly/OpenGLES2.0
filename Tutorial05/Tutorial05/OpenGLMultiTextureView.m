//
//  OpenGLMultiTextureView.m
//  Tutorial05
//
//  Created by heyonly on 2019/6/11.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "OpenGLMultiTextureView.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
@interface OpenGLMultiTextureView ()
{
    CAEAGLLayer         *_eaglLayer;
    EAGLContext         *_context;
    GLuint              _colorRenderBuffer;
    GLuint              _frameBuffer;
    GLuint              _programHandle;
    
    
    GLuint              _texture1;
    GLuint              _texture2;
    
    GLuint              _positionSlot;
    GLuint              _textureLocationSlot;
    
    GLuint              _texture1Slot;
    GLuint              _texture2Slot;
    
    GLint               vertCount;
    GLuint              vbo;
}
@end

@implementation OpenGLMultiTextureView
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
        NSLog(@"alloc context Failed!!");
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
    NSString *vertexFile = [[NSBundle mainBundle]pathForResource:@"VertexShaderMultiTexture" ofType:@"glsl"];
    NSString *fragmentFile = [[NSBundle mainBundle] pathForResource:@"FragmentShaderMultiTexture" ofType:@"glsl"];
    _programHandle = [self loadProgram:vertexFile fragmentFile:fragmentFile];
    
    
    _positionSlot = glGetAttribLocation(_programHandle, "vPosition");
    _textureLocationSlot = glGetAttribLocation(_programHandle, "textureCoordIn");
    _texture1Slot = glGetUniformLocation(_programHandle, "texture1");
    _texture2Slot = glGetUniformLocation(_programHandle, "texture2");
    glUseProgram(_programHandle);
}

- (void)setupTexture {
    _texture1 = [self createTexture2D:@"text.jpg"];
    _texture2 = [self createTexture2D:@"timg.jpeg"];
    
    glEnable(GL_TEXTURE_2D);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture1);
    glUniform1i(_texture1Slot, 0);

    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _texture2);
    glUniform1i(_texture2Slot, 1);

    // 设置图像拉伸变形时的处理方法
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
}


- (void)render {
    glClearColor(0.0, 1.0, 0.0, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    GLfloat vertices[] = {
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

    GLuint vbos;
    glGenBuffers(1, &vbos);
    glBindBuffer(GL_ARRAY_BUFFER, vbos);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    GLuint bufferIndex;
    glGenBuffers(1, &bufferIndex);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, bufferIndex);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexes), indexes, GL_STATIC_DRAW);
    
    
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), 0);
    glEnableVertexAttribArray(_positionSlot);
    
    glVertexAttribPointer(_textureLocationSlot, 2, GL_FLOAT, GL_FALSE, 5 *sizeof(GLfloat), (GLfloat*)NULL + 3);
    glEnableVertexAttribArray(_textureLocationSlot);
    
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
    [self render];
}

- (GLuint)createTexture2D:(NSString *)filename {
    GLuint texture;
    CGImageRef spriteImage = [UIImage imageNamed:filename].CGImage;
    GLuint width = (GLuint)CGImageGetWidth(spriteImage);
    GLuint height = (GLuint)CGImageGetHeight(spriteImage);
    CGRect rect = CGRectMake(0, 0, width, height);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *data = malloc(width * height * 4);
    CGContextRef context = CGBitmapContextCreate(data, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, spriteImage);
    
    
    glEnable(GL_TEXTURE_2D);
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    glBindTexture(GL_TEXTURE_2D, texture);
    free(data);
    return texture;
}

- (GLuint)loadProgram:(NSString *)vertexFile fragmentFile:(NSString *)fragmentFile
{
    GLuint program = 0;
    const char* vertexStringUTF8 = [[NSString stringWithContentsOfFile:vertexFile encoding:NSUTF8StringEncoding error:nil] UTF8String];
    const char* fragmentStringUTF8 = [[NSString stringWithContentsOfFile:fragmentFile encoding:NSUTF8StringEncoding error:nil] UTF8String];
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexStringUTF8, NULL);
    glCompileShader(vertexShader);
    
    GLint success;
    char infoLog[512];
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
    
    if (!success) {
        glGetShaderInfoLog(vertexShader, 512, NULL, infoLog);
        NSLog(@"compile vertex shader Failed:%s",infoLog);
    }
    
    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentStringUTF8, NULL);
    glCompileShader(fragmentShader);
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(fragmentShader, 512, NULL, infoLog);
        NSLog(@"compile fragment shader Failed:%s",infoLog);
    }
    
    program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    glLinkProgram(program);
    glGetProgramiv(program, GL_LINK_STATUS, &success);
    if (!success) {
        glGetProgramInfoLog(program, 512, NULL, infoLog);
        NSLog(@"link program failed:%s",infoLog);
    }
    
    glUseProgram(program);
    return program;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
