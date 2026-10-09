package com.baidu.idl.face.platform;

/**
 * Access package-private FaceConfig setters from the plugin package.
 */
public final class FaceConfigHelper {
    private FaceConfigHelper() {
    }

    public static void setSecType(FaceConfig config, int secType) {
        if (config != null) {
            config.setSecType(secType);
        }
    }
}
