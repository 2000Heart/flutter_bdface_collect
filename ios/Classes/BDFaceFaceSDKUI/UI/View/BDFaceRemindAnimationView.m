//
//  BDFaceRemindAnimationView.m
//  FaceSDKSample_IOS
//
//  Created by Li,Tonghui on 2020/5/11.
//  Copyright © 2020 Baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDFaceRemindAnimationView.h"

#define FACESDK_ACTION_BUNDLE_NAME @"com.baidu.idl.face.live.action.image.bundle"
#define FACESDK_ACTION_BUNDLE [[NSBundle alloc] initWithPath:[[NSBundle mainBundle] pathForResource:FACESDK_ACTION_BUNDLE_NAME ofType:nil]]

@interface BDFaceRemindAnimationView ()
@property (nonatomic, assign) BOOL isImageSuccess;
@property (nonatomic, readwrite, retain) UIImageView *imageView;
@property (nonatomic, strong) NSMutableDictionary *imageDict;
@end


@implementation BDFaceRemindAnimationView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake((frame.size.width-86.7)/2
                                                                       , (frame.size.height-113.3)/2
                                                                       , 86.7, 113.3)];
        [self addSubview:self.imageView];
        self.isImageSuccess = false;
    }
    return self;
}

- (void)setActionImages {
    
    if (self.isImageSuccess){
           return;
    }

    NSBundle *actionBundle = FACESDK_ACTION_BUNDLE;
    if (actionBundle == nil) {
        NSLog(@"BDFaceRemindAnimationView: action image bundle not found");
        return;
    }

    // New SDK ships 2 frames per action type (0~7): Eye/Mouth/YawRight/YawLeft/PitchUp/PitchDown/UpDown/ShakeHead
    const int actionTypeCount = 8;
    const int framesPerAction = 2;
    self.imageDict = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < actionTypeCount; i++){
        NSMutableArray<UIImage *> *imageArr = [[NSMutableArray alloc] init];
        for (int k = 1; k <= framesPerAction; k++){
            NSString *imageName = [NSString stringWithFormat:@"%d_0%d", i, k];
            NSString *path = [actionBundle pathForResource:imageName ofType:@"png"];
            if (path.length == 0) {
                continue;
            }
            UIImage *image = [UIImage imageWithContentsOfFile:path];
            if (image != nil) {
                [imageArr addObject:image];
            }
        }
        if (imageArr.count > 0) {
            self.imageDict[[NSString stringWithFormat:@"%d", i]] = imageArr;
        }
    }
    self.isImageSuccess = self.imageDict.count > 0;
}

- (BOOL)isActionAnimating {
    return [self.imageView isAnimating];
}

- (void)startActionAnimating:(int)type {
    
    if (!self.isImageSuccess){
        return;
    }
    
    NSMutableArray<UIImage *> *imageArr = self.imageDict[[NSString stringWithFormat:@"%d", type]];
    if (imageArr.count == 0) {
        return;
    }
    
    // 设置动画图片
    self.imageView.animationImages = imageArr;

    // 设置动画的播放次数
    self.imageView.animationRepeatCount = 1;

    // 新资源仅 2 帧，缩短时长避免拖沓
    self.imageView.animationDuration = 1.0;

    // 开始动画
    [self.imageView startAnimating];
}

- (void)stopActionAnimating {
    [self.imageView stopAnimating];
}


@end
