//
//  OpenGLView.m
//  Tutorial03
//
//  Created by heyonly on 2019/6/3.
//  Copyright © 2019 heyonly. All rights reserved.
//
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "OpenGLView.h"
#import "Utils/ksMatrix.h"
#import "Utils/ksVector.h"

@interface OpenGLView ()
{
    CAEAGLLayer         *_eaglLayer;
    EAGLContext         *_context;
    
    GLuint              _programHandle;
    GLuint              _frameBuffer;
    GLuint              _colorRenderBuffer;
    
    GLuint              _positionSlot;
    GLuint              _colorSlot;
    GLuint              _modelViewSlot;
    GLuint              _projectionSlot;
    
    ksMatrix4           _shouldModelViewMatrix;
    ksMatrix4           _elbowModelViewMatrix;
    
    ksMatrix4           _modelViewMatrix;
    ksMatrix4           _projectionMatrix;
    
    float               _rotateColorCube;
    CADisplayLink       *_displayLink;
}

@property (nonatomic, assign) float rotateShoulder;
@property (nonatomic, assign) float rotateElbow;

@end

@implementation OpenGLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer *)self.layer;
}

- (void)setupContext {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!_context) {
        NSLog(@"Failed to create context!!");
        return;
    }
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"set current context Failed!!");
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

- (void)setupProjection {
    float aspect = self.frame.size.width / self.frame.size.height;
    
    ksMatrixLoadIdentity(&_projectionMatrix);
    
    ksPerspective(&_projectionMatrix, 60.0, aspect, 1.0f, 20.0f);
    
    glUniformMatrix4fv(_projectionSlot, 1, GL_FALSE, (GLfloat *)&_projectionMatrix.m[0][0]);
    glEnable(GL_CULL_FACE);
}

- (void)setupProgram {
    NSString *vertexShaderFile = [[NSBundle mainBundle] pathForResource:@"VertexShader" ofType:@"glsl"];
    NSString *fragmentShaderFile = [[NSBundle mainBundle] pathForResource:@"FragmentShader" ofType:@"glsl"];
    
    NSString *vertexShaderString = [NSString stringWithContentsOfFile:vertexShaderFile encoding:NSUTF8StringEncoding error:nil];
    const char *vertexShaderStringUTF8 = [vertexShaderString UTF8String];
    
    NSString *fragmentShaderString = [NSString stringWithContentsOfFile:fragmentShaderFile encoding:NSUTF8StringEncoding error:nil];
    const char *fragmentShaderStringUTF8 = [fragmentShaderString UTF8String];
    
    
    
    GLuint verShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(verShader, 1, &vertexShaderStringUTF8, NULL);
    glCompileShader(verShader);
    
    GLint success;
    GLchar infoLog[512];
    glGetShaderiv(verShader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(verShader, 512, 0, infoLog);
        NSLog(@"compile verShader Failed: %s",infoLog);
    }
    
    GLuint fragShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragShader, 1, &fragmentShaderStringUTF8, NULL);
    glCompileShader(fragShader);
    glGetShaderiv(fragShader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(fragShader, 512, 0, infoLog);
        NSLog(@"compile verShader Failed: %s",infoLog);
    }
    
    _programHandle = glCreateProgram();
    glAttachShader(_programHandle, verShader);
    glAttachShader(_programHandle, fragShader);
    glLinkProgram(_programHandle);
    
    glGetProgramiv(_programHandle, GL_LINK_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(_programHandle, 512, 0, infoLog);
        NSLog(@"link program Failed: %s",infoLog);
    }
    glUseProgram(_programHandle);
    
    _positionSlot = glGetAttribLocation(_programHandle, "vPosition");
    _colorSlot = glGetAttribLocation(_programHandle, "vSourceColor");
    
    _projectionSlot = glGetUniformLocation(_programHandle, "projection");
    _modelViewSlot = glGetUniformLocation(_programHandle, "modelView");
    
    
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
}

- (void)updateColorTransform {
    ksMatrixLoadIdentity(&_modelViewMatrix);
    
    ksMatrixTranslate(&_modelViewMatrix, 0.0, -2, -5.5);
    ksMatrixRotate(&_modelViewMatrix, _rotateColorCube, 0.0, 1.0, 0.0);
    
    glUniformMatrix4fv(_modelViewSlot, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
}

- (void)render {
    glClearColor(0.0, 1.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    ksColor colorRed = {1,0,0,1};
    ksColor colorWhite = {1,1,1,1};
    
    
//    [self updateColorTransform];
//    [self drawColorCube];
    
    [self updateShoulderTransform];
    [self drawCube:colorRed];
//
    [self updateElbowTransform];
    [self drawCube:colorWhite];
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)drawCube:(ksColor)color
{
    GLfloat vertices[] = {
        0.0f, -0.5f, 0.5f,
        0.0f, 0.5f, 0.5f,
        1.0f, 0.5f, 0.5f,
        1.0f, -0.5f, 0.5f,
        
        1.0f, -0.5f, -0.5f,
        1.0f, 0.5f, -0.5f,
        0.0f, 0.5f, -0.5f,
        0.0f, -0.5f, -0.5f,
    };
    
    GLubyte indices[] = {
        0, 1, 1, 2, 2, 3, 3, 0,
        4, 5, 5, 6, 6, 7, 7, 4,
        0, 7, 1, 6, 2, 5, 3, 4
    };
    
    glVertexAttrib4f(_colorSlot, color.r, color.g, color.b, color.a);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    
    glEnableVertexAttribArray(_positionSlot);
    
    glDrawElements(GL_LINES, sizeof(indices)/sizeof(GLubyte), GL_UNSIGNED_BYTE, indices);
}

- (void)updateShoulderTransform
{
    ksMatrixLoadIdentity(&_shouldModelViewMatrix);
    
    ksMatrixTranslate(&_shouldModelViewMatrix, -0.0, 0.0, -5.5);
    
    ksMatrixRotate(&_shouldModelViewMatrix, 0.5 * 90, 0.0, 0.0, 1.0);
    
    ksMatrixCopy(&_modelViewMatrix, &_shouldModelViewMatrix);
    
    ksMatrixScale(&_modelViewMatrix, 1.5, 0.6, 0.6);
    
    glUniformMatrix4fv(_modelViewSlot, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
}

- (void)updateElbowTransform {
    ksMatrixCopy(&_elbowModelViewMatrix, &_shouldModelViewMatrix);
    
    ksMatrixTranslate(&_elbowModelViewMatrix, 1.5, 0.0, 0.0);
    
    ksMatrixRotate(&_elbowModelViewMatrix, 0.5 * 90, 0.0, 0.0, 1.0);
    
    ksMatrixCopy(&_modelViewMatrix, &_elbowModelViewMatrix);
    
    ksMatrixScale(&_modelViewMatrix, 1.0, 0.4, 0.4);
    
    glUniformMatrix4fv(_modelViewSlot, 1, GL_FALSE, (GLfloat *)&_modelViewMatrix.m[0][0]);
}

- (void)drawColorCube {
    GLfloat vertices[] = {
        -0.5f, -0.5f, 0.5f, 1.0, 0.0, 0.0, 1.0,     // red
        -0.5f, 0.5f, 0.5f, 1.0, 1.0, 0.0, 1.0,      // yellow
        0.5f, 0.5f, 0.5f, 0.0, 0.0, 1.0, 1.0,       // blue
        0.5f, -0.5f, 0.5f, 1.0, 1.0, 1.0, 1.0,      // white
        
        0.5f, -0.5f, -0.5f, 1.0, 1.0, 0.0, 1.0,     // yellow
        0.5f, 0.5f, -0.5f, 1.0, 0.0, 0.0, 1.0,      // red
        -0.5f, 0.5f, -0.5f, 1.0, 1.0, 1.0, 1.0,     // white
        -0.5f, -0.5f, -0.5f, 0.0, 0.0, 1.0, 1.0,    // blue
    };
    
    GLubyte indices[] = {
        // Front face
        0, 3, 2, 0, 2, 1,
        
        // Back face
        7, 5, 4, 7, 6, 5,
        
        // Left face
        0, 1, 6, 0, 6, 7,
        
        // Right face
        3, 4, 5, 3, 5, 2,
        
        // Up face
        1, 2, 5, 1, 5, 6,
        
        // Down face
        0, 7, 4, 0, 4, 3
    };
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 7 * sizeof(float), vertices);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, 7 * sizeof(float), vertices+3);
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(GLubyte), GL_UNSIGNED_BYTE, indices);
}

- (void)layoutSubviews {
    [self setupLayer];
    [self setupContext];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self setupProgram];
    [self setupProjection];
    [self render];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
