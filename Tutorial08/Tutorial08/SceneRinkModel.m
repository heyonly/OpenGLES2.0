//
//  SSceneRinkModel.m
//  Tutorial08
//
//  Created by heyonly on 2019/7/23.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "SceneRinkModel.h"
#import "SceneMesh.h"
#import "bumperRink.h"


@implementation SceneRinkModel
- (id)init {
    SceneMesh *rinkMesh = [[SceneMesh alloc] initWithPositionCoords:bumperRinkVerts normalCoords:bumperRinkNormals texCoords0:NULL numberOfPositions:bumperRinkNumVerts indices:NULL numberOfIndices:0];
    
    if (self = [super initWithName:@"bumberRink" mesh:rinkMesh numberOfVertices:bumperRinkNumVerts]) {
        [self updateAlignedBoundingBoxForVertices:bumperRinkVerts count:bumperRinkNumVerts];
    }
    return self;
}
@end
