import { FlutterPage } from '@ohos/flutter_ohos';
import { FaceCollectNavHolder } from './FaceCollectNavHolder';

/**
 * Drop-in replacement for FlutterPage that hosts Navigation for Baidu Face SDK.
 * Host apps can use this instead of manually wrapping Navigation + FaceCollectNavHolder.bind.
 */
@Component
export struct FlutterBdFacePage {
  @Prop viewId: string = '';
  @State pathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    FaceCollectNavHolder.bind(this.pathStack);
  }

  aboutToDisappear(): void {
    FaceCollectNavHolder.unbind();
  }

  build() {
    Navigation(this.pathStack) {
      Column() {
        FlutterPage({ viewId: this.viewId })
      }
      .width('100%')
      .height('100%')
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
  }
}
