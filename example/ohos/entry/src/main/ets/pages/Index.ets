import common from '@ohos.app.ability.common';
import { FaceCollectNavHolder, FlutterBdFacePage } from 'flutter_bdface_collect_plus';

let storage = LocalStorage.getShared()
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS'

@Entry(storage)
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext
  @LocalStorageLink('viewId') viewId: string = "";

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
    this.context.eventHub.emit(EVENT_BACK_PRESS)
    return true
  }
}
