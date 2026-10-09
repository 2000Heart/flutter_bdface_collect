//
//  IDLFaceDistanceLivenessManager.h
//  IDLFaceSDK
//
//  Created by v_renshaolei on 2023/12/25.
//  Copyright © 2023 Baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class FaceInfo;

typedef NS_ENUM(NSUInteger, DistanceLivenessRemindCode) {
    DistanceLivenessRemindCodeOK = 0, //成功
    DistanceLivenessRemindCodeBeyondPreviewFrame,    //出框
    DistanceLivenessRemindCodeNoFaceDetected, //没有检测到人脸
    DistanceLivenessRemindCodeFaceMoreThanOneDetected, //检测到多个人脸
    DistanceLivenessRemindCodeMuchIllumination,
    DistanceLivenessRemindCodePoorIllumination,   //光照不足
    DistanceLivenessRemindCodeImageBlured,    //图像模糊
    DistanceLivenessRemindCodeTooFar,    //太远
    DistanceLivenessRemindCodeTooClose,  //太近
    DistanceLivenessRemindCodePitchOutofDownRange,    //头部偏低
    DistanceLivenessRemindCodePitchOutofUpRange,  //头部偏高
    DistanceLivenessRemindCodeYawOutofLeftRange,  //头部偏左
    DistanceLivenessRemindCodeYawOutofRightRange, //头部偏右
    DistanceLivenessRemindCodeOcclusionLeftEye,   //左眼有遮挡
    DistanceLivenessRemindCodeOcclusionRightEye,  //右眼有遮挡
    DistanceLivenessRemindCodeOcclusionNose, //鼻子有遮挡
    DistanceLivenessRemindCodeOcclusionMouth,    //嘴巴有遮挡
    DistanceLivenessRemindCodeOcclusionLeftContour,  //左脸颊有遮挡
    DistanceLivenessRemindCodeOcclusionRightContour, //右脸颊有遮挡
    DistanceLivenessRemindCodeOcclusionChinCoutour,  //下颚有遮挡
    DistanceLivenessRemindCodeTimeout,   //超时
    DistanceLivenessRemindCodeVerifyInitError,          //鉴权失败
    DistanceLivenessRemindCodeSilentNoPass, //活体阈值偏低
    DistanceLivenessRemindCodeKeepStill, //请保持不动
    DistanceLivenessRemindCodeLiveEye, //眨眨眼
    DistanceLivenessRemindCodeWillCaptureFar, //将采集远景，请缓慢移动远离
    DistanceLivenessRemindCodeWillCaptureNear, //将采集近景，请缓慢移动靠近
    
    
    
    
};


NS_ASSUME_NONNULL_BEGIN

typedef void (^DistanceLivenessCompletion) (FaceInfo *  __nullable faceinfo, NSDictionary * __nullable images, DistanceLivenessRemindCode remindCode);

@interface IDLFaceDistanceLivenessManager : NSObject

@property (nonatomic, assign) BOOL enableSound;

+ (instancetype)sharedInstance;

/**
 * 人脸采集，成功之后返回扣图图片，原始图片
 * @param image 镜头拿到的图片
 * @param previewRect 预览的Rect
 * @param detectRect 检测的Rect
 * return completion 回调信息
 */
- (void)distanceLivenessWithImage:(UIImage *)image
                      previewRect:(CGRect)previewRect
                       detectRect:(CGRect)detectRect
                completionHandler:(DistanceLivenessCompletion)completion;
- (void)reset;
- (void)resetTime;
- (void)resetProperty;
- (void)startInitial;

@end

NS_ASSUME_NONNULL_END
