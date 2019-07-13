//
//  OpenGLKView.m
//  Tutorial06
//
//  Created by heyonly on 2019/7/11.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "OpenGLKView.h"
#import "sphere.h"

#define kLimitDegree 35.0f

@interface OpenGLKView ()
{
    EAGLContext             *_context;
    CAEAGLLayer             *_eaglLayer;
    GLuint                  _positionVbo;
    GLuint                  _normalVbo;
    GLuint                  _textCoordsVbo;
}
@property (nonatomic, strong) GLKBaseEffect *baseEffect;

@property(nonatomic, assign)CGFloat degreeY;
@property(nonatomic, assign)CGFloat degreeX;

@end

@implementation OpenGLKView
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.drawableDepthFormat = GLKViewDrawableDepthFormat16;
        [self setupContext];
        [self setupBaseEffect];
        [self setupTexture];
        [self setupVBO];
        [self setupBaseTransform];
//        [self setupVertex];
        
    }
    return self;
}

- (void)setupContext {
    
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    [EAGLContext setCurrentContext:self.context];
    
    
}

- (void)setupBaseEffect {
    self.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    
    glEnable(GL_DEPTH_TEST);
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
    
    self.baseEffect.light0.enabled = GL_TRUE;
    self.baseEffect.light0.diffuseColor = GLKVector4Make(0.7f, 0.7f, 0.7f, 1.0f);
    
    self.baseEffect.light0.ambientColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    
    self.baseEffect.light0.position = GLKVector4Make(1.0f, 0.0f, -0.8f, 0.0f);
    
    
}

- (void)setupBaseTransform {
    GLKMatrix4 mat = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -3.0f);
    mat = GLKMatrix4RotateY(mat, GLKMathDegreesToRadians(45));
    GLKMatrix4 temMat = GLKMatrix4RotateX(mat, GLKMathDegreesToRadians(45));
    self.baseEffect.transform.modelviewMatrix = temMat;
    
    float aspect = self.frame.size.width / self.frame.size.height;
    
    GLKMatrix4 matPersPective = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(60.0), aspect, 0.1f, 50.f);
    
    self.baseEffect.transform.projectionMatrix = matPersPective;
}

- (void)setupTexture {
    CGImageRef imageRef = [[UIImage imageNamed:@"Earth512x256.jpg"] CGImage];
    
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:imageRef options:@{GLKTextureLoaderOriginBottomLeft:@(YES)} error:NULL];
    self.baseEffect.texture2d0.enabled = GL_TRUE;
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.baseEffect.texture2d0.target = textureInfo.target;
    
    
}

- (void)setupVBO {
    glGenBuffers(1, &_positionVbo);
    glBindBuffer(GL_ARRAY_BUFFER, _positionVbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(sphereVerts), sphereVerts, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3 *sizeof(GLfloat), 0);
    
    glGenBuffers(1, &_normalVbo);
    glBindBuffer(GL_ARRAY_BUFFER, _normalVbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(sphereNormals), sphereNormals, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), 0);
    
    
    glGenBuffers(1, &_textCoordsVbo);
    glBindBuffer(GL_ARRAY_BUFFER, _textCoordsVbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(sphereTexCoords), sphereTexCoords, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), 0);
    
    
    
}




- (void)render {
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
//    glViewport(0, 0, self.frame.size.width, self.frame.size.height);

    
    [self.baseEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, sphereNumVerts);
}


- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    UITouch * touch = touches.anyObject;
    CGPoint currentPoint = [touch locationInView:self];
    CGPoint previousPoint = [touch previousLocationInView:self];
    
    self.degreeY += currentPoint.y - previousPoint.y;
    self.degreeX += currentPoint.x - previousPoint.x;
    
//    if (self.degreeY > kLimitDegree) {
//        self.degreeY = kLimitDegree;
//    }
//    if (self.degreeY < -kLimitDegree) {
//        self.degreeY = -kLimitDegree;
//    }
    [self update];
    
}


/**
 系统会调用些方法
 */
- (void)update{
    
    // 设置物体变换 （让物体远离是为了能看全，因为摄像机默认在0，0，0点，即在物体内部）
    GLKMatrix4 mat = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -3.0f);
    
    mat = GLKMatrix4RotateX(mat, GLKMathDegreesToRadians(self.degreeY));
    
    GLKMatrix4 temMat = GLKMatrix4RotateY(mat, GLKMathDegreesToRadians(self.degreeX));
    
    self.baseEffect.transform.modelviewMatrix = temMat;
}



- (void)prepareToDraw0 {
    [self.baseEffect prepareToDraw];
}


@end
