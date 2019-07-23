//
//  SceneModel.h
//  Tutorial08
//
//  Created by heyonly on 2019/7/17.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "SceneMesh.h"

NS_ASSUME_NONNULL_BEGIN
// 边界，注意min和max都是vector3
typedef struct
{
    GLKVector3 min;
    GLKVector3 max;
}
SceneAxisAllignedBoundingBox;

@interface SceneModel : NSObject
@property (copy, nonatomic, readonly) NSString
*name;
@property (assign, nonatomic, readonly)
SceneAxisAllignedBoundingBox axisAlignedBoundingBox;

- (id)initWithName:(NSString *)aName
              mesh:(SceneMesh *)aMesh
  numberOfVertices:(GLsizei)aCount;

- (void)draw;

- (void)updateAlignedBoundingBoxForVertices:(float *)verts
                                      count:(unsigned int)aCount;

@end

NS_ASSUME_NONNULL_END
