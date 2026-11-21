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

    readonly property string fDot:  Theme.fontDoto
    readonly property string fMono: Theme.fontMono
    readonly property color cBg:     Theme.bg
    readonly property color cFg:     Theme.fg
    readonly property color cAccent: Theme.accent
    readonly property color cDim:    Theme.line
    readonly property color cSurf:   Theme.surfaceHi
    readonly property color cText:   Theme.nText

    property var shaders: []
    property string current: ""
    property int idx: 0
    property string searchText: ""

    readonly property var filteredModel: {
        var res = [{ name: "none", type: "none", compiled: true, path: "", isNone: true }]
        var searchLower = win.searchText.toLowerCase()
        for (var i = 0; i < win.shaders.length; i++) {
            if (win.shaders[i].name.toLowerCase().indexOf(searchLower) !== -1) {
                res.push(Object.assign({ isNone: false }, win.shaders[i]))
            }
        }
        return res
    }

    function pad2(n) { return String(n).padStart(2, "0") }

    function currentIdx() {
        if (win.current === "" || win.current === "none") return 0
        for (var i = 0; i < win.filteredModel.length; i++) {
            if (win.filteredModel[i].name === win.current) return i
        }
        return 0
    }

    function shaderDescription(name) {
        var desc = {
            "none": "Disable all shaders. Default rendering.",
            "dots": "Screen-wide dot matrix via Hyprland compositor.",
            "wall": "Wallpaper rendered as LED dots via Quickshell.",
            "01_sepia": "Warm sepia tone filter.",
            "02_grayscale": "Black and white rendering.",
            "03_vibrance": "Intelligent color saturation.",
            "04_optics_compensate": "Optical distortion correction.",
            "05_sketch": "Pencil sketch edge-detection effect.",
            "06_chromatic_aberration": "Lens color fringing simulation.",
            "07_newspaper": "Old newspaper print dithering.",
            "08_posterization": "Retro poster-like color reduction.",
            "09_anaglyph_3d": "3D anaglyph (red/cyan) effect."
        }
        return desc[name] || "Custom shader effect."
    }

    Process {
        id: scanProc
        command: ["bash", "-c",
            "out=''; " +
            "add_shader() { local name=$1 type=$2 compiled=$3 path=$4; if [ -f \"$path\" ]; then out=\"${out}${name}|${type}|${compiled}|${path}\\n\"; fi }; " +
            "add_shader \"dots\" \"qsb_frag\" \"yes\" \"$HOME/.config/quickshell/tzeuk/shaders/hyprland/screen-dots.frag\"; " +
            "add_shader \"wall\" \"qsb\" \"yes\" \"$HOME/.config/quickshell/tzeuk/shaders/wall.frag.qsb\"; " +
            "for f in \"$HOME\"/.config/hypr/shaders/*.glsl; do [ -f \"$f\" ] || continue; name=$(basename \"$f\" .glsl); add_shader \"$name\" \"glsl\" \"yes\" \"$f\"; done; " +
            "printf \"%s\" \"$out\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n").filter(l => l.length > 0)
                var out = []
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].split("|")
                    if (p.length < 4) continue
                    out.push({
                        name: p[0],
                        type: p[1],
                        compiled: p[2] === "yes",
                        path: p[3]
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
    Shortcut { sequence: "Left";  enabled: win.opened; onActivated: if (win.idx > 0) win.idx-- }
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
        color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.85)
        MouseArea { anchors.fill: parent; onClicked: win.closeRequested() }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 960
        height: 680
        radius: 24
        color: cBg
        border.width: 1
        border.color: cDim

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 26
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 46

                Text {
                    text: "SHADER"
                    color: cFg
                    font.family: fDot
                    font.weight: Font.Black
                    font.pixelSize: 42
                    font.letterSpacing: 3
                }
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 16
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 2
                    color: cAccent
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: win.pad2(win.filteredModel.length) + " · EFFECTS"
                    color: cText
                    font.family: fMono
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }
            }

            TextField {
                id: searchField
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                placeholderText: "Search shaders..."
                text: win.searchText
                onTextChanged: win.searchText = text

                font.family: fMono
                font.pixelSize: 12
                color: cFg
                selectionColor: cAccent

                background: Rectangle {
                    radius: 8
                    color: cSurf
                    border.width: 1
                    border.color: searchField.activeFocus ? cAccent : cDim
                }
            }

            Canvas {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                property color dc: cFg
                onDcChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.fillStyle = Qt.rgba(dc.r, dc.g, dc.b, 0.45)
                    for (var x = 2; x < width; x += 6) {
                        ctx.beginPath()
                        ctx.arc(x, 2, 1, 0, Math.PI * 2)
                        ctx.fill()
                    }
                }
                onWidthChanged: requestPaint()
            }

            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: width / 3
                cellHeight: 210
                clip: true
                model: win.filteredModel
                currentIndex: win.idx
                boundsBehavior: Flickable.StopAtBounds

                Connections {
                    target: win
                    function onIdxChanged() {
                        Qt.callLater(() => grid.positionViewAtIndex(win.idx, GridView.Contain))
                    }
                }

                delegate: Item {
                    required property int index
                    required property var modelData
                    readonly property bool isNone: modelData.isNone
                    readonly property bool active: isNone ? win.current === "" : (win.current === modelData.name)
                    readonly property bool focused: win.idx === index
                    readonly property var sh: isNone ? null : modelData

                    width: grid.cellWidth - 14
                    height: grid.cellHeight - 14

                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: focused ? cSurf : "transparent"
                        border.width: active ? 2 : 1
                        border.color: active ? cAccent : (focused ? cFg : cDim)
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 10
                                color: Qt.rgba(cFg.r, cFg.g, cFg.b, 0.03)
                                clip: true

                                Canvas {
                                    anchors.fill: parent
                                    visible: isNone
                                    property color dc: cFg
                                    onDcChanged: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.reset()
                                        ctx.strokeStyle = Qt.rgba(dc.r, dc.g, dc.b, 0.22)
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
                                    visible: !isNone && sh !== null && sh.type === "qsb" && sh.compiled
                                    fragmentShader: "file://" + sh.path

                                    property vector2d size: Qt.vector2d(width, height)
                                    property real pitch: 7
                                    property real circ: 0
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
                                    visible: !isNone && sh !== null && sh.type === "glsl"
                                    text: "HYPRLAND\nNATIVE"
                                    color: cText
                                    font.family: fMono
                                    font.pixelSize: 12
                                    font.letterSpacing: 1
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: isNone
                                    text: "NONE"
                                    color: cText
                                    font.family: fDot
                                    font.weight: Font.Black
                                    font.pixelSize: 16
                                    font.letterSpacing: 2
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 14
                                Text {
                                    Layout.fillWidth: true
                                    text: isNone ? "disable" : (sh ? sh.name : "—")
                                    color: cFg
                                    font.family: fMono
                                    font.pixelSize: 11
                                    font.letterSpacing: 1
                                    elide: Text.ElideRight
                                }
                                Text {
                                    visible: active
                                    text: "●"
                                    color: cAccent
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: win.idx = index
                        onClicked: {
                            win.idx = index
                            win.apply(modelData.name)
                        }
                    }
                }
            }

            Canvas {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                property color dc: cFg
                onDcChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.fillStyle = Qt.rgba(dc.r, dc.g, dc.b, 0.45)
                    for (var x = 2; x < width; x += 6) {
                        ctx.beginPath()
                        ctx.arc(x, 2, 1, 0, Math.PI * 2)
                        ctx.fill()
                    }
                }
                onWidthChanged: requestPaint()
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 110
                radius: 12
                color: cSurf
                border.width: 1
                border.color: cDim

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "▶ " + (win.idx === 0 ? "NONE" : (win.filteredModel[win.idx] ? win.filteredModel[win.idx].name.toUpperCase() : "—"))
                            color: cAccent
                            font.family: fDot
                            font.weight: Font.Black
                            font.pixelSize: 18
                            font.letterSpacing: 2
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            visible: win.idx > 0
                            text: {
                                var sh = win.filteredModel[win.idx]
                                if (!sh) return ""
                                return sh.type === "glsl" ? "HYPRLAND NATIVE" : (sh.compiled ? "COMPILED · QT SHADEREFFECT" : "NOT COMPILED")
                            }
                            color: {
                                var sh = win.filteredModel[win.idx]
                                if (!sh) return cText
                                return (sh.type === "glsl" || sh.compiled) ? cText : cAccent
                            }
                            font.family: fMono
                            font.pixelSize: 9
                            font.letterSpacing: 2
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (win.idx === 0)
                                return "Disable shader. Default rendering."
                            var sh = win.filteredModel[win.idx]
                            return win.shaderDescription(sh ? sh.name : "")
                        }
                        color: cFg
                        font.family: fMono
                        font.pixelSize: 11
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: {
                            if (win.idx === 0) return ""
                            var sh = win.filteredModel[win.idx]
                            var consumer = sh.type === "glsl" || sh.name === "dots" ? "Hyprland compositor" : "Quickshell"
                            return "→ Consumed by: " + consumer + "  ·  state: ~/.cache/tzeuk/shader"
                        }
                        color: cText
                        font.family: fMono
                        font.pixelSize: 9
                        font.letterSpacing: 1
                        elide: Text.ElideRight
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 16

                Text {
                    text: "◀ ▶ NAV   ⏎ APPLY   ESC CLOSE"
                    color: cText
                    font.family: fMono
                    font.pixelSize: 9
                    font.letterSpacing: 1.5
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: win.pad2(win.idx + 1) + "/" + win.pad2(win.filteredModel.length)
                    color: cAccent
                    font.family: fDot
                    font.weight: Font.Black
                    font.pixelSize: 14
                }
            }
        }
    }
}
