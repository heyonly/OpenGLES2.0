//
//  SceneCar.m
//  Tutorial08
//
//  Created by heyonly on 2019/7/23.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "SceneCar.h"
@interface SceneCar ()

@property (nonatomic, assign, readwrite) long mCarId;
@property (nonatomic, strong, readwrite) SceneModel *model;
@property (nonatomic, assign, readwrite) GLKVector3 position;
@property (nonatomic, assign, readwrite) GLKVector3 nextPosition;
@property (nonatomic, assign, readwrite) GLKVector3 velocity;
@property (nonatomic, assign, readwrite) GLfloat yawRadians;
@property (nonatomic, assign, readwrite) GLfloat targetYawRadians;
@property (nonatomic, assign, readwrite) GLKVector4 color;
@property (nonatomic, assign, readwrite) GLfloat radius;

@end

@implementation SceneCar
@synthesize model;
@synthesize position;
@synthesize velocity;
@synthesize yawRadians;
@synthesize targetYawRadians;
@synthesize color;
@synthesize nextPosition;
@synthesize radius;


- (id)initWithModel:(SceneModel *)aModel position:(GLKVector3)aPosition velocity:(GLKVector3)aVelocity color:(GLKVector4)aColor {
    if (self = [super init]) {
        self.position = aPosition;
        self.color = aColor;
        self.velocity = aVelocity;
        self.model = aModel;
        
        SceneAxisAllignedBoundingBox axisAlignedBoundingBox = self.model.axisAlignedBoundingBox;
        
        self.radius = 0.5f * MAX(axisAlignedBoundingBox.max.x - axisAlignedBoundingBox.min.x, axisAlignedBoundingBox.max.z - axisAlignedBoundingBox.min.z);
    }
    return self;
}



- (void)updateWithController:
(id <SceneCarControllerProtocol>)controller;
{  // Calculate elapsed time bounded between 1/100th sec. and
    // half a second
    NSTimeInterval   elapsedTimeSeconds =
    MIN(MAX([controller timeSinceLastUpdate], 0.01f), 0.5f);
    
    // Scale velocity based on elapsed time
    GLKVector3 travelDistance =
    GLKVector3MultiplyScalar(self.velocity,
                             elapsedTimeSeconds);
    
    // Update position based on velocity and time since last
    // update
    self.nextPosition = GLKVector3Add(self.position,
                                      travelDistance);
    
    SceneAxisAllignedBoundingBox rinkBoundingBox =
    [controller rinkBoundingBox];
    
    [self bounceOffCars:[controller cars]
            elapsedTime:elapsedTimeSeconds];
    [self bounceOffWallsWithBoundingBox:rinkBoundingBox];
    
    // Accelerate if going slow
    if(0.1 > GLKVector3Length(self.velocity))
    {  // Got so slow that direction is unreliable so
        // launch in a new direction
        self.velocity = GLKVector3Make(
                                       (random() / (0.5f * RAND_MAX)) - 1.0f, // range -1 to 1
                                       0.0f,
                                       (random() / (0.5f * RAND_MAX)) - 1.0f);// range -1 to 1
    }
    else if(4 > GLKVector3Length(self.velocity))
    {  // Speed up in current direction
        self.velocity = GLKVector3MultiplyScalar(
                                                 self.velocity,
                                                 1.01f);
    }
    
    // The dot product is the cos() of the angle between two
    // vectors: in this case, the default orientation of the
    // car model and the car's velocity vector.
    float dotProduct = GLKVector3DotProduct(
                                            GLKVector3Normalize(self.velocity),
                                            GLKVector3Make(0.0, 0, -1.0));
    
    // Set the target yaw angle to match the car's direction of
    // motion
    if(0.0 > self.velocity.x)
    {  // Quadrants II and III use +acos()
        self.targetYawRadians = acosf(dotProduct);
    }
    else
    {  // Quadrants IV and I use -acos()
        self.targetYawRadians = -acosf(dotProduct);
    }
    
    [self spinTowardDirectionOfMotion:elapsedTimeSeconds];
    
    self.position = self.nextPosition;
}

- (void)bounceOffWallsWithBoundingBox:
(SceneAxisAllignedBoundingBox)rinkBoundingBox
{
    if((rinkBoundingBox.min.x + self.radius) >
       self.nextPosition.x)
    {
        self.nextPosition = GLKVector3Make(
                                           (rinkBoundingBox.min.x + self.radius),
                                           self.nextPosition.y, self.nextPosition.z);
        self.velocity = GLKVector3Make(-self.velocity.x,
                                       self.velocity.y, self.velocity.z);
    }
    else if((rinkBoundingBox.max.x - self.radius) <
            self.nextPosition.x)
    {
        self.nextPosition = GLKVector3Make(
                                           (rinkBoundingBox.max.x - self.radius),
                                           self.nextPosition.y, self.nextPosition.z);
        self.velocity = GLKVector3Make(-self.velocity.x,
                                       self.velocity.y, self.velocity.z);
    }
    
    if((rinkBoundingBox.min.z + self.radius) >
       self.nextPosition.z)
    {
        self.nextPosition = GLKVector3Make(self.nextPosition.x,
                                           self.nextPosition.y,
                                           (rinkBoundingBox.min.z + self.radius));
        self.velocity = GLKVector3Make(self.velocity.x,
                                       self.velocity.y, -self.velocity.z);
    }
    else if((rinkBoundingBox.max.z - self.radius) <
            self.nextPosition.z)
    {
        self.nextPosition = GLKVector3Make(self.nextPosition.x,
                                           self.nextPosition.y,
                                           (rinkBoundingBox.max.z - self.radius));
        self.velocity = GLKVector3Make(self.velocity.x,
                                       self.velocity.y, -self.velocity.z);
    }
}

- (void)bounceOffCars:(NSArray *)cars elapsedTime:(NSTimeInterval)elapsedTimeSeconds {
    for (SceneCar *currentCar in cars) {
        if (currentCar != self) {
            float distance = GLKVector3Distance(self.nextPosition, currentCar.nextPosition);
            
            if ((2.0f * self.radius) > distance) {
                GLKVector3 ownVelocity = self.velocity;
                GLKVector3 otherVelocity = currentCar.velocity;
                
                GLKVector3 directionToOtherCar = GLKVector3Subtract(currentCar.position, self.position);
                
                directionToOtherCar = GLKVector3Normalize(directionToOtherCar);
                GLKVector3 negDirectionToOtherCar = GLKVector3Negate(directionToOtherCar);
                
                GLKVector3 tanOwnVecloicty = GLKVector3MultiplyScalar(negDirectionToOtherCar, GLKVector3DotProduct(ownVelocity, negDirectionToOtherCar));
                
                GLKVector3 tanOtherVelocity = GLKVector3MultiplyScalar(directionToOtherCar, GLKVector3DotProduct(otherVelocity, directionToOtherCar));
                
                {
                    self.velocity = GLKVector3Subtract(ownVelocity, tanOwnVecloicty);
                    GLKVector3 travelDistance = GLKVector3MultiplyScalar(self.velocity, elapsedTimeSeconds);
                    
                    self.nextPosition = GLKVector3Add(self.position, travelDistance);
                }
                
                {
                    currentCar.velocity = GLKVector3Subtract(otherVelocity, tanOtherVelocity);
                    
                    GLKVector3 travelDistance = GLKVector3MultiplyScalar(currentCar.velocity, elapsedTimeSeconds);
                    
                    currentCar.nextPosition = GLKVector3Add(currentCar.position, travelDistance);
                }
            }
        }
    }
}


- (void)spinTowardDirectionOfMotion:(NSTimeInterval)elasped {
    self.yawRadians = SceneScalarFastLowPassFilter(elasped, self.targetYawRadians, self.yawRadians);
}

- (void)drawWithBaseEffect:(GLKBaseEffect *)anEffect {
    GLKMatrix4 saveModelViewMatrix = anEffect.transform.modelviewMatrix;
    
    GLKVector4 saveDiffuseColor = anEffect.material.diffuseColor;
    
    GLKVector4 saveAmbientColor = anEffect.material.ambientColor;
    
    anEffect.transform.modelviewMatrix = GLKMatrix4Translate(saveModelViewMatrix, position.x, position.y, position.z);
    
    
    anEffect.transform.modelviewMatrix = GLKMatrix4Rotate(anEffect.transform.modelviewMatrix, self.yawRadians, 0.0, 1.0, 0.0);
    
    anEffect.material.diffuseColor = self.color;
    anEffect.material.ambientColor = self.color;
    
    [anEffect prepareToDraw];
    
    [model draw];
    
    anEffect.transform.modelviewMatrix = saveModelViewMatrix;
    anEffect.material.diffuseColor = saveDiffuseColor;
    anEffect.material.ambientColor = saveAmbientColor;
}


@end
/////////////////////////////////////////////////////////////////
// This function returns a value between target and current. Call
// this function repeatedly to asymptotically return values closer
// to target: "ease in" to the target value.
GLfloat SceneScalarFastLowPassFilter(
                                     NSTimeInterval elapsed,    // seconds elapsed since last call
                                     GLfloat target,            // target value to approach
                                     GLfloat current)           // current value
{  // Constant 50.0 is an arbitrarily "large" factor
    return current + (50.0 * elapsed * (target - current));
}


/////////////////////////////////////////////////////////////////
// This function returns a value between target and current. Call
// this function repeatedly to asymptotically return values closer
// to target: "ease in" to the target value.
GLfloat SceneScalarSlowLowPassFilter(
                                     NSTimeInterval elapsed,    // seconds elapsed since last call
                                     GLfloat target,            // target value to approach
                                     GLfloat current)           // current value
{  // Constant 4.0 is an arbitrarily "small" factor
    return current + (4.0 * elapsed * (target - current));
}


/////////////////////////////////////////////////////////////////
// This function returns a vector between target and current.
// Call repeatedly to asymptotically return vectors closer
// to target: "ease in" to the target value.
GLKVector3 SceneVector3FastLowPassFilter(
                                         NSTimeInterval elapsed,    // seconds elapsed since last call
                                         GLKVector3 target,         // target value to approach
                                         GLKVector3 current)        // current value
{
    return GLKVector3Make(
                          SceneScalarFastLowPassFilter(elapsed, target.x, current.x),
                          SceneScalarFastLowPassFilter(elapsed, target.y, current.y),
                          SceneScalarFastLowPassFilter(elapsed, target.z, current.z));
}


/////////////////////////////////////////////////////////////////
// This function returns a vector between target and current.
// Call repeatedly to asymptotically return vectors closer
// to target: "ease in" to the target value.
GLKVector3 SceneVector3SlowLowPassFilter(
                                         NSTimeInterval elapsed,    // seconds elapsed since last call
                                         GLKVector3 target,         // target value to approach
                                         GLKVector3 current)        // current value
{
    return GLKVector3Make(
                          SceneScalarSlowLowPassFilter(elapsed, target.x, current.x),
                          SceneScalarSlowLowPassFilter(elapsed, target.y, current.y),
                          SceneScalarSlowLowPassFilter(elapsed, target.z, current.z));
}
