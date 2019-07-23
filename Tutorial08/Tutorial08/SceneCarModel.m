//
//  SceneCarModel.m
//  Tutorial08
//
//  Created by heyonly on 2019/7/23.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "SceneCarModel.h"
#import "SceneMesh.h"
#import "bumperCar.h"

@implementation SceneCarModel
- (id)init {
    SceneMesh *carMesh = [[SceneMesh alloc] initWithPositionCoords:bumperCarVerts normalCoords:bumperCarNormals texCoords0:NULL numberOfPositions:bumperCarNumVerts indices:NULL numberOfIndices:0];
    
    if (self = [super initWithName:@"bumberCar" mesh:carMesh numberOfVertices:bumperCarNumVerts]) {
        [self updateAlignedBoundingBoxForVertices:bumperCarVerts count:bumperCarNumVerts];
    }
    return self;
}
@end
