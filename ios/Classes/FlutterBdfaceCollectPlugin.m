#import "FlutterBdfaceCollectPlugin.h"
#import <AVFoundation/AVFoundation.h>
#import <BDFaceBaseKit/FaceSDKManager.h>
#import <BDFaceBaseKit/BDFaceDef.h>

@implementation FlutterBdfaceCollectPlugin {
    BOOL _sdkReady;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"com.fluttercandies.bdface_collect"
            binaryMessenger:[registrar messenger]];
  FlutterBdfaceCollectPlugin* instance = [[FlutterBdfaceCollectPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([call.method isEqualToString:GetPlatformVersion]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if ([call.method isEqualToString:Init]) {
      [self init:call.arguments result:result];
  } else if ([call.method isEqualToString:Collect]) {
      [self collect:call.arguments result:result];
  } else if ([call.method isEqualToString:UnInit]) {
      [self unInit:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (UIViewController *)topViewController {
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive) {
                continue;
            }
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *w in windowScene.windows) {
                if (w.isKeyWindow) {
                    window = w;
                    break;
                }
            }
            if (window != nil) {
                break;
            }
        }
    }
    if (window == nil) {
        window = UIApplication.sharedApplication.keyWindow;
    }
    UIViewController *top = window.rootViewController;
    while (top.presentedViewController != nil) {
        top = top.presentedViewController;
    }
    return top;
}

- (NSString *)statusMessage:(BDFaceCompletionStatusCode)code {
    switch (code) {
        case BDFaceStatusCancel: return @"用户取消";
        case BDFaceStatusSDKNotInit: return @"SDK未初始化";
        case BDFaceStatusSDKNotLoad: return @"SDK未加载";
        case BDFaceStatusNetworkError: return @"网络错误";
        case BDFaceStatusIsRiskDevice: return @"风险设备";
        case BDFaceStatusResultFail: return @"构建数据异常";
        case BDFaceStatusCameraError: return @"相机权限受限,请在设置中启用";
        case BDFaceStatusVideoRecordingFail: return @"视频录制错误";
        case BDFaceStatusCropImageError: return @"抠图失败";
        case BDFaceStatusTimeout: return @"采集超时";
        case BDFaceStatusColorMatchFailed: return @"炫彩色彩错误";
        case BDFaceStatusVideoColorScoreFailed: return @"炫彩分数错误";
        case BDFaceStatusDetectSilentNoPass: return @"静默活体未通过";
        case BDFaceStatusLivenessSilentNoPass: return @"动作活体未通过";
        case BDFaceStatusLivenessActionNotMatch: return @"动作与提示不符";
        case BDFaceStatusIsRunning: return @"正在采集";
        default: return [NSString stringWithFormat:@"采集失败(%ld)", (long)code];
    }
}

- (NSString *)firstImageString:(id)value {
    if ([value isKindOfClass:[NSString class]]) {
        NSString *text = (NSString *)value;
        return text.length > 0 ? text : nil;
    }
    if ([value isKindOfClass:[NSArray class]]) {
        for (id item in (NSArray *)value) {
            NSString *text = [self firstImageString:item];
            if (text.length > 0) {
                return text;
            }
        }
        return nil;
    }
    if ([value isKindOfClass:[FaceCropImageInfo class]]) {
        FaceCropImageInfo *info = (FaceCropImageInfo *)value;
        if (info.originalImageEncryptStr.length > 0) {
            return info.originalImageEncryptStr;
        }
        if (info.cropImageWithBlackEncryptStr.length > 0) {
            return info.cropImageWithBlackEncryptStr;
        }
        if (info.originalImageStr.length > 0) {
            return info.originalImageStr;
        }
        if (info.cropImageWithBlackStr.length > 0) {
            return info.cropImageWithBlackStr;
        }
        return nil;
    }
    if ([value isKindOfClass:[UIImage class]]) {
        NSData *data = UIImageJPEGRepresentation((UIImage *)value, 0.9);
        return data.length > 0 ? [data base64EncodedStringWithOptions:0] : nil;
    }
    if ([value isKindOfClass:[NSData class]]) {
        NSData *data = (NSData *)value;
        return data.length > 0 ? [data base64EncodedStringWithOptions:0] : nil;
    }
    return nil;
}

- (NSDictionary *)collectResultFromDict:(NSDictionary *)result {
    // 新版 BaseKit：originImage / cropImage 为数组；旧版为独立字符串字段
    NSString *src = [self firstImageString:result[@"originImage"]]
        ?: [self firstImageString:result[@"originalImageEncryptStr"]]
        ?: [self firstImageString:result[@"originalImageStr"]];
    NSString *crop = [self firstImageString:result[@"cropImage"]]
        ?: [self firstImageString:result[@"cropImageWithBlackEncryptStr"]]
        ?: [self firstImageString:result[@"cropImageWithBlackStr"]];

    id best = result[@"bestImageInfo"] ?: result[@"cropImageInfo"];
    if ((crop.length == 0 || src.length == 0) && [best isKindOfClass:[FaceCropImageInfo class]]) {
        FaceCropImageInfo *info = (FaceCropImageInfo *)best;
        if (src.length == 0) {
            src = [self firstImageString:info];
        }
        if (crop.length == 0) {
            crop = info.cropImageWithBlackEncryptStr.length > 0
                ? info.cropImageWithBlackEncryptStr
                : info.cropImageWithBlackStr;
        }
    }
    if (crop.length == 0 && src.length > 0) {
        crop = src;
    }
    return @{
        @"imageCropBase64": crop ?: @"",
        @"imageSrcBase64": src ?: @"",
        @"error": @""
    };
}

/// 初始化（官方整包 BDFaceBaseKit）
- (void)init:(NSString*)licenseId result:(FlutterResult)result{
    NSString* licensePath = [[NSBundle mainBundle] pathForResource:@"idl-license" ofType:@"face-ios"];
    if (licensePath.length == 0 || ![[NSFileManager defaultManager] fileExistsAtPath:licensePath]) {
        result(@"errCode: LICENSE_NOT_FOUND, errMsg: idl-license.face-ios 未加入 Runner 资源");
        return;
    }
    if (licenseId.length == 0) {
        result(@"errCode: LICENSE_ID_EMPTY, errMsg: licenseId 为空");
        return;
    }

    // 与官方 Demo 一致：license 文件名 + 可选加密 key 文件名（宿主可按需放入 idl-key.face-ios）
    NSString *licenseName = @"idl-license.face-ios";
    NSString *encryptKeyName = @"idl-key.face-ios";

    [[BDFaceBaseKitManager sharedInstance] initCollectWithLicenseID:licenseId
                                               andLocalLicenceName:licenseName
                                               andEncryptKeyName:encryptKeyName
                                                   andExtradata:@{}
                                                      callback:^(BDFaceInitRemindCode code, NSDictionary *extradata) {
        NSLog(@"[BDFace] BaseKit init licenseId=%@ code=%ld version=%@",
              licenseId, (long)code, [[FaceSDKManager sharedInstance] getVersion] ?: @"");
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == BDFaceInitOK) {
                self->_sdkReady = YES;
                // 不进入 SDK 自带结果页，直接回调 Flutter
                [BDFaceBaseKitManager sharedInstance].paramsCustomConfigItem.isIntoResultView = NO;
                [BDFaceBaseKitManager sharedInstance].paramsCustomConfigItem.isColorType = NO;
                [BDFaceBaseKitManager sharedInstance].paramsCustomConfigItem.checkAgreeBtn = NO;
                result(NULL);
            } else {
                self->_sdkReady = NO;
                result([NSString stringWithFormat:
                        @"errCode: AUTH_FAILED, errMsg: BaseKit初始化失败(code=%ld)。请确认 licenseId、BundleId、签名证书与授权文件匹配",
                        (long)code]);
            }
        });
    }];
}

/// 释放
- (void)unInit:(FlutterResult)result{
    [[BDFaceBaseKitManager sharedInstance] uninitCollect];
    _sdkReady = NO;
    result(NULL);
}

- (void)applyFaceConfig:(NSDictionary *)faceConfigMap {
    BDFaceBaseKitParamsCustomConfigItem *params =
        [BDFaceBaseKitManager sharedInstance].paramsCustomConfigItem;
    if (params == nil) {
        params = [[BDFaceBaseKitParamsCustomConfigItem alloc] initWithParamsConfig];
        [[BDFaceBaseKitManager sharedInstance] setFaceSdkCustomParamsConfig:params];
    }

    NSNumber* minFaceSize = faceConfigMap[@"minFaceSize"];
    NSNumber* notFace = faceConfigMap[@"notFace"];
    NSNumber* brightness = faceConfigMap[@"brightness"];
    NSNumber* brightnessMax = faceConfigMap[@"brightnessMax"];
    NSNumber* blurness = faceConfigMap[@"blurness"];
    NSNumber* occlusionLeftEye = faceConfigMap[@"occlusionLeftEye"];
    NSNumber* occlusionRightEye = faceConfigMap[@"occlusionRightEye"];
    NSNumber* occlusionNose = faceConfigMap[@"occlusionNose"];
    NSNumber* occlusionMouth = faceConfigMap[@"occlusionMouth"];
    NSNumber* occlusionLeftContour = faceConfigMap[@"occlusionLeftContour"];
    NSNumber* occlusionRightContour = faceConfigMap[@"occlusionRightContour"];
    NSNumber* occlusionChin = faceConfigMap[@"occlusionChin"];
    NSNumber* headPitch = faceConfigMap[@"headPitch"];
    NSNumber* headYaw = faceConfigMap[@"headYaw"];
    NSNumber* headRoll = faceConfigMap[@"headRoll"];
    NSNumber* scale = faceConfigMap[@"scale"];
    NSNumber* cropHeight = faceConfigMap[@"cropHeight"];
    NSNumber* cropWidth = faceConfigMap[@"cropWidth"];
    NSNumber* enlargeRatio = faceConfigMap[@"enlargeRatio"];
    NSNumber* faceFarRatio = faceConfigMap[@"faceFarRatio"];
    NSNumber* faceClosedRatio = faceConfigMap[@"faceClosedRatio"];
    NSNumber* sound = faceConfigMap[@"sound"];
    NSNumber* livenessRandom = faceConfigMap[@"livenessRandom"];
    NSNumber* timeoutTime = faceConfigMap[@"timeoutTime"];
    NSArray* livenessTypes = faceConfigMap[@"livenessTypes"];

    if (minFaceSize != nil) { params.minFaceSize = minFaceSize.intValue; }
    if (notFace != nil) { params.notRGBFaceThreshold = notFace.floatValue; }
    if (brightness != nil) { params.minIllumThr = brightness.floatValue; }
    if (brightnessMax != nil) { params.maxIllumThr = brightnessMax.floatValue; }
    if (blurness != nil) { params.blurThr = blurness.floatValue; }
    if (occlusionLeftEye != nil) { params.leftEyeOcclus = occlusionLeftEye.floatValue; }
    if (occlusionRightEye != nil) { params.rightEyeOcclus = occlusionRightEye.floatValue; }
    if (occlusionNose != nil) { params.noseOcclus = occlusionNose.floatValue; }
    if (occlusionMouth != nil) { params.mouthOcclus = occlusionMouth.floatValue; }
    if (occlusionLeftContour != nil) { params.leftCheekOcclus = occlusionLeftContour.floatValue; }
    if (occlusionRightContour != nil) { params.rightCheekOcclus = occlusionRightContour.floatValue; }
    if (occlusionChin != nil) { params.chinOcclus = occlusionChin.floatValue; }
    if (headPitch != nil) { params.pitchThr = headPitch.floatValue; }
    if (headYaw != nil) { params.yawThr = headYaw.floatValue; }
    if (headRoll != nil) { params.rollThr = headRoll.floatValue; }
    if (scale != nil) { params.imageScale = scale.floatValue; }
    if (cropHeight != nil) { params.height = cropHeight.intValue; }
    if (cropWidth != nil) { params.width = cropWidth.intValue; }
    if (enlargeRatio != nil) { params.enlarge_ratio = enlargeRatio.floatValue; }
    if (faceFarRatio != nil) { params.minRectScale = faceFarRatio.floatValue; }
    if (faceClosedRatio != nil) { params.maxRectScale = faceClosedRatio.floatValue; }
    if (sound != nil) { params.isSoundMode = sound.boolValue; }
    if (timeoutTime != nil && timeoutTime.floatValue > 0) {
        params.conditionTimeout = timeoutTime.floatValue;
    }

    params.maxCropImageNum = 3;
    params.isIntoResultView = NO;
    params.isColorType = NO;
    params.isOpenDistanceLive = NO;
    params.checkAgreeBtn = NO;
    params.isPopWindow = YES;

    NSMutableArray *liveActionArray = [NSMutableArray new];
    for (NSString *typeStr in livenessTypes) {
        if (![typeStr isKindOfClass:[NSString class]]) {
            continue;
        }
        if ([typeStr isEqualToString:@"Eye"]) {
            [liveActionArray addObject:@(FaceLivenessActionTypeLiveEye)];
        } else if ([typeStr isEqualToString:@"Mouth"]) {
            [liveActionArray addObject:@(FaceLivenessActionTypeLiveMouth)];
        } else if ([typeStr isEqualToString:@"HeadLeft"]) {
            [liveActionArray addObject:@(FaceLivenessActionTypeLiveYawLeft)];
        } else if ([typeStr isEqualToString:@"HeadRight"]) {
            [liveActionArray addObject:@(FaceLivenessActionTypeLiveYawRight)];
        } else if ([typeStr isEqualToString:@"HeadUp"]) {
            [liveActionArray addObject:@(FaceLivenessActionTypeLivePitchUp)];
        } else if ([typeStr isEqualToString:@"HeadDown"]) {
            [liveActionArray addObject:@(FaceLivenessActionTypeLivePitchDown)];
        } else if ([typeStr isEqualToString:@"HeadLeftOrRight"]) {
            [liveActionArray addObject:@(FaceLivenessActionTypeShakeHead)];
        }
    }

    BOOL useLiveness = liveActionArray.count > 0;
    params.isLivenessType = useLiveness;
    if (useLiveness) {
        params.liveActionArray = liveActionArray;
        params.numOfLiveness = (int)liveActionArray.count;
        params.actionLiveSelectNum = (int)liveActionArray.count;
        params.isLivenessRandom = livenessRandom != nil ? livenessRandom.boolValue : YES;
    } else {
        params.liveActionArray = [NSMutableArray new];
        params.numOfLiveness = 0;
        params.actionLiveSelectNum = 0;
        params.isLivenessRandom = NO;
    }

    [[BDFaceBaseKitManager sharedInstance] setFaceSdkCustomParamsConfig:params];
    [[BDFaceBaseKitManager sharedInstance] facesdkParamsInit];
}

/// 采集
- (void)collect:(NSDictionary*)faceConfigMap result:(FlutterResult)result{
    if (!_sdkReady) {
        result(@{@"imageCropBase64": @"",
                 @"imageSrcBase64": @"",
                 @"error": @"SDK未授权成功，请先 Init 并检查 licenseId/授权文件/BundleId/签名"});
        return;
    }

    void (^presentCollect)(void) = ^{
        [self applyFaceConfig:faceConfigMap];

        UIViewController *presenter = [self topViewController];
        if (presenter == nil) {
            result(@{@"imageCropBase64": @"", @"imageSrcBase64": @"", @"error": @"no presenter view controller"});
            return;
        }

        __block BOOL didReply = NO;
        [[BDFaceBaseKitManager sharedInstance] startWithCurrentController:presenter
                                                            andExtradata:@{}
                                                               callback:^(BDFaceCompletionStatusCode code, NSDictionary *collectResult) {
            if (didReply) {
                return;
            }
            didReply = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (code == BDFaceStatusSuccess) {
                    NSLog(@"[BDFace] collectResult: %@", collectResult);
                    result([self collectResultFromDict:collectResult ?: @{}]);
                } else if (code == BDFaceStatusCancel) {
                    result(NULL);
                } else {
                    result(@{
                        @"imageCropBase64": @"",
                        @"imageSrcBase64": @"",
                        @"error": [self statusMessage:code]
                    });
                }
            });
        }];
    };

    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        result(@{@"imageCropBase64": @"", @"imageSrcBase64": @"", @"error": @"相机权限受限,请在设置中启用"});
        return;
    }
    if (status == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!granted) {
                    result(@{@"imageCropBase64": @"", @"imageSrcBase64": @"", @"error": @"相机权限受限,请在设置中启用"});
                    return;
                }
                presentCollect();
            });
        }];
        return;
    }
    presentCollect();
}
@end
