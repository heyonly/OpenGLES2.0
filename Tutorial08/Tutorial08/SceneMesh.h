//
//  SceneMesh.h
//  Tutorial08
//
//  Created by heyonly on 2019/7/23.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
// 顶点数据
typedef struct
{
    GLKVector3 position;
    GLKVector3 normal;
    GLKVector2 texCoords0;
}
SceneMeshVertex;

NS_ASSUME_NONNULL_BEGIN

@interface SceneMesh : NSObject
- (id)initWithVertexAttributeData:(NSData *)vertexAttributes
                        indexData:(NSData *)indices;


- (id)initWithPositionCoords:(const GLfloat *)somePositions
                normalCoords:(const GLfloat *)someNormals
                  texCoords0:(const GLfloat *)someTexCoords0
           numberOfPositions:(size_t)countPositions
                     indices:(const GLushort *)someIndices
             numberOfIndices:(size_t)countIndices;

- (void)prepareToDraw;

- (void)drawUnidexedWithMode:(GLenum)mode
            startVertexIndex:(GLint)first
            numberOfVertices:(GLsizei)count;

- (void)makeDynamicAndUpdateWithVertices:
(const SceneMeshVertex *)someVerts
                        numberOfVertices:(size_t)count;

@end

NS_ASSUME_NONNULL_END
