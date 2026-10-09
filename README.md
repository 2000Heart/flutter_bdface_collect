# flutter_bdface_collect

a baidu face offline collect plugin for Android, iOS and OpenHarmony. 【Android: armeabi-v7a、arm64-v8a；iOS: arm64；OHOS: arm64-v8a】

百度人脸离线采集插件，支持 Android、iOS、OpenHarmony。【Android: armeabi-v7a、arm64-v8a；iOS: arm64；OHOS: arm64-v8a】

# PS: Android SDK supports armeabi-v7a / arm64-v8a; iOS SDK is arm64 device-only.
# PS: Android 支持 armeabi-v7a、arm64-v8a；iOS 仅支持真机 arm64。

## SDK Version
| Platform | Version |
|   ----   |--------|
|  Android | 6.4.6  |
|   iOS    | 6.4.x (official FaceSolutionFinance sample IDLFaceSDK, arm64) |
|   OHOS   | faceplatform 6.4.6 / facesolutionsdk 1.0.0 (arm64-v8a) |

> iOS SDK 为 arm64 真机包；模拟器需排除 x86_64。App 体积会明显增大。
> OHOS 仅 arm64-v8a；采集 UI 用 `FlutterBdFacePage` 替代入口 `FlutterPage` 即可（内部已托管 Navigation）。

## Preparing for use

PS：已注释隐私授权检查，故使用前请自行检查授权

### Android
在 Android 项目的`app/src/main/assets` 目录下放入百度离线采集SDK的Android授权文件，文件名固定为 `idl-license.face-android`
SDK 会校验 apk 签名，请使用申请授权相符的签名证书
### OpenHarmony / 鸿蒙

1. 在宿主 `entry/src/main/resources/rawfile/` 放入授权文件，文件名固定为 `idl-license.face-harmony`（需与应用 bundleName / 签名匹配）
2. 建议同步放入 `local_config.json`、`quality_config.json`（可参考 `example/ohos`）
3. 在 `module.json5` 声明 `ohos.permission.CAMERA`
4. 入口页用 plugin 提供的 `FlutterBdFacePage` 替代 `FlutterPage`（内部已托管 Navigation，无需再自行 bind）：

```ts
import { FaceCollectNavHolder, FlutterBdFacePage } from 'flutter_bdface_collect';

build() {
  Column() {
    FlutterBdFacePage({ viewId: this.viewId })
  }
  .width('100%')
  .height('100%')
}

onBackPress(): boolean {
  if (FaceCollectNavHolder.handleBackPress()) {
    return true;
  }
  // 再交给 Flutter 默认返回逻辑
  return true;
}
```

> 若宿主已有自己的 `Navigation`，也可继续手动 `FaceCollectNavHolder.bind(pathStack)`，不必使用 `FlutterBdFacePage`。

### iOS

在 `Info.plist` 的 `dict` 标签内添加以下内容
```xml
<key>NSCameraUsageDescription</key>
<string>使用相机</string>
```
在 iOS 项目的 `Runner` 目录下放入百度离线采集SDK的iOS授权文件，文件名固定为 `idl-license.face-ios`，并将文件加入资源
![example](https://raw.githubusercontent.com/fluttercandies/flutter_bdface_collect/main/doc/QQ20210616-175934.jpg)

## Usage

### Init 初始化
```dart 
    late var licenseId;
    if (Platform.isAndroid) licenseId = "demo-face-android";
    else if (Platform.isIOS) licenseId = "demo-face-ios";
    else if (Platform.operatingSystem == "ohos") licenseId = "demo-face-harmony";
    print('开始初始化');
    String? err = await FlutterBdfaceCollect.instance.init(licenseId);
    print('初始化结果${err == null ? '成功' : '失败'}');
```

### Collect 采集
```dart
    FaceConfig config = FaceConfig(livenessTypes: Set.from(LivenessType.all.sublist(1, 4)));
    CollectRresult res = await FlutterBdfaceCollect.instance.collect(config);
    print('采集错误结果:${res.error.isNotEmpty} 内容：${res.error}');
    print('采集原图imageCropBase64:${res.imageSrcBase64.isNotEmpty}');
    print('采集抠图imageSrcBase64:${res.imageCropBase64.isNotEmpty}');
```
### UnInit 释放
```dart
    FlutterBdfaceCollect.instance.unInit();
```

## 常见问题
### iOS
### Android
### OpenHarmony










