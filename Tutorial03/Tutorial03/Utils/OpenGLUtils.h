//
//  OpenGLUtils.h
//  Tutorial07
//
//  Created by heyonly on 2019/6/22.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenGLUtils : NSObject
+ (GLuint)programWithVertexFile:(NSString *)vertexFile fragmentFile:(NSString *)fragmentFile;

@end

NS_ASSUME_NONNULL_END
