import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import UIAbility from '@ohos.app.ability.UIAbility';
import common from '@ohos.app.ability.common';
import ArrayList from '@ohos.util.ArrayList';
import HashMap from '@ohos.util.HashMap';
import deviceInfo from '@ohos.deviceInfo';
import {
  FaceLiveManager,
  LivenessTypeEnum,
  LivenessValueModel,
} from 'facesolutionsdk';
import {
  Face,
  InitCallback,
  InitOption,
  LivenessCallback,
  LivenessResult,
} from 'faceplatformsdk';
import { FaceStatusNewEnum, ImageInfo } from 'faceplatform';
import { FaceCollectNavHolder } from './FaceCollectNavHolder';
import { MethodConstants } from './MethodConstants';

class ParsedFaceImages {
  crop: string = '';
  src: string = '';
}

/** FlutterBdfaceCollectPlugin **/
export default class FlutterBdfaceCollectPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private ability: UIAbility | null = null;
  private pendingResult: MethodResult | null = null;
  private currentSecType: number = 0;

  getUniqueClassName(): string {
    return 'FlutterBdfaceCollectPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), MethodConstants.ChannelName);
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
    }
    this.channel = null;
    this.pendingResult = null;
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.ability = binding.getAbility();
  }

  onDetachedFromAbility(): void {
    this.ability = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === MethodConstants.GetPlatformVersion) {
      result.success('OpenHarmony ' + deviceInfo.osFullName);
      return;
    }
    if (call.method === MethodConstants.Init) {
      this.init(call, result);
      return;
    }
    if (call.method === MethodConstants.Collect) {
      this.collect(call, result);
      return;
    }
    if (call.method === MethodConstants.UnInit) {
      this.unInit(result);
      return;
    }
    result.notImplemented();
  }

  private getContext(): common.UIAbilityContext | null {
    if (this.ability == null) {
      return null;
    }
    return this.ability.context;
  }

  private buildCollectPayload(crop: string, src: string, error: string): Record<string, string> {
    const payload: Record<string, string> = {};
    payload['imageCropBase64'] = crop;
    payload['imageSrcBase64'] = src;
    payload['error'] = error;
    return payload;
  }

  private init(call: MethodCall, result: MethodResult): void {
    const context = this.getContext();
    if (context == null) {
      result.success('errCode: OTHER_ERROR, errMsg: UIAbilityContext is null');
      return;
    }
    let licenseId = '';
    if (typeof call.args === 'string') {
      licenseId = call.args as string;
    }
    if (licenseId.length === 0) {
      result.success('errCode: OTHER_ERROR, errMsg: licenseId is empty');
      return;
    }

    const initOption: InitOption = new InitOption();
    initOption.licenseKey = licenseId;
    initOption.licenseFileName = MethodConstants.LicenseFileName;
    initOption.encKeyFileName = '';

    const callback: InitCallback = {
      onSuccess: (_code: number, _desc: string): void => {
        result.success(null);
      },
      onError: (code: number, desc: string): void => {
        result.success('errCode: ' + code.toString() + ', errMsg: ' + desc);
      }
    };
    FaceLiveManager.getInstance().init(context, initOption, callback);
  }

  private collect(call: MethodCall, result: MethodResult): void {
    if (this.pendingResult != null) {
      result.success(this.buildCollectPayload('', '', 'collect already in progress'));
      return;
    }
    const navPathStack = FaceCollectNavHolder.get();
    if (navPathStack == null) {
      result.success(this.buildCollectPayload(
        '',
        '',
        'NavPathStack not bound. Wrap FlutterPage with Navigation and call FaceCollectNavHolder.bind(pathStack).'
      ));
      return;
    }

    this.applyFaceConfig(call);
    this.pendingResult = result;

    const callback: LivenessCallback = {
      onLivenessResult: (livenessResult: LivenessResult): void => {
        this.handleLivenessResult(livenessResult);
      },
      onLivenessCancel: (): void => {
        const pending = this.pendingResult;
        this.pendingResult = null;
        if (pending != null) {
          pending.success(null);
        }
      }
    };
    FaceLiveManager.getInstance().startFaceLiveness(null, callback, navPathStack);
  }

  private unInit(result: MethodResult): void {
    FaceLiveManager.getInstance().release();
    this.pendingResult = null;
    result.success(null);
  }

  private handleLivenessResult(livenessResult: LivenessResult): void {
    const pending = this.pendingResult;
    this.pendingResult = null;
    if (pending == null) {
      return;
    }

    let crop = '';
    let src = '';
    const status = livenessResult.getStatus();
    const isOk = status === FaceStatusNewEnum.OK;
    if (isOk) {
      crop = this.pickBestImage(livenessResult.getBase64ImageCropMap(), this.currentSecType);
      src = this.pickBestImage(livenessResult.getBase64ImageSrcMap(), this.currentSecType);
      // 鸿蒙金融版成功时 map 常为空，图片在 imageData JSON 中
      if (crop.length === 0 && src.length === 0) {
        const parsed = this.parseImagesFromImageData(livenessResult.getImageData());
        crop = parsed.crop;
        src = parsed.src;
      }
    }

    let error = '';
    if (crop.length === 0 && src.length === 0) {
      const message: string = livenessResult.getMessage();
      error = message.length > 0 ? message : 'collect failed';
    }
    pending.success(this.buildCollectPayload(crop, src, error));
  }

  /**
   * 解析 LivenessResult.imageData：
   * {"images":["base64..."],"tags":["1","2","0"]}
   * tags: "0"=原图, "1"=抠图；其余按最高分/首张兜底。
   */
  private parseImagesFromImageData(imageData: string): ParsedFaceImages {
    const result: ParsedFaceImages = new ParsedFaceImages();
    if (imageData.length === 0) {
      return result;
    }
    try {
      const face: Face = JSON.parse(imageData) as Face;
      const images: Array<string> = face.images;
      if (images == null || images.length === 0) {
        return result;
      }
      const tags: Array<string> = face.tags != null ? face.tags : [];

      for (let i = 0; i < images.length; i++) {
        const image: string = images[i];
        if (image.length === 0) {
          continue;
        }
        const tag: string = i < tags.length ? tags[i] : '';
        if (tag === '1') {
          result.crop = image;
        } else if (tag === '0') {
          result.src = image;
        }
      }

      if (result.crop.length === 0 && result.src.length === 0) {
        let bestScore: number = Number.NEGATIVE_INFINITY;
        let best: string = images[0];
        for (let i = 0; i < images.length; i++) {
          const image: string = images[i];
          if (image.length === 0) {
            continue;
          }
          const tag: string = i < tags.length ? tags[i] : '';
          const score: number = Number.parseFloat(tag);
          if (!Number.isNaN(score) && score >= bestScore) {
            bestScore = score;
            best = image;
          }
        }
        result.crop = best;
        result.src = best;
      } else {
        if (result.crop.length === 0) {
          result.crop = result.src;
        }
        if (result.src.length === 0) {
          result.src = result.crop;
        }
      }
    } catch (e) {
    }
    return result;
  }

  private applyFaceConfig(call: MethodCall): void {
    const config = FaceLiveManager.getInstance().getFaceConfig();
    const minFaceSize = this.readNumberArg(call, 'minFaceSize');
    if (minFaceSize != null) {
      config.setMinFaceSize(minFaceSize);
    }
    const notFace = this.readNumberArg(call, 'notFace');
    if (notFace != null) {
      config.setNotFaceValue(notFace);
    }
    const brightness = this.readNumberArg(call, 'brightness');
    if (brightness != null) {
      config.setBrightnessValue(brightness);
    }
    const brightnessMax = this.readNumberArg(call, 'brightnessMax');
    if (brightnessMax != null) {
      config.setBrightnessMaxValue(brightnessMax);
    }
    const blurness = this.readNumberArg(call, 'blurness');
    if (blurness != null) {
      config.setBlurnessValue(blurness);
    }
    const occlusionLeftEye = this.readNumberArg(call, 'occlusionLeftEye');
    if (occlusionLeftEye != null) {
      config.setOcclusionLeftEyeValue(occlusionLeftEye);
    }
    const occlusionRightEye = this.readNumberArg(call, 'occlusionRightEye');
    if (occlusionRightEye != null) {
      config.setOcclusionRightEyeValue(occlusionRightEye);
    }
    const occlusionNose = this.readNumberArg(call, 'occlusionNose');
    if (occlusionNose != null) {
      config.setOcclusionNoseValue(occlusionNose);
    }
    const occlusionMouth = this.readNumberArg(call, 'occlusionMouth');
    if (occlusionMouth != null) {
      config.setOcclusionMouthValue(occlusionMouth);
    }
    const occlusionLeftContour = this.readNumberArg(call, 'occlusionLeftContour');
    if (occlusionLeftContour != null) {
      config.setOcclusionLeftContourValue(occlusionLeftContour);
    }
    const occlusionRightContour = this.readNumberArg(call, 'occlusionRightContour');
    if (occlusionRightContour != null) {
      config.setOcclusionRightContourValue(occlusionRightContour);
    }
    const occlusionChin = this.readNumberArg(call, 'occlusionChin');
    if (occlusionChin != null) {
      config.setOcclusionChinValue(occlusionChin);
    }
    const headPitch = this.readNumberArg(call, 'headPitch');
    if (headPitch != null) {
      config.setHeadPitchValue(headPitch);
    }
    const headYaw = this.readNumberArg(call, 'headYaw');
    if (headYaw != null) {
      config.setHeadYawValue(headYaw);
    }
    const headRoll = this.readNumberArg(call, 'headRoll');
    if (headRoll != null) {
      config.setHeadRollValue(headRoll);
    }
    const eyeClosed = this.readNumberArg(call, 'eyeClosed');
    if (eyeClosed != null) {
      config.setEyeClosedValue(eyeClosed);
    }
    const cropHeight = this.readNumberArg(call, 'cropHeight');
    if (cropHeight != null) {
      config.setCropHeight(cropHeight);
    }
    const cropWidth = this.readNumberArg(call, 'cropWidth');
    if (cropWidth != null) {
      config.setCropWidth(cropWidth);
    }
    const enlargeRatio = this.readNumberArg(call, 'enlargeRatio');
    if (enlargeRatio != null) {
      config.setEnlargeRatio(enlargeRatio);
    }
    const faceFarRatio = this.readNumberArg(call, 'faceFarRatio');
    if (faceFarRatio != null) {
      config.setFaceFarRatio(faceFarRatio);
    }
    const faceClosedRatio = this.readNumberArg(call, 'faceClosedRatio');
    if (faceClosedRatio != null) {
      config.setFaceClosedRatio(faceClosedRatio);
    }
    const secType = this.readNumberArg(call, 'secType');
    if (secType != null) {
      config.setSecType(secType);
      this.currentSecType = secType;
    } else {
      this.currentSecType = 0;
    }
    const sound = this.readBooleanArg(call, 'sound');
    if (sound != null) {
      config.setSound(sound);
    }
    const timeoutTime = this.readNumberArg(call, 'timeoutTime');
    if (timeoutTime != null && timeoutTime > 0) {
      // 秒 -> 毫秒
      config.setTimeDetectModule(timeoutTime * 1000);
    }
    config.setCacheImageNum(3);
    config.setShowResultView(false);
    config.setIsOpenColorLive(false);
    config.setIsOpenDistanceLive(false);

    const types = this.readStringArrayArg(call, 'livenessTypes');
    const actionList = new ArrayList<LivenessTypeEnum>();
    for (let i = 0; i < types.length; i++) {
      const type: string = types[i];
      if (type === 'Eye') {
        actionList.add(LivenessTypeEnum.Eye);
      } else if (type === 'Mouth') {
        actionList.add(LivenessTypeEnum.Mouth);
      } else if (type === 'HeadLeft') {
        actionList.add(LivenessTypeEnum.HeadLeft);
      } else if (type === 'HeadRight') {
        actionList.add(LivenessTypeEnum.HeadRight);
      } else if (type === 'HeadUp') {
        actionList.add(LivenessTypeEnum.HeadUp);
      } else if (type === 'HeadDown') {
        actionList.add(LivenessTypeEnum.HeadDown);
      }
    }

    const openAction = actionList.length > 0;
    config.setIsOpenActionLive(openAction);
    const livenessRandom = this.readBooleanArg(call, 'livenessRandom');
    if (livenessRandom != null) {
      config.setIsLivenessRandom(livenessRandom);
    }
    const model: LivenessValueModel = config.getLivenessValueModel();
    model.actionList = actionList;
    model.actionRandomNumber = actionList.length;
    config.setLivenessValueModel(model);
  }

  private pickBestImage(map: HashMap<String, ImageInfo> | null, secType: number): string {
    if (map == null || map.length === 0) {
      return '';
    }
    let bestScore = -1.0;
    let best = '';
    map.forEach((info: ImageInfo, key: String) => {
      const keyStr = key.toString();
      const parts = keyStr.split('_');
      let score = 0.0;
      if (parts.length > 2) {
        const parsed = Number.parseFloat(parts[2]);
        if (!Number.isNaN(parsed)) {
          score = parsed;
        }
      }
      if (score >= bestScore) {
        bestScore = score;
        if (secType === 0) {
          best = info.getBase64();
        } else {
          best = info.getSecBase64();
        }
      }
    });
    return best;
  }

  private readNumberArg(call: MethodCall, key: string): number | null {
    if (call.args == null || !call.hasArgument(key)) {
      return null;
    }
    try {
      const value: number = call.argument(key) as number;
      if (typeof value === 'number' && !Number.isNaN(value)) {
        return value;
      }
    } catch (_e) {
    }
    return null;
  }

  private readBooleanArg(call: MethodCall, key: string): boolean | null {
    if (call.args == null || !call.hasArgument(key)) {
      return null;
    }
    try {
      const value: boolean = call.argument(key) as boolean;
      if (typeof value === 'boolean') {
        return value;
      }
    } catch (_e) {
    }
    return null;
  }

  private readStringArrayArg(call: MethodCall, key: string): Array<string> {
    const list: Array<string> = new Array<string>();
    if (call.args == null || !call.hasArgument(key)) {
      return list;
    }
    try {
      const value: Array<Object> = call.argument(key) as Array<Object>;
      if (value instanceof Array) {
        for (let i = 0; i < value.length; i++) {
          const item: Object = value[i] as Object;
          if (typeof item === 'string') {
            list.push(item as string);
          }
        }
      }
    } catch (_e) {
    }
    return list;
  }
}
