//
//  OpenGLView.m
//  Tutorial03
//
//  Created by heyonly on 2019/7/9.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "OpenGLView.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "Utils/OpenGLUtils.h"

@interface OpenGLView ()
{
    CAEAGLLayer             *_eaglLayer;
    EAGLContext             *_context;
    GLuint                  _frameBuffer;
    GLuint                  _colorRenderBuffer;
    
    GLuint                  _programHandle0;
    
    GLuint                  _positionSlot;
    GLuint                  _textureCoordsSlot0;
    GLuint                  _imageTextureSlot0;
    GLuint                  _imageTextureSlot1;
    
    
    GLuint                  _imageTexture0;
    GLuint                  _imageTexture1;
}
@end


@implementation OpenGLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
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


- (void)setupFrameBuffer {
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void)setupProgram {
    NSString *VertexFile = [[NSBundle mainBundle] pathForResource:@"VertexFile.glsl" ofType:nil];
    NSString *FragmentFile = [[NSBundle mainBundle] pathForResource:@"FragmentFile.glsl" ofType:nil];
    
    _programHandle0 = [OpenGLUtils programWithVertexFile:VertexFile fragmentFile:FragmentFile];
    glUseProgram(_programHandle0);//激活shader 程序
    
    _positionSlot = glGetAttribLocation(_programHandle0, "in_position");//在ES3.0 中有另一种方式
    _textureCoordsSlot0 = glGetAttribLocation(_programHandle0, "in_tex_coord");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_textureCoordsSlot0);
    
    _imageTextureSlot0 = glGetUniformLocation(_programHandle0, "tex1");
    _imageTextureSlot1 = glGetUniformLocation(_programHandle0, "tex2");
    
}

- (void)setupImageTexture {
    UIImage *image0 = [UIImage imageNamed:@"mixture.jpg"];
    _imageTexture0 = [self genarateTexture:image0];
    
    UIImage *image1 = [UIImage imageNamed:@"text.jpg"];
    _imageTexture1 = [self genarateTexture:image1];
    
}

- (void)setupVBO {
    GLfloat vertexes[] = {
        // 三角形           // 纹理
        1.0,  1.0,0.0, 1.0, 0.0,   // 右上
        1.0, -1.0,0.0, 1.0, 1.0,   // 右下
        -1.0, -1.0,0.0, 0.0, 1.0,  // 左下
        -1.0, -1.0, 0.0,0.0, 1.0,  // 左下
        -1.0,  1.0,0.0, 0.0, 0.0,  // 左上
        1.0,  1.0, 0.0,1.0, 0.0,   // 右上
    };
    
    // 设置VBO（顶点缓存）
    GLuint bufferVBO;
    glGenBuffers(1, &bufferVBO);
    glBindBuffer(GL_ARRAY_BUFFER, bufferVBO);
    glBufferData(GL_ARRAY_BUFFER, // 目标
                 sizeof(vertexes), // 顶点数组数据大小
                 vertexes, // 顶点数组数据
                 GL_STATIC_DRAW); // 传入VBO数据的使用方式，这里一般设在表态
    
    // 设置图形顶点指针数据(因为使用了VBO所以最后一个参数不用传)
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    glEnableVertexAttribArray(_positionSlot);
    
    // 设置纹理顶点数据(因为使用了VBO所以最后一个参数不用传)
    glVertexAttribPointer(_textureCoordsSlot0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
    glEnableVertexAttribArray(_textureCoordsSlot0);
    
}

- (void)render {
    glClearColor(0.0, 1.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    

    
    // 关闭第一个纹理混合
    glDisable(GL_BLEND);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _imageTexture0);
    glUniform1i(_imageTextureSlot0, 0);
    
    // 绘制第一个纹理
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    // 开启第二个纹理混合
    glEnable(GL_BLEND);
    // 设置混合因子
    glBlendFunc(GL_ONE, GL_ONE);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _imageTexture1);
    glUniform1i(_imageTextureSlot1, 1);

    // 用索引绘制顶点
    glDrawArrays(GL_TRIANGLES, 0, 6);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)layoutSubviews {
    [self setupLayer];
    [self setupContext];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self setupProgram];
    [self setupImageTexture];
    [self setupVBO];
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
