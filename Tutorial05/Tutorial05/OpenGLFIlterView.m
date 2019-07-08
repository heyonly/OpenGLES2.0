//
//  OpenGLFIlterView.m
//  Tutorial05
//
//  Created by heyonly on 2019/6/13.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "OpenGLFIlterView.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreGraphics/CoreGraphics.h>

#import "ksMatrix.h"
#import "ksVector.h"

@interface OpenGLFIlterView ()
{
    EAGLContext             *_context;
    CAEAGLLayer             *_eaglLayer;
    
    GLuint                  _colorRenderBuffer;
    GLuint                  _frameBuffer;
    
    GLuint                  _programHandle;
    
    GLuint                  _positionSlot;
    GLuint                  _textureCoordsSlot;
    GLuint                  _textureSlot;
    
    GLuint                  _texture1;
    GLuint                  _vignetteCenterUniform;
    GLuint                  _vignetteColorUniform;
    GLuint                  _vignetteStartUniform;
    GLuint                  _vignetteEndUniform;
    
    
    CVOpenGLESTextureCacheRef   _coreVideoTextureCache;
    CVPixelBufferRef            _renderTarget;
    CVOpenGLESTextureRef        _renderTexture;
    
}

@end

@implementation OpenGLFIlterView
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
        NSLog(@"alloc context failed!!");
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"failed set current context!!");
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
    NSString *vertexFile = [[NSBundle mainBundle]pathForResource:@"VertexShaderFilter" ofType:@"glsl"];
    NSString *fragmentFile = [[NSBundle mainBundle] pathForResource:@"FragmentShaderFilter" ofType:@"glsl"];
    _programHandle = [self loadProgram:vertexFile fragmentFile:fragmentFile];
    
    
    
    _positionSlot = glGetAttribLocation(_programHandle, "position");
    _textureCoordsSlot = glGetAttribLocation(_programHandle, "inputTextureCoordinate");
    _textureSlot = glGetUniformLocation(_programHandle, "inputImageTexture");
    glUseProgram(_programHandle);
    
//    [self setDefaultValue];
}

- (void)setupTexture {
    _texture1 = [self createTexture2D:@"timg.jpeg"];
    glEnable(GL_TEXTURE_2D);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture1);
    glUniform1i(_textureSlot, 0);
    
    // 设置图像拉伸变形时的处理方法
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
}

- (void)setDefaultValue {
    CGPoint pointValue = CGPointMake(0.5, 0.5);
    GLfloat positionArray[2];
    
    positionArray[0] = pointValue.x;
    positionArray[1] = pointValue.y;
    
    glUniform2fv(_vignetteCenterUniform, 1, positionArray);
    
    ksVec3 defaultColor = {0.0,0.0,0.0};
    
    glUniform3fv(_vignetteColorUniform, 1, (GLfloat*)&defaultColor);
    
    glUniform1f(_vignetteStartUniform, 0.3);
    glUniform1f(_vignetteEndUniform, 1.0);
}


- (void)render {
    glClearColor(0.0, 1.0, 0.0, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    GLfloat vertices[] = {
        // 第一个三角形           // 纹理
        -1.0f, 1.0f, 0.0f,      0.0f, 1.0f, // 左上
        -1.0f, -1.0f, 0.0f,     0.0f, 0.0f, // 左下
        1.0f, -1.0f, 0.0f,      1.0f, 0.0f, // 右下
        1.0f, 1.0f, 0.0f,       1.0f, 1.0f // 右上
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
    
    glVertexAttribPointer(_textureCoordsSlot, 2, GL_FLOAT, GL_FALSE, 5 *sizeof(GLfloat), (GLfloat*)NULL + 3);
    glEnableVertexAttribArray(_textureCoordsSlot);
    
    glDrawElements(GL_TRIANGLES, sizeof(indexes)/sizeof(indexes[0]), GL_UNSIGNED_BYTE, 0);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
}

- (void)setupTextureCache {
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"failed set current context!!");
    }

    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_coreVideoTextureCache);
    
    CFDictionaryRef empty;
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    err = CVPixelBufferCreate(kCFAllocatorDefault, (int)self.frame.size.width, (int)self.frame.size.height, kCVPixelFormatType_32BGRA, attrs, &_renderTarget);
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _coreVideoTextureCache, _renderTarget, NULL, GL_TEXTURE_2D, GL_RGBA, self.frame.size.width, self.frame.size.height, GL_BGRA, GL_UNSIGNED_BYTE, 0, &_renderTexture);
    glBindTexture(CVOpenGLESTextureGetTarget(_renderTexture), CVOpenGLESTextureGetName(_renderTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(_renderTexture), 0);
}

- (void)glReadPixelBuffer {
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    glFinish();
    NSUInteger totalBytesForImage = (int)self.frame.size.width * (int)self.frame.size.height * 4;
    // It appears that the width of a texture must be padded out to be a multiple of 8 (32 bytes) if reading from it using a texture cache
    
    GLubyte *rawImagePixels;
    
    CGDataProviderRef dataProvider = NULL;
    
    rawImagePixels = (GLubyte *)malloc(totalBytesForImage);
    glReadPixels(0, 0, self.frame.size.width, self.frame.size.height, GL_RGBA, GL_UNSIGNED_BYTE,rawImagePixels);
    
    dataProvider = CGDataProviderCreateWithData(NULL, rawImagePixels, totalBytesForImage, NULL);
    CGColorSpaceRef defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImageFromBytes = CGImageCreate((int)self.frame.size.width, (int)self.frame.size.height, 8, 32, 4 * (int)self.frame.size.width, defaultRGBColorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaLast, dataProvider, NULL, NO, kCGRenderingIntentDefault);
    
    
    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(defaultRGBColorSpace);

    UIImage *image = [UIImage imageWithCGImage:cgImageFromBytes scale:1.0 orientation:UIImageOrientationDownMirrored];
    NSLog(@"iamge: %@",image);
    
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
}

- (void)imageFromPixelBuffer {
    GLfloat vertices[] = {
        // 第一个三角形           // 纹理
        -1.0f, 1.0f, 0.0f,      0.0f, 1.0f, // 左上
        -1.0f, -1.0f, 0.0f,     0.0f, 0.0f, // 左下
        1.0f, -1.0f, 0.0f,      1.0f, 0.0f, // 右下
        1.0f, 1.0f, 0.0f,       1.0f, 1.0f // 右上
    };
    GLbyte indexes[] = {
        0, 1, 2,
        0, 2, 3
    };
    
    
    
    
    
    NSUInteger paddedWithOfImage = CVPixelBufferGetBytesPerRow(_renderTarget)/4.0;
    NSUInteger paddedBytesForImage = paddedWithOfImage * (int)self.frame.size.height * 4;
    glFinish();
    CFRetain(_renderTarget);
    CVPixelBufferLockBaseAddress(_renderTarget, 0);
    
    GLubyte *rawImagePixels;
    CGDataProviderRef dataProvider = NULL;
    rawImagePixels = (GLubyte *)CVPixelBufferGetBaseAddress(_renderTarget);
    dataProvider = CGDataProviderCreateWithData((__bridge_retained void*)self, rawImagePixels, paddedBytesForImage, NULL);
    
    CGColorSpaceRef defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef cgImageFromBytes;
    cgImageFromBytes = CGImageCreate((int)self.frame.size.width, (int)self.frame.size.height, 8, 32, CVPixelBufferGetBytesPerRow(_renderTarget), defaultRGBColorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst, dataProvider, NULL, NO, kCGRenderingIntentDefault);

    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    
    UIImage *image = [UIImage imageWithCGImage:cgImageFromBytes];
    NSLog(@"iamge: %@",image);
    
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
}

- (void)layoutSubviews {
    [self setupLayer];
    [self setupContext];
    [self setupColorRenderBuffer];
    [self setupFrameBuffer];
    [self setupProgram];
//    [self setupTextureCache];
    [self setupTexture];
    [self render];
//    [self imageFromPixelBuffer];
    [self glReadPixelBuffer];
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
    glBindTexture(GL_TEXTURE_2D, 0);
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
