//
//  SSFaceProcessManager.h
//  BDFaceBaseKit
//
//  Created by 之哥 on 2022/8/23.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SSFaceSDK.h"

/**
 * 流程返回结果类型
 */
typedef NS_ENUM(NSInteger, SSFaceProcessStatus) {
    SSFaceProcessStatusSuccess = 1,  // 成功
    SSFaceProcessStatusCancel = -102, // 取消
    SSFaceProcessStatusCameraError = -302,    // 没有授权镜头
    SSFaceProcessStatusCropImageError = -305, // 抠图失败
    SSFaceProcessStatusTimeout = -401, // 超时
    SSFaceProcessStatusVideoRecordingFail = -303, // 视频录制失败
    SSFaceProcessStatusColorMatchFailed = -402, // 炫彩色彩错误
    SSFaceProcessStatusActionNotMatch = -406, // 连续检测到与提示不符动作

};


/**
 * 活体检测过程中，返回活体总数，当前成功个数，当前活体类型
 */
typedef void (^LivenessProcess) (float numberOfLiveness, float numberOfSuccess, LivenessActionType currenActionType);


@protocol SSFaceProcessDelegate <NSObject>

// 开始采集
- (void)onBegin;

// 视频录制
- (void)onBeginCollectFaceInfo;

// 动作活体检测返回
- (void)onLivenessActionWithCode:(LivenessRemindCode)code imageInfo:(NSDictionary *)imageInfo faceInfo:(FaceInfo *)faceInfo;

// 静默活体检测返回
- (void)onDetectionActionWithCode:(DetectRemindCode)code imageInfo:(NSDictionary *)imageInfo faceInfo:(FaceInfo *)faceInfo;

// 炫彩活体检测返回
- (void)onColorfulActionWithCode:(ColorRemindCode)code imageInfo:(NSDictionary *)imageInfo faceInfo:(FaceInfo *)faceInfo;

// 远近距离活体返回
- (void)onDistanceLivenessActionWithCode:(DistanceLivenessRemindCode)code imageInfo:(NSDictionary *)imageInfo faceInfo:(FaceInfo *)faceInfo;

- (void)onBeginBuildData;

// 流程结束返回
- (void)onEnd:(SSFaceProcessStatus)status result:(NSDictionary *)result;

//全流程剩余时间
- (void)onRemainTime:(CGFloat)remainTime;

// 摄像头回调
- (void)captureOutputSampleBuffer:(UIImage *)image;

@end


__attribute__((visibility("default")))
@interface SSFaceProcessManager : NSObject

// 图像返回帧处理代理
@property (nonatomic, weak) id<SSFaceProcessDelegate> delegate;

// 采集流程运行状态
@property (nonatomic, assign, readonly) BOOL runningStatus;

// AVCaptureSessionPreset类型枚举，支持低版本所以使用NSString
@property (nonatomic, copy) NSString *sessionPresent;

// 采集图像区域
@property (nonatomic, assign) CGRect previewRect;

// 探测区域
@property (nonatomic, assign) CGRect detectRect;

// 是否开启声音提醒
@property (nonatomic, assign) BOOL enableSound;

// 设置使用镜头，前置/后置，默认前置
@property (nonatomic, assign) AVCaptureDevicePosition devicePosition;

//摄像头采集方向 默认为竖屏
@property (nonatomic, assign) AVCaptureVideoOrientation videoOrientation;

// 是否使用压缩视频配置 默认不开启
@property (nonatomic, assign) BOOL enableVideoCompressionSettings;

// 自定义视频清晰度，开启压缩视频配置时生效，设置值越小录制视频体积越小。最小值1，最大值10，默认值1
@property (nonatomic, assign) CGFloat videoBitRate;

// 设置录像结果是否镜像翻转，默认翻转
@property (nonatomic, assign) BOOL videoMirrored;

// 返回图片类型
@property (nonatomic, assign) SSFaceProcessImageType outputImageType;

// 输出图片数量，默认1（支持炫彩流程）
@property (nonatomic, assign) NSInteger successImageCount;

// BDFaceDetectionTypeColorfulLiveness流程中是否开启动作活体
@property (nonatomic, assign) BOOL enableLivenessInColorfulFlow;

+ (instancetype)sharedInstance;
/*
 关联视频显示layer
 */
- (void)connectPreviewLayer:(AVCaptureVideoPreviewLayer*)pLayer;

/**
 *  创建视频录制参数
 * @param enableVideoSound 是否开启声音录制
 * @param videoFileName 视频文件名称
 * @param imageWidth 视频宽度
 * @param imageHeight 视频高度
 *  */
- (NSDictionary *)createVideoRecordParametersWithEnableVideoSound:(BOOL)enableVideoSound
                                                    videoFileName:(NSString *)videoFileName
                                                        imageWidth:(NSUInteger)imageWidth
                                                      imageHeight:(NSUInteger)imageHeight;

/**
 * 开始当前人脸校验流程，供视频录制时传入参数使用
 * @param flowType 操作流程，人脸采集、人脸活体、炫彩
 * @param videoParameters 视频参数
 * @param vc 展现的UIViewController
 */
- (void)startFaceProcessWithFaceFlow:(SSFaceProcessType)flowType videoParameters:(NSDictionary *)videoParameters viewController:(UIViewController *)vc;

/**
 * 取消当前人脸校验流程
 */
- (void)cancelFaceProcess;

/**
 * 开始视频录制
 */
- (void)startRecordingVideo;


/**
 * 活体检测过程中，返回活体总数，当前成功个数，当前活体类型
 */
-(void)livenessProcessHandler:(LivenessProcess)process;

/**
 * 返回无黑边的方法
 * @param array 活体动作数组
 * @param order 是否顺序执行
 * @param numberOfLiveness 活体动作个数
 */
- (void)livenesswithList:(NSArray *)array order:(BOOL)order numberOfLiveness:(NSInteger)numberOfLiveness;

/**
 * 设置炫彩活体颜色顺序
 * @param colorGroup 颜色顺序，如“RGB”
 */
- (void)setColorLivenessColors:(NSString *)colorGroup;

-(void)reset;

@end





