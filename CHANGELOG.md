## 1.2.0

* RENAME package to `flutter_bdface_collect_plus`; Android / channel namespace `com.fluttercandies.*` → `com.heart.*`.
* ADD OpenHarmony (OHOS) platform support.
* UPDATE Baidu Face offline collect SDK to 6.4.x (Android / iOS / OHOS).
* UPDATE iOS to use official BDFaceBaseKit and remove custom collect UI.
* ADD FaceConfig.timeoutTime for collect timeout (seconds).
* FIX OHOS collect result parsing.
* FIX iOS collect stability (action animation crash, auth / camera main-thread jank).
* 包名更名为 `flutter_bdface_collect_plus`；Android / Channel 命名空间由 `com.fluttercandies.*` 改为 `com.heart.*`。
* 新增 OpenHarmony（鸿蒙）平台支持。
* 升级百度人脸离线采集 SDK 至 6.4.x（Android / iOS / 鸿蒙）。
* iOS 接入官方 BDFaceBaseKit，移除自研采集 UI。
* FaceConfig 新增 timeoutTime 采集超时配置（秒）。
* 修复鸿蒙采集结果解析。
* 修复 iOS 采集稳定性（动作动画崩溃、授权与相机主线程卡顿等）。

## 1.1.9

* UPDATE Android compileSdkVersion to 31.
* FIX typos.
* 升级 Android compileSdkVersion 至 31。
* 修正拼写错误。

## 1.1.8

* FIx no result on iOS
* 修复在ios无采集结果问题

## 1.1.7

* FIX crash on ios
* 修复在ios平台崩溃问题

## 1.1.6

* UPDATE README.md
* 更新README.md

## 1.1.5

* UPDATE SDK to 4.1.5
* FIX ios resource import
* 更新SDK版本到 4.1.5
* 整理ios层资源引用

## 1.1.4

* Remove auto start in Android  
* 移除安卓端自启

## 1.1.3

* fix Android projects no longer need to modify AndroidManifest.xml
* 整理 Android项目不再需要修改AndroidManifest.xml

## 1.1.2

* fix IOS device no message callback when close auth page .
* 修复 IOS设备关闭验证页时没有消息回调的情况

## 1.1.1

* Delete redundant binary files of IOS platform.
* 删除IOS平台的冗余二进制文件。

## 1.1.0

* Version of no permission check.
* 无权限检查的版本。

## 1.0.4

* update README, add old-sdk verison guide.
* FIX Wrong type name.
* 更新README,添加old-sdk版本指引。
* 修正错误的类型名称

## 1.0.3

* delete redundant resource.
* 删除多余的资源。

## 1.0.2

* FIX Optimize Android code, avoid data size limit of intent.
* FIX iOS moveface voice.
* FIX iOS import resource.
* 安卓规避 intent 数据大小限制。
* iOS 找脸语言修复。
* iOS 导入资源文件。

## 1.0.1

* Reduce package size.
* 减少插件包大小。

## 1.0.0

* First version.
* 第一个版本。
