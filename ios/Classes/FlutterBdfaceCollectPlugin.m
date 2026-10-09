#import "FlutterBdfaceCollectPlugin.h"
#import "BDFaceLivenessViewController.h"
#import "BDFaceDetectionViewController.h"
#import <AVFoundation/AVFoundation.h>

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

///  初始化
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

    // 鉴权可能触发同步网络，放到后台，避免卡住主线程；调试包本地 md5 常为 0，需开启 remoteAuthorize 完成设备绑定
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int authCode = [[FaceSDKManager sharedInstance] setLicenseID:licenseId
                                               andLocalLicenceFile:licensePath
                                               andRemoteAuthorize:YES];
        int initCode = [[FaceSDKManager sharedInstance] initCollect];
        BOOL canWork = [[FaceSDKManager sharedInstance] canWork];
        NSLog(@"[BDFace] licenseId=%@ authCode=%d initCode=%d canWork=%d path=%@",
              licenseId, authCode, initCode, canWork, licensePath);
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_sdkReady = canWork;
            if (canWork) {
                result(NULL);
            } else {
                result([NSString stringWithFormat:
                        @"errCode: AUTH_FAILED, errMsg: 本地授权失败(auth=%d,init=%d)。请确认 licenseId、BundleId、签名证书与授权文件匹配",
                        authCode, initCode]);
            }
        });
    });
}

/// 释放
- (void)unInit:(FlutterResult)result{
    [[FaceSDKManager sharedInstance] uninitCollect];
    _sdkReady = NO;
    result(NULL);
}

/// 采集
- (void)collect:(NSDictionary*)faceConfigMap result:(FlutterResult)result{
    if (!_sdkReady || ![[FaceSDKManager sharedInstance] canWork]) {
        result(@{@"imageCropBase64": @"",
                 @"imageSrcBase64": @"",
                 @"error": @"SDK未授权成功，请先 Init 并检查 licenseId/授权文件/BundleId/签名"});
        return;
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
    NSNumber* sound = faceConfigMap[@"sound"];
    NSNumber* livenessRandom = faceConfigMap[@"livenessRandom"];
    NSNumber* secType = faceConfigMap[@"secType"];
    NSArray* livenessTypes = faceConfigMap[@"livenessTypes"];
    [[FaceSDKManager sharedInstance] setMinFaceSize:minFaceSize.intValue];
    [[FaceSDKManager sharedInstance] setNotFaceThreshold:notFace.floatValue];
    [[FaceSDKManager sharedInstance] setMinIllumThreshold:brightness.floatValue];
    [[FaceSDKManager sharedInstance] setMaxIllumThreshold:brightnessMax.floatValue];
    [[FaceSDKManager sharedInstance] setBlurThreshold:blurness.floatValue];
    [[FaceSDKManager sharedInstance] setOccluLeftEyeThreshold:occlusionLeftEye.floatValue];
    [[FaceSDKManager sharedInstance] setOccluRightEyeThreshold:occlusionRightEye.floatValue];
    [[FaceSDKManager sharedInstance] setOccluLeftCheekThreshold:occlusionLeftContour.floatValue];
    [[FaceSDKManager sharedInstance] setOccluRightCheekThreshold:occlusionRightContour.floatValue];
    [[FaceSDKManager sharedInstance] setOccluNoseThreshold:occlusionNose.floatValue];
    [[FaceSDKManager sharedInstance] setOccluMouthThreshold:occlusionMouth.floatValue];
    [[FaceSDKManager sharedInstance] setCropChinExtend:occlusionChin.floatValue];
    [[FaceSDKManager sharedInstance] setEulurAngleThrPitch:headPitch.floatValue yaw:headYaw.floatValue roll:headRoll.floatValue];
    [[FaceSDKManager sharedInstance] setMaxCropImageNum: 3];
    [[FaceSDKManager sharedInstance] setImageWithScale:scale.floatValue];
    [[FaceSDKManager sharedInstance] setCropFaceSizeHeight:cropHeight.floatValue];
    [[FaceSDKManager sharedInstance] setCropFaceSizeWidth:cropWidth.floatValue];
    [[FaceSDKManager sharedInstance] setCropEnlargeRatio:enlargeRatio.floatValue];
    [[FaceSDKManager sharedInstance] setMinRect:faceFarRatio.floatValue];
    [[FaceSDKManager sharedInstance] setImageEncrypteType:secType.intValue];

    void (^presentCollect)(void) = ^{
        BDFaceBaseViewController* lvc;
        if (livenessTypes.count > 0){
            [[IDLFaceLivenessManager sharedInstance] setEnableSound:sound.boolValue];
            [[NSUserDefaults standardUserDefaults] setObject:@(sound.boolValue) forKey:@"SoundMode"];
            NSMutableArray* liveActionArray = [NSMutableArray new];
            for (NSString *typeStr in livenessTypes) {
                if ([typeStr isEqualToString:@"Eye"]){
                    [liveActionArray addObject:@(FaceLivenessActionTypeLiveEye)];
                } else if ([typeStr isEqualToString:@"Mouth"]){
                    [liveActionArray addObject:@(FaceLivenessActionTypeLiveMouth)];
                } else if ([typeStr isEqualToString:@"HeadLeft"]){
                    [liveActionArray addObject:@(FaceLivenessActionTypeLiveYawLeft)];
                } else if ([typeStr isEqualToString:@"HeadRight"]){
                    [liveActionArray addObject:@(FaceLivenessActionTypeLiveYawRight)];
                } else if ([typeStr isEqualToString:@"HeadUp"]){
                    [liveActionArray addObject:@(FaceLivenessActionTypeLivePitchUp)];
                } else if ([typeStr isEqualToString:@"HeadDown"]){
                    [liveActionArray addObject:@(FaceLivenessActionTypeLivePitchDown)];
                }
            }
            if (liveActionArray.count == 0) {
                result(@{@"imageCropBase64": @"", @"imageSrcBase64": @"", @"error": @"invalid livenessTypes"});
                return;
            }
            BDFaceLivenessViewController* lvc2 = [[BDFaceLivenessViewController alloc] init];
            [lvc2 livenesswithList:liveActionArray order:!livenessRandom.boolValue numberOfLiveness:liveActionArray.count];
            lvc = lvc2;
        } else {
            [[IDLFaceDetectionManager sharedInstance] setEnableSound:sound.boolValue];
            [[NSUserDefaults standardUserDefaults] setObject:@(sound.boolValue) forKey:@"SoundMode"];
            lvc = [[BDFaceDetectionViewController alloc] init];
        }
        __block BOOL didReply = NO;
        lvc.completion = ^(FaceCropImageInfo* bestImage){
            if (didReply) {
                return;
            }
            didReply = YES;
            if (bestImage == NULL) {
                result(NULL);
            } else {
                NSDictionary *res = @{@"imageCropBase64": bestImage.cropImageWithBlackEncryptStr ?: @"",
                                      @"imageSrcBase64": bestImage.originalImageEncryptStr ?: @"",
                                      @"error": @""};
                result(res);
            }
        };
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:lvc];
        navi.navigationBarHidden = true;
        navi.modalPresentationStyle = UIModalPresentationFullScreen;
        UIViewController *presenter = [self topViewController];
        if (presenter == nil) {
            result(@{@"imageCropBase64": @"", @"imageSrcBase64": @"", @"error": @"no presenter view controller"});
            return;
        }
        [presenter presentViewController:navi animated:YES completion:nil];
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
