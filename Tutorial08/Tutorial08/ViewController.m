//
//  ViewController.m
//  Tutorial08
//
//  Created by heyonly on 2019/7/17.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "ViewController.h"
#import "SceneCarModel.h"
#import "SceneRinkModel.h"
#import "SceneCar.h"

static const int SceneNumberOfPOVAnimationSeconds = 2.0;

@interface ViewController ()<SceneCarControllerProtocol>
{
    NSMutableArray              *cars;
    
}
@property (nonatomic, strong) GLKBaseEffect *baseEffect;
@property (nonatomic, assign) GLKVector3    eyePosition;
@property (nonatomic, assign) GLKVector3    lookatPosition;

@property (nonatomic, strong) SceneModel *carModel;
@property (nonatomic, strong) SceneModel *rinkModel;

@property (nonatomic, assign) BOOL shouldUseFirstPersonPOV;
@property (nonatomic, assign) GLfloat   pointOfViewAnimationCountDown;
@property (nonatomic, assign) GLKVector3  targetEyePosition;
@property (nonatomic, assign) GLKVector3  targetLookAtPosition;

@property (nonatomic, assign, readwrite) SceneAxisAllignedBoundingBox rinkBoundingBox;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    cars = [[NSMutableArray alloc] init];
    GLKView *view = (GLKView *)self.view;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:view.context];
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.light0.enabled = GL_TRUE;
    
    self.baseEffect.light0.ambientColor = GLKVector4Make(
                                                         0.6f, // Red
                                                         0.6f, // Green
                                                         0.6f, // Blue
                                                         1.0f);// Alpha
    self.baseEffect.light0.position = GLKVector4Make(
                                                     1.0f,
                                                     0.8f,
                                                     0.4f,
                                                     0.0f);
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    
    self.carModel = [[SceneCarModel alloc] init];
    self.rinkModel = [[SceneRinkModel alloc] init];
    
    self.rinkBoundingBox = self.rinkModel.axisAlignedBoundingBox;
    
    SceneCar   *newCar = [[SceneCar alloc]
                          initWithModel:self.carModel
                          position:GLKVector3Make(1.0, 0.0, 1.0)
                          velocity:GLKVector3Make(1.5, 0.0, 1.5)
                          color:GLKVector4Make(0.0, 0.5, 0.0, 1.0)];
    [cars addObject:newCar];
    
    newCar = [[SceneCar alloc]
              initWithModel:self.carModel
              position:GLKVector3Make(-1.0, 0.0, 1.0)
              velocity:GLKVector3Make(-1.5, 0.0, 1.5)
              color:GLKVector4Make(0.5, 0.5, 0.0, 1.0)];
    [cars addObject:newCar];
    
    newCar = [[SceneCar alloc]
              initWithModel:self.carModel
              position:GLKVector3Make(1.0, 0.0, -1.0)
              velocity:GLKVector3Make(-1.5, 0.0, -1.5)
              color:GLKVector4Make(0.5, 0.0, 0.0, 1.0)];
    [cars addObject:newCar];
    
    newCar = [[SceneCar alloc]
              initWithModel:self.carModel
              position:GLKVector3Make(2.0, 0.0, -2.0)
              velocity:GLKVector3Make(-1.5, 0.0, -0.5)
              color:GLKVector4Make(0.3, 0.0, 0.3, 1.0)];
    [cars addObject:newCar];
    
    
    self.eyePosition = GLKVector3Make(10.5, 5.0, 0.0);
    self.lookatPosition = GLKVector3Make(0.0, 0.5, 0.0);
}

- (void)updatePointOfView {
    if (!self.shouldUseFirstPersonPOV) {
        self.eyePosition = GLKVector3Make(10.5, 5.0, 0.0);
        self.lookatPosition = GLKVector3Make(0.0, 0.5, 0.0);
    }else {
        SceneCar *viewerCar = [cars lastObject];
        
        self.targetEyePosition = GLKVector3Make(viewerCar.position.x, viewerCar.position.y+0.45f, viewerCar.position.z);
        
        self.targetLookAtPosition = GLKVector3Add(_eyePosition, viewerCar.velocity);
    }
}

- (void)update
{
    if(0 < self.pointOfViewAnimationCountDown)
    {
        self.pointOfViewAnimationCountDown -=
        self.timeSinceLastUpdate;
        
        // Update the current eye and look-at positions with slow
        // filter so user can savor the POV animation
        self.eyePosition = SceneVector3SlowLowPassFilter(
                                                         self.timeSinceLastUpdate,
                                                         self.targetEyePosition,
                                                         self.eyePosition);
        self.lookatPosition = SceneVector3SlowLowPassFilter(
                                                            self.timeSinceLastUpdate,
                                                            self.targetLookAtPosition,
                                                            self.lookatPosition);
    }
    else
    {  // Update the current eye and look-at positions with fast
        // filter so POV stays close to car orientation but still
        // has a little "bounce"
        self.eyePosition = SceneVector3FastLowPassFilter(
                                                         self.timeSinceLastUpdate,
                                                         self.targetEyePosition,
                                                         self.eyePosition);
        self.lookatPosition = SceneVector3FastLowPassFilter(
                                                            self.timeSinceLastUpdate,
                                                            self.targetLookAtPosition,
                                                            self.lookatPosition);
    }
    
    // Update the cars
    [cars makeObjectsPerformSelector:
     @selector(updateWithController:) withObject:self];
    
    // Update the target positions
    [self updatePointOfView];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    self.baseEffect.light0.diffuseColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    const GLfloat aspectRatio = (GLfloat)view.drawableWidth/(GLfloat)view.drawableHeight;
    
    self.baseEffect.transform.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(35.0f), aspectRatio, 0.1f, 25.0f);
    
    self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeLookAt(self.eyePosition.x, self.eyePosition.y, self.eyePosition.z, self.lookatPosition.x, self.lookatPosition.y, self.lookatPosition.z, 0, 1.0, 0.0);
    
    [self.baseEffect prepareToDraw];
    [self.rinkModel draw];
    
    for (SceneCar *car in cars) {
        [car drawWithBaseEffect:self.baseEffect];
    }
    
}

- (NSArray *)cars {
    return cars;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation !=
            UIInterfaceOrientationPortraitUpsideDown &&
            interfaceOrientation !=
            UIInterfaceOrientationPortrait);
}
- (IBAction)takeShouldUseFirstPersonPOVFrom:(UISwitch *)sender {
    self.shouldUseFirstPersonPOV = [sender isOn];
    
    self.pointOfViewAnimationCountDown = SceneNumberOfPOVAnimationSeconds;
}
@end
