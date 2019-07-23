//
//  ViewController.m
//  Tutorial03
//
//  Created by heyonly on 2019/7/9.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "ViewController.h"

template <typename T1,typename T2, typename T3 = int>
class CeilDemo {
    
    
public:
    int ceil(T1 t1,T2 t2,T3 t3) {
        printf("%f, %f, %d\n",t1,t2,t3);
        return (int)t1 + (int)t2 + t3;
    }
    
};

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CeilDemo<double, float> a;
    int ret = a.ceil(3.2, 2.3, 4);
    printf("%d\n",ret);
}


@end
