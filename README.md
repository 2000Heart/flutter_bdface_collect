# flutter_bdface_collect_plus

Baidu face offline collect plugin for **Android / iOS / OpenHarmony**.

百度人脸离线采集插件，支持 Android、iOS、OpenHarmony。

> Fork of [flutter_bdface_collect](https://pub.dev/packages/flutter_bdface_collect) (fluttercandies)，在原项目基础上升级官方 SDK 6.4.x，并新增 OpenHarmony 支持。  
> 原仓库：https://github.com/fluttercandies/flutter_bdface_collect

**ABI：** Android `armeabi-v7a` / `arm64-v8a`；iOS `arm64`（仅真机）；OHOS `arm64-v8a`。

## Install

```yaml
dependencies:
  flutter_bdface_collect_plus: ^1.2.0
```

```dart
import 'package:flutter_bdface_collect_plus/flutter_bdface_collect_plus.dart';
import 'package:flutter_bdface_collect_plus/model.dart';
```

## SDK Version

| Platform | Version |
| -------- | ------- |
| Android  | 6.4.6 |
| iOS      | 6.4.x（官方 FaceSolutionFinance 样例 IDLFaceSDK，arm64） |
| OHOS     | faceplatform 6.4.6 / facesolutionsdk 1.0.0（arm64-v8a） |

> iOS 为 arm64 真机包；模拟器需排除 `x86_64`，App 体积会明显增大。  
> OHOS 采集 UI：用 `FlutterBdFacePage` 替代入口 `FlutterPage`（内部已托管 Navigation）。

## Preparing for use

PS：已注释隐私授权检查，使用前请自行完成授权与合规流程。

### Android

在 Android 项目的 `app/src/main/assets` 目录放入百度离线采集 SDK 授权文件，文件名固定为 `idl-license.face-android`。  
SDK 会校验 APK 签名，请使用与授权申请一致的签名证书。

### OpenHarmony / 鸿蒙

1. 在宿主 `entry/src/main/resources/rawfile/` 放入授权文件，文件名固定为 `idl-license.face-harmony`（需与应用 bundleName / 签名匹配）
2. 在 `module.json5` 声明 `ohos.permission.CAMERA`
3. 入口页用插件提供的 `FlutterBdFacePage` 替代 `FlutterPage`：

```ts
import { FaceCollectNavHolder, FlutterBdFacePage } from 'flutter_bdface_collect_plus';

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
  return true;
}
```

> 若宿主已有自己的 `Navigation`，也可手动 `FaceCollectNavHolder.bind(pathStack)`，不必使用 `FlutterBdFacePage`。

### iOS

在 `Info.plist` 的 `dict` 内添加：

```xml
<key>NSCameraUsageDescription</key>
<string>使用相机</string>
```

在 iOS 项目 `Runner` 目录放入授权文件，文件名固定为 `idl-license.face-ios`，并加入 Copy Bundle Resources。

![example](https://raw.githubusercontent.com/2000Heart/flutter_bdface_collect/main/doc/QQ20210616-175934.jpg)

## Usage

### Init

```dart
late var licenseId;
if (Platform.isAndroid) {
  licenseId = "demo-face-android";
} else if (Platform.isIOS) {
  licenseId = "demo-face-ios";
} else if (Platform.operatingSystem == "ohos") {
  licenseId = "demo-face-harmony";
}
String? err = await FlutterBdfaceCollect.instance.init(licenseId);
```

### Collect

```dart
FaceConfig config = FaceConfig(
  livenessTypes: Set.from(LivenessType.all.sublist(1, 4)),
);
CollectRresult res = await FlutterBdfaceCollect.instance.collect(config);
```

### UnInit

```dart
FlutterBdfaceCollect.instance.unInit();
```

## License

Apache License 2.0.  
Based on work by CyJaySong / fluttercandies；本 fork 的修改由 [2000Heart](https://github.com/2000Heart) 维护。
