import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../themes"

PanelWindow {
    id: win
    property bool opened: false
    signal closeRequested()

    readonly property string stateFile: Quickshell.env("HOME") + "/.cache/tzeuk/shader"

    readonly property string fDot: Theme.fontDoto
    readonly property string fMono: Theme.fontMono
    readonly property color cBg: Theme.bg
    readonly property color cFg: Theme.fg
    readonly property color cAccent: Theme.accent
    readonly property color cDim: Theme.line
    readonly property color cSurf: Theme.surfaceHi
    readonly property color cText: Theme.nText

    property var shaders: []
    property string current: ""
    property int idx: 0
    property string searchText: ""

    readonly property var filteredModel: {
        var res = [{ name: "none", type: "none", path: "", isNone: true }]
        var searchLower = win.searchText.toLowerCase()
        for (var i = 0; i < win.shaders.length; i++) {
            if (win.shaders[i].name.toLowerCase().indexOf(searchLower) !== -1) {
                res.push(Object.assign({ isNone: false }, win.shaders[i]))
            }
        }
        return res
    }

    function currentIdx() {
        if (win.current === "" || win.current === "none") return 0
        for (var i = 0; i < win.filteredModel.length; i++) {
            if (win.filteredModel[i].name === win.current) return i
        }
        return 0
    }

    function shaderDescription(name) {
        var desc = {
            "none": "Disable all shaders",
            "dots": "Screen-wide dot matrix via Hyprland",
            "wall": "Wallpaper LED dots via Quickshell",
            "01_sepia": "Warm sepia tone filter",
            "02_grayscale": "Black and white rendering",
            "03_vibrance": "Enhanced color saturation",
            "04_optics_compensate": "Optical distortion correction",
            "05_sketch": "Pencil sketch effect",
            "06_chromatic_aberration": "Lens color fringing",
            "07_newspaper": "Newspaper print dithering",
            "08_posterization": "Retro poster colors",
            "09_anaglyph_3d": "3D anaglyph effect"
        }
        return desc[name] || "Custom shader"
    }

    Process {
        id: scanProc
        command: ["bash", "-c",
            "echo \"dots|hyprland|$HOME/.config/quickshell/tzeuk/shaders/hyprland/screen-dots.frag\"; " +
            "echo \"wall|quickshell|$HOME/.config/quickshell/tzeuk/shaders/wall.frag.qsb\"; " +
            "[ -f \"$HOME/.config/hypr/shaders/01_sepia.glsl\" ] && echo \"01_sepia|hyprland|$HOME/.config/hypr/shaders/01_sepia.glsl\"; " +
            "[ -f \"$HOME/.config/hypr/shaders/02_grayscale.glsl\" ] && echo \"02_grayscale|hyprland|$HOME/.config/hypr/shaders/02_grayscale.glsl\"; " +
            "[ -f \"$HOME/.config/hypr/shaders/03_vibrance.glsl\" ] && echo \"03_vibrance|hyprland|$HOME/.config/hypr/shaders/03_vibrance.glsl\"; " +
            "[ -f \"$HOME/.config/hypr/shaders/04_optics_compensate.glsl\" ] && echo \"04_optics_compensate|hyprland|$HOME/.config/hypr/shaders/04_optics_compensate.glsl\"; " +
            "[ -f \"$HOME/.config/hypr/shaders/05_sketch.glsl\" ] && echo \"05_sketch|hyprland|$HOME/.config/hypr/shaders/05_sketch.glsl\"; " +
            "[ -f \"$HOME/.config/hypr/shaders/06_chromatic_aberration.glsl\" ] && echo \"06_chromatic_aberration|hyprland|$HOME/.config/hypr/shaders/06_chromatic_aberration.glsl\"; " +
            "[ -f \"$HOME/.config/hypr/shaders/07_newspaper.glsl\" ] && echo \"07_newspaper|hyprland|$HOME/.config/hypr/shaders/07_newspaper.glsl\"; " +
            "[ -f \"$HOME/.config/hypr/shaders/08_posterization.glsl\" ] && echo \"08_posterization|hyprland|$HOME/.config/hypr/shaders/08_posterization.glsl\"; " +
            "[ -f \"$HOME/.config/hypr/shaders/09_anaglyph_3d.glsl\" ] && echo \"09_anaglyph_3d|hyprland|$HOME/.config/hypr/shaders/09_anaglyph_3d.glsl\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n").filter(l => l.length > 0)
                var out = []
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].split("|")
                    if (p.length < 3) continue
                    out.push({
                        name: p[0],
                        type: p[1],
                        path: p[2]
                    })
                }
                win.shaders = out
                win.idx = win.currentIdx()
            }
        }
    }

    FileView {
        id: stateView
        path: win.stateFile
        blockLoading: true
        onLoaded: win.current = text().trim()
        onLoadFailed: win.current = ""
    }

    function apply(shaderName) {
        var nameToWrite = (shaderName === "none" || shaderName === "") ? "" : shaderName
        win.current = nameToWrite
        stateView.setText(nameToWrite)
        Quickshell.execDetached(["bash", "-c", "sleep 0.1 && hyprctl reload"])
    }

    onOpenedChanged: {
        if (opened) {
            win.current = stateView.text().trim()
            win.searchText = ""
            scanProc.running = true
        }
    }

    Shortcut { sequence: "Escape"; enabled: win.opened; onActivated: win.closeRequested() }
    Shortcut { sequence: "Up"; enabled: win.opened; onActivated: if (win.idx > 0) win.idx-- }
    Shortcut { sequence: "Down"; enabled: win.opened; onActivated: if (win.idx < win.filteredModel.length - 1) win.idx++ }
    Shortcut {
        sequence: "Return"; enabled: win.opened
        onActivated: {
            if (win.idx >= 0 && win.idx < win.filteredModel.length) {
                win.apply(win.filteredModel[win.idx].name)
            }
            win.closeRequested()
        }
    }

    visible: opened
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tzeuk-shader"
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        id: sharedSource
        visible: false
        width: 240
        height: 240
        gradient: Gradient {
            GradientStop { position: 0.0; color: win.cAccent }
            GradientStop { position: 0.55; color: Qt.rgba(win.cFg.r, win.cFg.g, win.cFg.b, 0.65) }
            GradientStop { position: 1.0; color: win.cBg }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.85)
        MouseArea { anchors.fill: parent; onClicked: win.closeRequested() }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 520
        height: 680
        radius: 24
        color: cBg
        border.width: 1
        border.color: cDim

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 20

            // Header
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Shaders"
                color: cFg
                font.family: fDot
                font.weight: Font.Black
                font.pixelSize: 28
                font.letterSpacing: 2
            }

            // Search
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 12
                color: cSurf

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Text {
                        text: "⌕"
                        color: cText
                        font.pixelSize: 16
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: "Search..."
                        text: win.searchText
                        onTextChanged: win.searchText = text

                        font.family: fMono
                        font.pixelSize: 12
                        color: cFg

                        background: Rectangle { color: "transparent" }
                    }
                }
            }

            // Shader List
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: cSurf

                ListView {
                    id: shaderList
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    model: win.filteredModel
                    currentIndex: win.idx
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds

                    Connections {
                        target: win
                        function onIdxChanged() {
                            Qt.callLater(() => shaderList.positionViewAtIndex(win.idx, ListView.Contain))
                        }
                    }

                    delegate: Rectangle {
                        required property int index
                        required property var modelData
                        width: shaderList.width
                        height: 52
                        radius: 10
                        color: win.idx === index ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.12) : "transparent"

                        readonly property bool active: modelData.isNone ? win.current === "" : (win.current === modelData.name)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 12

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: active ? cAccent : "transparent"
                                border.width: active ? 0 : 1
                                border.color: cText
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.isNone ? "None" : modelData.name
                                    color: active ? cAccent : cFg
                                    font.family: fMono
                                    font.pixelSize: 13
                                    font.weight: active ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: win.shaderDescription(modelData.name)
                                    color: cText
                                    font.family: fMono
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                visible: active
                                text: "✓"
                                color: cAccent
                                font.pixelSize: 16
                                font.weight: Font.Bold
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                win.idx = index
                                win.apply(modelData.name)
                            }
                            onEntered: win.idx = index
                        }
                    }
                }
            }

            // Footer
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 20

                Text {
                    text: "↑↓ • ⏎ • Esc"
                    color: cText
                    font.family: fMono
                    font.pixelSize: 10
                    font.letterSpacing: 1
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: (win.idx + 1) + "/" + win.filteredModel.length
                    color: cAccent
                    font.family: fDot
                    font.weight: Font.Black
                    font.pixelSize: 13
                }
            }
        }
    }
}
