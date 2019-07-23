//
//  SceneMesh.m
//  Tutorial08
//
//  Created by heyonly on 2019/7/23.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "SceneMesh.h"
@interface SceneMesh ()
{
    GLuint              _vboId;
    GLuint              _indexBufferId;
}
@property (nonatomic, assign) GLuint name;

//顶点数据
@property (strong, nonatomic, readwrite) NSData *vertexData;
//索引数据
@property (strong, nonatomic, readwrite) NSData *indexData;

@end


@implementation SceneMesh
- (id)initWithVertexAttributeData:(NSData *)vertexAttributes indexData:(NSData *)indices {
    if (self = [super init]) {
        self.vertexData = vertexAttributes;
        self.indexData = indices;
    }
    return self;
}

- (id)initWithPositionCoords:(const GLfloat *)somePositions normalCoords:(const GLfloat *)someNormals texCoords0:(const GLfloat *)someTexCoords0 numberOfPositions:(size_t)countPositions indices:(const GLushort *)someIndices numberOfIndices:(size_t)countIndices
{
    NSMutableData *vertexAttributesData = [[NSMutableData alloc] init];
    
    NSMutableData *indicesData = [[NSMutableData alloc] init];
    
    [indicesData appendBytes:someIndices length:countIndices * sizeof(GLushort)];
    
    //把顶点数据转成二进制
    for(size_t i = 0; i < countPositions; i++)
    {
        SceneMeshVertex currentVertex;
        
        currentVertex.position.x = somePositions[i * 3 + 0];
        currentVertex.position.y = somePositions[i * 3 + 1];
        currentVertex.position.z = somePositions[i * 3 + 2];
        
        currentVertex.normal.x = someNormals[i * 3 + 0];
        currentVertex.normal.y = someNormals[i * 3 + 1];
        currentVertex.normal.z = someNormals[i * 3 + 2];
        
        if(NULL != someTexCoords0)
        {
            currentVertex.texCoords0.s = someTexCoords0[i * 2 + 0];
            currentVertex.texCoords0.t = someTexCoords0[i * 2 + 1];
        }
        else
        {
            currentVertex.texCoords0.s = 0.0f;
            currentVertex.texCoords0.t = 0.0f;
        }
        
        [vertexAttributesData appendBytes:&currentVertex
                                   length:sizeof(currentVertex)];
    }
    
    return [self initWithVertexAttributeData:vertexAttributesData
                                   indexData:indicesData];
}

- (void)prepareToDraw {

    if (0 == _vboId) {
        glGenBuffers(1, &_vboId);
        glBindBuffer(GL_ARRAY_BUFFER, _vboId);
        
        glBufferData(GL_ARRAY_BUFFER, [self.vertexData length], [self.vertexData bytes], GL_STATIC_DRAW);
    }
    
    if (0 == _indexBufferId) {
        glGenBuffers(1, &_indexBufferId);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBufferId);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, [self.indexData length], [self.indexData bytes], GL_STATIC_DRAW);
    }

    
    glBindBuffer(GL_ARRAY_BUFFER, _vboId);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(SceneMeshVertex), NULL+offsetof(SceneMeshVertex, position));
    
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(SceneMeshVertex), NULL+offsetof(SceneMeshVertex, normal) );
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(SceneMeshVertex), NULL+offsetof(SceneMeshVertex, texCoords0));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBufferId);
    
    
}

- (void)drawUnidexedWithMode:(GLenum)mode startVertexIndex:(GLint)first numberOfVertices:(GLsizei)count {
    glDrawArrays(mode, first, count);
}

@end
