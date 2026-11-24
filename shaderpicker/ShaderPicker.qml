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
            "none": "Disable all shaders. Restore default rendering.",
            "dots": "Screen-wide dot matrix effect applied via Hyprland compositor.",
            "wall": "Wallpaper rendered as LED dot matrix via Quickshell background layer.",
            "01_sepia": "Applies warm sepia tone filter to entire screen.",
            "02_grayscale": "Converts screen to black and white.",
            "03_vibrance": "Intelligently enhances color saturation.",
            "04_optics_compensate": "Corrects optical distortions.",
            "05_sketch": "Pencil sketch edge-detection effect.",
            "06_chromatic_aberration": "Simulates lens color fringing.",
            "07_newspaper": "Old newspaper print dithering effect.",
            "08_posterization": "Reduces color levels for retro poster look.",
            "09_anaglyph_3d": "3D anaglyph red/cyan effect."
        }
        return desc[name] || "Custom shader effect."
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
        Quickshell.execDetached(["hyprctl", "reload"])
    }

    onOpenedChanged: {
        if (opened) {
            win.current = stateView.text().trim()
            win.searchText = ""
            scanProc.running = true
        }
    }

    Shortcut { sequence: "Escape"; enabled: win.opened; onActivated: win.closeRequested() }
    Shortcut { sequence: "Left"; enabled: win.opened; onActivated: if (win.idx > 0) win.idx-- }
    Shortcut { sequence: "Right"; enabled: win.opened; onActivated: if (win.idx < win.filteredModel.length - 1) win.idx++ }
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
        color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.92)
        MouseArea { anchors.fill: parent; onClicked: win.closeRequested() }
    }

    Rectangle {
        id: mainCard
        anchors.centerIn: parent
        width: 1000
        height: 720
        radius: 16
        color: cBg
        border.width: 1
        border.color: cDim

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 20

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 48

                Text {
                    text: "SHADER PICKER"
                    color: cFg
                    font.family: fDot
                    font.weight: Font.Black
                    font.pixelSize: 28
                    font.letterSpacing: 4
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: win.filteredModel.length + " EFFECTS"
                    color: cText
                    font.family: fMono
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }
            }

            // Search Bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 8
                color: cSurf
                border.width: 1
                border.color: searchField.activeFocus ? cAccent : cDim

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Text {
                        text: "⌕"
                        color: cText
                        font.pixelSize: 18
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: "Search shaders..."
                        text: win.searchText
                        onTextChanged: win.searchText = text

                        font.family: fMono
                        font.pixelSize: 13
                        color: cFg
                        selectionColor: cAccent

                        background: Rectangle { color: "transparent" }
                    }
                }
            }

            // Main Content
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 24

                // Shader List
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 320
                    radius: 12
                    color: cSurf
                    border.width: 1
                    border.color: cDim

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
                            height: 56
                            radius: 8
                            color: win.idx === index ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.15) : "transparent"
                            border.width: win.idx === index ? 1 : 0
                            border.color: cAccent

                            readonly property bool active: modelData.isNone ? win.current === "" : (win.current === modelData.name)

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Text {
                                    text: modelData.isNone ? "○" : "●"
                                    color: active ? cAccent : cText
                                    font.pixelSize: 14
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
                                        font.weight: active ? Font.Bold : Font.Normal
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.type === "hyprland" ? "Hyprland" : (modelData.type === "quickshell" ? "Quickshell" : "")
                                        color: cText
                                        font.family: fMono
                                        font.pixelSize: 10
                                        font.letterSpacing: 1
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

                // Preview & Info
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 16

                    // Preview
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 380
                        radius: 12
                        color: Qt.rgba(cFg.r, cFg.g, cFg.b, 0.03)
                        border.width: 1
                        border.color: cDim
                        clip: true

                        Canvas {
                            anchors.fill: parent
                            visible: win.idx === 0
                            property color dc: cFg
                            onDcChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                ctx.strokeStyle = Qt.rgba(dc.r, dc.g, dc.b, 0.15)
                                ctx.lineWidth = 1
                                ctx.beginPath()
                                ctx.moveTo(0, 0); ctx.lineTo(width, height)
                                ctx.moveTo(width, 0); ctx.lineTo(0, height)
                                ctx.stroke()
                            }
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                        }

                        ShaderEffect {
                            anchors.fill: parent
                            visible: win.idx > 0 && win.filteredModel[win.idx].type === "quickshell"
                            fragmentShader: "file://" + win.filteredModel[win.idx].path

                            property vector2d size: Qt.vector2d(width, height)
                            property real pitch: 7
                            property var source: sharedSource
                            property vector2d origin: Qt.vector2d(width / 2, height / 2)
                            property vector2d cropA: Qt.vector2d(1, 1)
                            property vector2d cropB: Qt.vector2d(1, 1)
                            property vector4d lo: Qt.vector4d(cBg.r, cBg.g, cBg.b, 1.0)
                            property vector4d hi: Qt.vector4d(cAccent.r, cAccent.g, cAccent.b, 1.0)
                            property vector4d bg: Qt.vector4d(cBg.r, cBg.g, cBg.b, 1.0)
                            property real dots: 1.0
                            property real mono: 1.0
                            property real bright: 1.0
                            property real wave: 0.0
                            property real hasA: 1.0
                            property real hasB: 0.0
                            property var srcA: sharedSource
                            property var srcB: sharedSource
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: win.idx > 0 && win.filteredModel[win.idx].type === "hyprland"
                            text: "HYPRLAND\nCOMPOSITOR\nSHADER"
                            color: cText
                            font.family: fMono
                            font.pixelSize: 14
                            font.letterSpacing: 2
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: win.idx === 0
                            text: "NONE"
                            color: cText
                            font.family: fDot
                            font.weight: Font.Black
                            font.pixelSize: 24
                            font.letterSpacing: 4
                        }
                    }

                    // Info Panel
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 12
                        color: cSurf
                        border.width: 1
                        border.color: cDim

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12

                            Text {
                                Layout.fillWidth: true
                                text: win.idx === 0 ? "DISABLED" : win.filteredModel[win.idx].name.toUpperCase()
                                color: cAccent
                                font.family: fDot
                                font.weight: Font.Black
                                font.pixelSize: 20
                                font.letterSpacing: 3
                            }

                            Text {
                                Layout.fillWidth: true
                                text: win.shaderDescription(win.idx === 0 ? "none" : win.filteredModel[win.idx].name)
                                color: cFg
                                font.family: fMono
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                                lineHeight: 1.4
                            }

                            Item { Layout.fillHeight: true }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: cDim
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Consumer:"
                                    color: cText
                                    font.family: fMono
                                    font.pixelSize: 10
                                    font.letterSpacing: 1
                                }

                                Text {
                                    text: win.idx === 0 ? "None" : (win.filteredModel[win.idx].type === "hyprland" ? "Hyprland Compositor" : "Quickshell")
                                    color: cFg
                                    font.family: fMono
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                }
                            }
                        }
                    }
                }
            }

            // Footer
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 20

                Text {
                    text: "◀ ▶ Navigate   ⏎ Apply   Esc Close"
                    color: cText
                    font.family: fMono
                    font.pixelSize: 10
                    font.letterSpacing: 1
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: (win.idx + 1) + " / " + win.filteredModel.length
                    color: cAccent
                    font.family: fDot
                    font.weight: Font.Black
                    font.pixelSize: 14
                }
            }
        }
    }
}
