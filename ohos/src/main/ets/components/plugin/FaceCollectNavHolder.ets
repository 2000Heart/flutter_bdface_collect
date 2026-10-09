/**
 * Holds the NavPathStack used by FaceLiveManager.
 * Prefer FlutterBdFacePage for automatic bind; advanced hosts may call bind() themselves.
 */
export class FaceCollectNavHolder {
  private static navPathStack: NavPathStack | null = null;

  static bind(navPathStack: NavPathStack): void {
    FaceCollectNavHolder.navPathStack = navPathStack;
  }

  static unbind(): void {
    FaceCollectNavHolder.navPathStack = null;
  }

  static get(): NavPathStack | null {
    return FaceCollectNavHolder.navPathStack;
  }

  /** Pop SDK page if any; return true when consumed. Use from @Entry onBackPress. */
  static handleBackPress(): boolean {
    const stack = FaceCollectNavHolder.navPathStack;
    if (stack != null && stack.size() > 0) {
      stack.pop();
      return true;
    }
    return false;
  }
}
