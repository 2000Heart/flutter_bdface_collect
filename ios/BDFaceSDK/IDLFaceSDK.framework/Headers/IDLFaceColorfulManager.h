//
//  IDLFaceColorfulManager.h
//  IDLFaceSDK
//
//  Created by 之哥 on 2020/12/29.
//  Copyright © 2020 Baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

@class FaceInfo;

#define TIME_THRESHOLD_FOR_ANOTHER_SESSION 2.0

typedef NS_ENUM(NSUInteger, ColorRemindCode) {
    ColorRemindCodeOK = 0, //成功
    ColorRemindCodeBeyondPreviewFrame,    //出框
    ColorRemindCodeNoFaceDetected, //没有检测到人脸
    ColorRemindCodeFaceMoreThanOneDetected, //没有检测到人脸
    ColorRemindCodeMuchIllumination,
    ColorRemindCodePoorIllumination,   //光照不足
    ColorRemindCodeImageBlured,    //图像模糊
    ColorRemindCodeTooFar,    //太远
    ColorRemindCodeTooClose,  //太近
    ColorRemindCodePitchOutofDownRange,    //头部偏低
    ColorRemindCodePitchOutofUpRange,  //头部偏高
    ColorRemindCodeYawOutofLeftRange,  //头部偏左
    ColorRemindCodeYawOutofRightRange, //头部偏右
    ColorRemindCodeOcclusionLeftEye,   //左眼有遮挡
    ColorRemindCodeOcclusionRightEye,  //右眼有遮挡
    ColorRemindCodeOcclusionNose, //鼻子有遮挡
    ColorRemindCodeOcclusionMouth,    //嘴巴有遮挡
    ColorRemindCodeOcclusionLeftContour,  //左脸颊有遮挡
    ColorRemindCodeOcclusionRightContour, //右脸颊有遮挡
    ColorRemindCodeOcclusionChinCoutour,  //下颚有遮挡
    ColorRemindCodeTimeout,   //超时
    ColorRemindCodeVerifyInitError,          //鉴权失败
    ColorRemindCodeSuccess, //炫彩活体采集成功
    ColorRemindCodeColorMatchFailed, //炫彩活体采集失败
    ColorRemindCodeScreenWillFlash, //屏幕即将闪烁
    ColorRemindCodeBreak, //炫彩中途失败，由于当前颜色没有拿到质量满足的图片
    ColorRemindCodeComplete, //炫彩活体完成
    ColorRemindCodeChangeColor,
    ColorRemindCodeFaceIdChanged   // faceid 发生变化
};

typedef void (^ColorStrategyCompletion) (FaceInfo * faceinfo,NSDictionary * images, ColorRemindCode remindCode);

@interface IDLFaceColorfulManager : NSObject

@property (nonatomic, assign) BOOL enableSound;

@property (nonatomic, copy) NSString *str1, *str2, *str3, *str;//设置当前颜色字段

+ (instancetype)sharedInstance;

/**
 * 人脸采集，成功之后返回扣图图片，原始图片
 * @param image 镜头拿到的图片
 * @param detectRect 检测的Rect
 * @param previewRect 预览的Rect
 * @param colorQuality 炫彩当前颜色是否通过质量检测
 * @param livenessFinished 活体动作是否完成
 * return completion 回调信息
 */
- (void)colorStratrgyWithNormalImage:(UIImage *)image
                         previewRect:(CGRect)previewRect
                          detectRect:(CGRect)detectRect
                      isColorQuality:(BOOL)colorQuality
                    livenessFinished:(BOOL)livenessFinished
                   completionHandler:(ColorStrategyCompletion)completion;


- (void)reset;

- (void)resetTime;

- (void)startInitial;

@end
