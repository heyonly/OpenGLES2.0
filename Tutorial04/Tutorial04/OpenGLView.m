//
//  OpenGLView.m
//  Tutorial04
//
//  Created by heyonly on 2019/7/10.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "OpenGLView.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "Utils/OpenGLUtils.h"
#import "Utils/ksMatrix.h"
#import "Utils/ksVector.h"

// 限制上下转动的角度
#define kLimitDegreeUpDown 40.0

// 顶点结构体
typedef struct{
    
    GLfloat position[3];
    GLfloat texturePosion[2];
} Vertex;


const Vertex vertexes[] = {
    // 顶点                   纹理
    // 前面
    {{-0.5f, 0.5f, 0.5f},   {0.0f, 0.0f}}, // 前左上 0
    {{-0.5f, -0.5f, 0.5f},  {0.0f, 1.0f}}, // 前左下 1
    {{0.5f, -0.5f, 0.5f},   {1.0f, 1.0f}}, // 前右下 2
    {{0.5f, 0.5f, 0.5f},    {1.0f, 0.0f}}, // 前右上 3
    // 后面
    {{-0.5f, 0.5f, -0.5f},   {1.0f, 0.0f}}, // 后左上 4
    {{-0.5f, -0.5f, -0.5f},  {1.0f, 1.0f}}, // 后左下 5
    {{0.5f, -0.5f, -0.5f},   {0.0f, 1.0f}}, // 后右下 6
    {{0.5f, 0.5f, -0.5f},    {0.0f, 0.0f}}, // 后右上 7
    // 左面
    {{-0.5f, 0.5f, -0.5f},   {0.0f, 0.0f}}, // 后左上 8
    {{-0.5f, -0.5f, -0.5f},  {0.0f, 1.0f}}, // 后左下 9
    {{-0.5f, 0.5f, 0.5f},   {1.0f, 0.0f}}, // 前左上 10
    {{-0.5f, -0.5f, 0.5f},  {1.0f, 1.0f}}, // 前左下 11
    // 右面
    {{0.5f, 0.5f, 0.5f},    {0.0f, 0.0f}}, // 前右上 12
    {{0.5f, -0.5f, 0.5f},   {0.0f, 1.0f}}, // 前右下 13
    {{0.5f, -0.5f, -0.5f},   {1.0f, 1.0f}}, // 后右下 14
    {{0.5f, 0.5f, -0.5f},    {1.0f, 0.0f}}, // 后右上 15
    // 上面
    {{-0.5f, 0.5f, -0.5f},   {0.0f, 0.0f}}, // 后左上 16
    {{-0.5f, 0.5f, 0.5f},   {0.0f, 1.0f}}, // 前左上 17
    {{0.5f, 0.5f, 0.5f},    {1.0f, 1.0f}}, // 前右上 18
    {{0.5f, 0.5f, -0.5f},    {1.0f, 0.0f}}, // 后右上 19
    // 下面
    {{-0.5f, -0.5f, 0.5f},  {0.0f, 0.0f}}, // 前左下 20
    {{0.5f, -0.5f, 0.5f},   {1.0f, 0.0f}}, // 前右下 21
    {{-0.5f, -0.5f, -0.5f},  {0.0f, 1.0f}}, // 后左下 22
    {{0.5f, -0.5f, -0.5f},   {1.0f, 1.0f}}, // 后右下 23
};

const GLbyte indexes[] = {
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
    16, 17, 18,
    16, 18, 19,
    // 下面
    20, 22, 23,
    20, 23, 21,
};


@interface OpenGLView ()
{
    CAEAGLLayer             *_eaglLayer;
    EAGLContext             *_context;
    GLuint                  _frameBuffer;
    GLuint                  _colorRenderBuffer;
    GLuint                  _depthRenderBuffer;
    GLuint                  _programHandle0;
    
    GLuint                  _positionSlot;
    GLuint                  _textureCoordsSlot0;
    GLuint                  _imageTextureSlot0;
    
    GLuint                  _modelViewSlot; // 物体变换的槽
    GLuint                  _projectionSlot; // 摄像机的槽
    
    
    GLuint                  _imageTexture0;
    
    ksMatrix4               _modelViewMatrix4;
    
}

@property(nonatomic,assign)GLfloat degreeX;

@property(nonatomic,assign)GLfloat degreeY;

@end


@implementation OpenGLView
+ (Class)layerClass {
    return [CAEAGLLayer class];
}


- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    UITouch * touch = touches.anyObject;
    
    CGPoint currentPoint = [touch locationInView:self];
    CGPoint previousPoint = [touch previousLocationInView:self];
    
    self.degreeX += previousPoint.y - currentPoint.y;
    
    // 限制上下转动的角度
    if (self.degreeX > kLimitDegreeUpDown) {
        self.degreeX = kLimitDegreeUpDown;
    }
    
    if (self.degreeX < -kLimitDegreeUpDown) {
        self.degreeX = -kLimitDegreeUpDown;
    }
    
    self.degreeY += previousPoint.x - currentPoint.x;
    [self render];
}



- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer*)self.layer;
    _eaglLayer.opaque = YES;
    
    _eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking:@(NO),
                                      kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8
                                      };
}



- (void)setupContext {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context) {
        NSLog(@"Failed to initialize opengl es2.0 context!!");
        return;
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set context!!");
        return;
    }
}

- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

- (void)setupDepthRenderBuffer {
    // 设置深度调试
    GLint width;
    GLint height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    // 申请深度渲染缓存
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    // 设置深度测试的存储信息
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    
}

- (void)setupFrameBuffer {
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    // 将渲染缓存挂载到GL_DEPTH_ATTACHMENT这个挂载点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
    // GL_RENDERBUFFER绑定的是深度测试渲染缓存，所以要绑定回色彩渲染缓存
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    
    // 检查帧缓存状态
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Error: Frame buffer is not completed.");
        exit(1);
    }
}

- (void)setupProgram {
    NSString *VertexFile = [[NSBundle mainBundle] pathForResource:@"vertexShader.glsl" ofType:nil];
    NSString *FragmentFile = [[NSBundle mainBundle] pathForResource:@"fragmentShader.glsl" ofType:nil];
    
    _programHandle0 = [OpenGLUtils programWithVertexFile:VertexFile fragmentFile:FragmentFile];
    glUseProgram(_programHandle0);//激活shader 程序
    
    _positionSlot = glGetAttribLocation(_programHandle0, "vPosition");//在ES3.0 中有另一种方式
    _textureCoordsSlot0 = glGetAttribLocation(_programHandle0, "textureCoordsIn");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_textureCoordsSlot0);
    
    _imageTextureSlot0 = glGetUniformLocation(_programHandle0, "imageTexture");
    _modelViewSlot = glGetUniformLocation(_programHandle0, "modelView");
    _projectionSlot = glGetUniformLocation(_programHandle0, "projection");
    
}

- (void)setupImageTexture {
    UIImage *image0 = [UIImage imageNamed:@"timg.jpeg"];
    _imageTexture0 = [self genarateTexture:image0];
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _imageTexture0);
    glUniform1i(_imageTextureSlot0, 0);
    
}


- (void)setupVBO {
    GLuint bufferVBO;
    glGenBuffers(1, &bufferVBO);
    glBindBuffer(GL_ARRAY_BUFFER, bufferVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexes), vertexes, GL_STATIC_DRAW);
    
    GLuint bufferIndex;
    glGenBuffers(1, &bufferIndex);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, bufferIndex);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexes), indexes, GL_STATIC_DRAW);
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    //    glVertexAttribPointer(_vertexSlot, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 3, NULL);
    glEnableVertexAttribArray(_positionSlot);
    
    glVertexAttribPointer(_textureCoordsSlot0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
    glEnableVertexAttribArray(_textureCoordsSlot0);
}


/**
 设置视锥体
 */
- (void)setupPerspactive{
    
    GLfloat aspect = self.frame.size.width / self.frame.size.height;
    
    ksMatrix4 tempMatrix;
    
    ksMatrixLoadIdentity(&tempMatrix);
    //0.1 近平面，10.0远平面
    ksPerspective(&tempMatrix, 60, aspect, 0.1f, 10.0f);
    
    glUniformMatrix4fv(_projectionSlot, 1 , GL_FALSE, (GLfloat *)&tempMatrix.m[0][0]);
}

- (void)render {
    // 设置物体的变换
    ksMatrixLoadIdentity(&_modelViewMatrix4);
    // 远离视野，不然是在
    ksMatrixTranslate(&_modelViewMatrix4, 0, 0, -3);
    // x方向旋转
    ksMatrixRotate(&_modelViewMatrix4, self.degreeX, 1, 0, 0);
    // y方向旋转
    ksMatrixRotate(&_modelViewMatrix4, self.degreeY, 0, 1, 0);
    
    glUniformMatrix4fv(_modelViewSlot, 1, GL_FALSE, (GLfloat *)&_modelViewMatrix4.m[0][0]);
    
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    glClearColor(1.0, 1.0, 1.0, 1.0);
    
    glEnable(GL_DEPTH_TEST);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glDrawElements(GL_TRIANGLES, sizeof(indexes)/sizeof(indexes[0]), GL_UNSIGNED_BYTE, 0);
    
    //    glDrawElements(GL_LINES, sizeof(indexes) / sizeof(indexes[0]), GL_UNSIGNED_BYTE, 0);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}


- (void)layoutSubviews {
    [self setupLayer];
    [self setupContext];
    [self setupRenderBuffer];
    [self setupDepthRenderBuffer];
    [self setupFrameBuffer];
    [self setupProgram];
    [self setupImageTexture];
    [self setupVBO];
    [self setupPerspactive];
    [self render];
}

- (GLuint)genarateTexture:(UIImage *)image {
    
    size_t width = CGImageGetWidth(image.CGImage);
    size_t height = CGImageGetHeight(image.CGImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    void *imageData = malloc(height * width * 4);
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, CGRectMake(0, 0, width, height));
    //    CGContextTranslateCTM(context, 0, height);
    //    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image.CGImage);
    CGContextRelease(context);
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLint)width, (GLint)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    free(imageData);
    return texture;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
