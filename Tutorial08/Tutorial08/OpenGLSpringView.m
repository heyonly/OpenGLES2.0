//
//  OpenGLSpringView.m
//  Tutorial08
//
//  Created by heyonly on 2019/6/19.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "OpenGLSpringView.h"
static CGFloat const kDefaultOriginTextureHeight = 0.7f;  // 初始纹理高度占控件高度的比例
static NSInteger const kVerticesCount = 8;  // 顶点数量

typedef struct {
    GLKVector3 positionCoord;
    GLKVector2 textureCoord;
} SenceVertex;

@interface OpenGLSpringView ()<GLKViewDelegate>
{
    GLuint              _vbos;
}
@property (nonatomic, strong) GLKBaseEffect *baseEffect;
@property (nonatomic, assign) SenceVertex *vertices;

@property (nonatomic, assign) CGSize currentImageSize;
@property (nonatomic, assign, readwrite) BOOL hasChange;
@property (nonatomic, assign) CGFloat   currentTextureWidth;

@property (nonatomic, assign) GLuint tmpFrameBuffer;
@property (nonatomic, assign) GLuint tmpTexture;

// 用于重新绘制纹理
@property (nonatomic, assign) CGFloat currentTextureStartY;
@property (nonatomic, assign) CGFloat currentTextureEndY;
@property (nonatomic, assign) CGFloat currentNewHeight;

@end








@implementation OpenGLSpringView
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        self.delegate = self;
        [EAGLContext setCurrentContext:self.context];
        
        self.vertices = malloc(sizeof(SenceVertex) * kVerticesCount);
        glClearColor(0, 0, 0, 1);
        glGenBuffers(1, &_vbos);
        glBindBuffer(GL_ARRAY_BUFFER, _vbos);
        glBufferData(GL_ARRAY_BUFFER, sizeof(SenceVertex) * kVerticesCount, self.vertices, GL_STATIC_DRAW);
    }
    return self;
}



- (void)updateImage:(UIImage *)image {
    self.hasChange = NO;
    
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft:@(YES)};
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:[image CGImage] options:options error:nil];
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.currentImageSize = image.size;
    
    CGFloat ratio = (self.currentImageSize.height / self.currentImageSize.width)*(self.bounds.size.width / self.bounds.size.height);
    
    CGFloat textureHeight = MIN(ratio, kDefaultOriginTextureHeight);
    self.currentTextureWidth = textureHeight / ratio;
    
    [self calculateOriginTextureCoordWithTextureSize:self.currentImageSize
                                              startY:0
                                                endY:0
                                           newHeight:0];
    
    glBindBuffer(GL_ARRAY_BUFFER, _vbos);
    glBufferData(GL_ARRAY_BUFFER, sizeof(SenceVertex) * kVerticesCount, self.vertices, GL_STATIC_DRAW);
    
    [self display];
    
}

- (void)calculateOriginTextureCoordWithTextureSize:(CGSize)size
                                            startY:(CGFloat)startY
                                              endY:(CGFloat)endY
                                         newHeight:(CGFloat)newHeight {
    CGFloat ratio = (size.height / size.width)*(self.bounds.size.width/self.bounds.size.height);
    CGFloat textureWidth = self.currentTextureWidth;
    CGFloat textureHeight = textureWidth *ratio;
    
    CGFloat delta = (newHeight - (endY - startY)) * textureHeight;
    
    if (textureHeight + delta >= 1) {
        delta = 1- textureHeight;
        newHeight = delta / textureHeight +(endY - startY);
    }
    
    // 纹理的顶点
    GLKVector3 pointLT = {-textureWidth, textureHeight + delta, 0};  // 左上角
    GLKVector3 pointRT = {textureWidth, textureHeight + delta, 0};  // 右上角
    GLKVector3 pointLB = {-textureWidth, -textureHeight - delta, 0};  // 左下角
    GLKVector3 pointRB = {textureWidth, -textureHeight - delta, 0};  // 右下角
    
    // 中间矩形区域的顶点
    CGFloat startYCoord = MIN(-2 * textureHeight * startY + textureHeight, textureHeight);
    CGFloat endYCoord = MAX(-2 * textureHeight * endY + textureHeight, -textureHeight);
    GLKVector3 centerPointLT = {-textureWidth, startYCoord + delta, 0};  // 左上角
    GLKVector3 centerPointRT = {textureWidth, startYCoord + delta, 0};  // 右上角
    GLKVector3 centerPointLB = {-textureWidth, endYCoord - delta, 0};  // 左下角
    GLKVector3 centerPointRB = {textureWidth, endYCoord - delta, 0};  // 右下角
    
    // 纹理的上面两个顶点
    self.vertices[0].positionCoord = pointLT;
    self.vertices[0].textureCoord = GLKVector2Make(0, 1);
    self.vertices[1].positionCoord = pointRT;
    self.vertices[1].textureCoord = GLKVector2Make(1, 1);
    
    // 中间区域的4个顶点
    self.vertices[2].positionCoord = centerPointLT;
    self.vertices[2].textureCoord = GLKVector2Make(0, 1 - startY);
    self.vertices[3].positionCoord = centerPointRT;
    self.vertices[3].textureCoord = GLKVector2Make(1, 1 - startY);
    self.vertices[4].positionCoord = centerPointLB;
    self.vertices[4].textureCoord = GLKVector2Make(0, 1 - endY);
    self.vertices[5].positionCoord = centerPointRB;
    self.vertices[5].textureCoord = GLKVector2Make(1, 1 - endY);
    
    // 纹理的下面两个顶点
    self.vertices[6].positionCoord = pointLB;
    self.vertices[6].textureCoord = GLKVector2Make(0, 0);
    self.vertices[7].positionCoord = pointRB;
    self.vertices[7].textureCoord = GLKVector2Make(1, 0);
    
    // 保存临时值
    self.currentTextureStartY = startY;
    self.currentTextureEndY = endY;
    self.currentNewHeight = newHeight;
}
- (void)glkView:(nonnull GLKView *)view drawInRect:(CGRect)rect {
    
}



@end
