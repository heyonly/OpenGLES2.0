//
//  OpenGLCubeView.m
//  Tutorial05
//
//  Created by heyonly on 2019/6/11.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "OpenGLCubeView.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "ksMatrix.h"
#import "ksVector.h"

@interface OpenGLCubeView ()
{
    EAGLContext         *_context;
    CAEAGLLayer         *_eaglLayer;
    
    GLuint              _colorRenderBuffer;
    GLuint              _frameBuffer;
    GLuint              _depthRenderBuffer;
    
    GLuint              _positionSlot;
    GLuint              _colorSlot;
    GLuint              _coordPositionSlot;
    
    GLuint              _projectionMatrixSlot;
    GLuint              _modelViewMatrixSlot;
    GLuint              _viewMatrixSlot;
    
    GLuint              _programHandle;
    GLfloat             degreeX;
    GLfloat             degreeY;
    
    GLuint              _colorMapSlot;
    
    GLuint              _bufferIndex;
}

@end


@implementation OpenGLCubeView
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
    glEnable(GL_DEPTH_TEST);
}

- (void)setupColorRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

- (void)setupDepthBuffer {
    GLint width = 0;
    GLint height = 0;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    
}

- (void)setupFrameBuffer {
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void)setupProgram {
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"VertexShaderCube.glsl" ofType:nil];
    NSString *fragmentFile = [[NSBundle mainBundle] pathForResource:@"FragmentShaderCube.glsl" ofType:nil];
    _programHandle = [self loadProgram:vertFile fragmentFile:fragmentFile];
    glUseProgram(_programHandle);

    _positionSlot = glGetAttribLocation(_programHandle, "vPosition");
    
    _coordPositionSlot = glGetAttribLocation(_programHandle,"textCoordinate");
    _projectionMatrixSlot = glGetUniformLocation(_programHandle, "projectionMatrix");
    _modelViewMatrixSlot = glGetUniformLocation(_programHandle, "modelViewMatrix");
    _viewMatrixSlot = glGetUniformLocation(_programHandle, "viewMatrix");
    _colorMapSlot = glGetUniformLocation(_programHandle, "colorMap");
}

- (void)setupTexture {
    CGImageRef spriteImage = [UIImage imageNamed:@"timg.jpeg"].CGImage;
    GLint width = (GLint)CGImageGetWidth(spriteImage);
    GLint height = (GLint)CGImageGetHeight(spriteImage);
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
    //    GLuint tt;
    //    glGenTextures(1, &tt);
    glBindTexture(GL_TEXTURE_2D, _colorMapSlot);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    CGContextRelease(context);
    free(data);
}

- (void)render {
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    GLfloat vertices[] = {
        // 前面
        -0.5, 0.5, 0.5,      0.0, 1.0, // 前左上 0
        -0.5, -0.5, 0.5,     0.0, 0.0, // 前左下 1
        0.5, -0.5, 0.5,      1.0, 0.0, // 前右下 2
        0.5, 0.5, 0.5,       1.0, 1.0, // 前右上 3
        // 后面
        -0.5, 0.5, -0.5,     1.0, 1.0, // 后左上 4
        -0.5, -0.5, -0.5,    1.0, 0.0, // 后左下 5
        0.5, -0.5, -0.5,     0.0, 0.0, // 后右下 6
        0.5, 0.5, -0.5,      0.0, 1.0, // 后右上 7
        // 左面
        -0.5, 0.5, -0.5,     0.0, 1.0, // 后左上 8
        -0.5, -0.5, -0.5,    0.0, 0.0, // 后左下 9
        -0.5, 0.5, 0.5,      1.0, 1.0, // 前左上 10
        -0.5, -0.5, 0.5,     1.0, 0.0, // 前左下 11
        // 右面
        0.5, 0.5, 0.5,       0.0, 1.0, // 前右上 12
        0.5, -0.5, 0.5,      0.0, 0.0, // 前右下 13
        0.5, -0.5, -0.5,     1.0, 0.0, // 后右下 14
        0.5, 0.5, -0.5,      1.0, 1.0, // 后右上 15
        // 上面
        -0.5, 0.5, 0.5,      0.0, 0.0, // 前左上 16
        0.5, 0.5, 0.5,       1.0, 0.0, // 前右上 17
        -0.5, 0.5, -0.5,     0.0, 1.0, // 后左上 18
        0.5, 0.5, -0.5,      1.0, 1.0, // 后右上 19
        // 下面
        -0.5, -0.5, 0.5,     0.0, 1.0, // 前左下 20
        0.5, -0.5, 0.5,      1.0, 1.0, // 前右下 21
        -0.5, -0.5, -0.5,    0.0, 0.0, // 后左下 22
        0.5, -0.5, -0.5,     1.0, 0.0, // 后右下 23
    };
    
    GLubyte indices[] = {
        // 前面
        0, 1, 2,
        0, 2, 3,
        // 后面
        4, 5, 6,
        4, 6, 7,
        // 左面
        8, 9, 11,
        8, 11, 10,
        // 右面
        12, 13, 14,
        12, 14, 15,
        // 上面
        18, 16, 17,
        18, 17, 19,
        // 下面
        20, 22, 23,
        20, 23, 21
    };
    
    GLuint VBO = 0;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), 0);
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_coordPositionSlot, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), (GLfloat*)NULL + 3);
    glEnableVertexAttribArray(_coordPositionSlot);
    
//    GLuint bufferIndex;
    glGenBuffers(1, &_bufferIndex);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _bufferIndex);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    
    [self setupTexture];
    
    GLint width = self.frame.size.width;
    GLint height = self.frame.size.height;
    
    ksMatrix4 projectionMatrix;
    ksMatrixLoadIdentity(&projectionMatrix);
    float aspect = width / height;
    
    ksPerspective(&projectionMatrix, 35, aspect, 0.1, 100);
    
    glUniformMatrix4fv(_projectionMatrixSlot, 1, GL_FALSE, (GLfloat*)&projectionMatrix.m[0][0]);
    
    ksMatrix4 modelViewMatrix;
    ksMatrixLoadIdentity(&modelViewMatrix);
    
    
    ksMatrix4 viewMatrix;
    ksMatrixLoadIdentity(&viewMatrix);
    ksVec3 eyeVec3 = {0,0,3};
    ksVec3 targetVec3 = {0,0,0};
    ksVec3 upVec3 = {0,1,0};
    ksLookAt(&viewMatrix, &eyeVec3, &targetVec3, &upVec3);
    glUniformMatrix4fv(_viewMatrixSlot, 1, GL_FALSE, (GLfloat*)&viewMatrix.m[0][0]);
    
    ksMatrixTranslate(&modelViewMatrix, 0, 0, -3);
    ksMatrix4 rotationMatrix;
    ksMatrixLoadIdentity(&rotationMatrix);
    ksMatrixRotate(&rotationMatrix, degreeY, 1, 0, 0);
    
    ksMatrixRotate(&rotationMatrix, degreeX, 0, 1.0, 0);
    
    ksMatrix4 modelViewMatrixCopy = modelViewMatrix;
    ksMatrixMultiply(&modelViewMatrix, &rotationMatrix, &modelViewMatrixCopy);
    
    glUniformMatrix4fv(_modelViewMatrixSlot, 1, GL_FALSE, (GLfloat*)&modelViewMatrix.m[0][0]);
    
    glBindBuffer(GL_ARRAY_BUFFER, _bufferIndex);
    glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(indices[0]), GL_UNSIGNED_BYTE, 0);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
    glDeleteBuffers(1, &VBO);
    
    
}

- (void)layoutSubviews {
    [self setupLayer];
    [self setupContext];
    [self setupColorRenderBuffer];
    [self setupDepthBuffer];
    [self setupFrameBuffer];
//    [self setupTexture];
    [self setupProgram];
    [self render];
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
