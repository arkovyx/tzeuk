import QtQuick
import Quickshell

QtObject {
    readonly property string homeDir: Quickshell.env("HOME")

    readonly property string wallpapersRoot: {
        const env = Quickshell.env("QS_WALLPAPER_DIR");
        const raw = (env && env.length > 0) ? env : homeDir + "/data/Wallpapers";
        return raw.replace(/\/+$/, "");
    }

    readonly property string cacheDir: homeDir + "/.cache/tzeuk-wallpicker"
    readonly property string thumbDir: cacheDir + "/thumbs"

    readonly property var imageExtensions: ["jpg", "jpeg", "png", "webp", "gif", "bmp", "avif"]

    property string wallpaperBackend: "auto"
    property string colorBackend: "matugen"

    readonly property var setAnimations: ["fade", "wipe", "wave", "grow", "center", "outer", "any"]
    property real transitionDuration: 0.85
    property int transitionFps: 60

    readonly property real cardWidth: 360
    readonly property real cardHeight: 300
    readonly property real cardSkew: -0.30
    readonly property real cardSpacing: 22
}
