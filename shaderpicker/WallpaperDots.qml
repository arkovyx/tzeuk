import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../themes"

PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    readonly property string stateFile: Quickshell.env("HOME") + "/.cache/tzeuk/shader"
    readonly property string wallpaperFile: Quickshell.env("HOME") + "/.cache/tzeuk/wallpicker/last_wallpaper"
    readonly property string shaderPath: Quickshell.env("HOME") + "/.config/quickshell/tzeuk/shaders/wall.frag.qsb"

    property bool enabled: false
    property string wallPath: ""

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "tzeuk-wallpaper-dots"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    visible: win.enabled && win.wallPath !== ""

    FileView {
        id: stateView
        path: win.stateFile
        watchChanges: true
        blockLoading: true
        onLoaded: win.enabled = (text().trim() === "wall")
        onFileChanged: win.enabled = (text().trim() === "wall")
        onLoadFailed: win.enabled = false
    }

    FileView {
        id: wallView
        path: win.wallpaperFile
        watchChanges: true
        blockLoading: true
        onLoaded: win.wallPath = text().trim()
        onFileChanged: win.wallPath = text().trim()
        onLoadFailed: win.wallPath = ""
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    Image {
        id: wallImage
        anchors.fill: parent
        source: win.wallPath !== "" ? "file://" + win.wallPath : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: true
        smooth: true
        visible: false
        layer.enabled: true
    }

    ShaderEffectSource {
        id: wallSource
        sourceItem: wallImage
        live: true
        hideSource: false
        textureSize: Qt.size(win.width, win.height)
    }

    ShaderEffect {
        anchors.fill: parent
        visible: win.enabled && win.wallPath !== "" && wallImage.status === Image.Ready
        fragmentShader: "file://" + win.shaderPath

        property vector2d size: Qt.vector2d(width, height)
        property vector2d origin: Qt.vector2d(width / 2, height / 2)
        property vector2d cropA: {
            if (wallImage.implicitWidth === 0) return Qt.vector2d(1, 1)
            var imgAspect = wallImage.implicitWidth / wallImage.implicitHeight
            var scrAspect = width / Math.max(1, height)
            if (imgAspect > scrAspect) return Qt.vector2d(scrAspect / imgAspect, 1)
            return Qt.vector2d(1, imgAspect / scrAspect)
        }
        property vector2d cropB: cropA
        property vector4d lo: Qt.vector4d(Theme.bg.r, Theme.bg.g, Theme.bg.b, 1.0)
        property vector4d hi: Qt.vector4d(Theme.accent.r, Theme.accent.g, Theme.accent.b, 1.0)
        property vector4d bg: Qt.vector4d(Theme.bg.r, Theme.bg.g, Theme.bg.b, 1.0)
        property real pitch: 12
        property real dots: 1.0
        property real mono: 0.0
        property real bright: 1.0
        property real wave: 0.0
        property real hasA: 1.0
        property real hasB: 0.0
        property var srcA: wallSource
        property var srcB: wallSource
    }
}
