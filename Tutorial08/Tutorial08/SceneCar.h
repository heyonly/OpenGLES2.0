//
//  SceneCar.h
//  Tutorial08
//
//  Created by heyonly on 2019/7/23.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "SceneModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SceneCarControllerProtocol <NSObject>

- (NSTimeInterval)timeSinceLastUpdate;
- (SceneAxisAllignedBoundingBox)rinkBoundingBox;
- (NSArray *)cars;

@end


@interface SceneCar : NSObject
@property (nonatomic, assign, readonly) long mCarId;
@property (nonatomic, strong, readonly) SceneModel *model;
@property (nonatomic, assign, readonly) GLKVector3 position;
@property (nonatomic, assign, readonly) GLKVector3 nextPosition;
@property (nonatomic, assign, readonly) GLKVector3 velocity;
@property (nonatomic, assign, readonly) GLfloat yawRadians;
@property (nonatomic, assign, readonly) GLfloat targetYawRadians;
@property (nonatomic, assign, readonly) GLKVector4 color;
@property (nonatomic, assign, readonly) GLfloat radius;


- (id)initWithModel:(SceneModel *)aModel position:(GLKVector3)aPosition velocity:(GLKVector3)aVelocity color:(GLKVector4)aColor;


- (void)updateWithController:(id<SceneCarControllerProtocol>)controller;

- (void)drawWithBaseEffect:(GLKBaseEffect *)anEffect;

@end
extern GLfloat SceneScalarFastLowPassFilter(
                                            NSTimeInterval timeSinceLastUpdate,
                                            GLfloat target,
                                            GLfloat current);

extern GLfloat SceneScalarSlowLowPassFilter(
                                            NSTimeInterval timeSinceLastUpdate,
                                            GLfloat target,
                                            GLfloat current);

extern GLKVector3 SceneVector3FastLowPassFilter(
                                                NSTimeInterval timeSinceLastUpdate,
                                                GLKVector3 target,
                                                GLKVector3 current);

extern GLKVector3 SceneVector3SlowLowPassFilter(
                                                NSTimeInterval timeSinceLastUpdate,
                                                GLKVector3 target,
                                                GLKVector3 current);

NS_ASSUME_NONNULL_END
