import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../themes"

Item {
    id: root
    readonly property var tools: ["pen", "arrow", "rect", "blur", "text"]
    readonly property var hotkeys: [Qt.Key_P, Qt.Key_A, Qt.Key_R, Qt.Key_B, Qt.Key_T]
    readonly property var inks: ["#ff3333", "#FFFFFF", "#000000", "#8C8C8C"]
    readonly property var sizes: [3, 6, 12]

    property string shot: ""
    property var scr: null
    property int tool: 0
    property int ink: 0
    property int size: 1
    property var marks: []
    property var live: null
    readonly property real dpr: scr?.devicePixelRatio ?? 1
    readonly property real w: sizes[size] * dpr

    function fade(color, opacity) { return Qt.rgba(color.r, color.g, color.b, opacity) }

    function open(path, screen) {
        shot = path; scr = screen; marks = []; live = null; typing.visible = false; win.shown = true; st.forceActiveFocus()
    }
    function close() { win.shown = false }

    function commitWord() {
        if (!typing.visible) return
        if (typing.text.trim()) marks = marks.concat([{ k: "text", c: inks[ink], s: typing.font.pixelSize, x: typing.x, y: typing.y, t: typing.text }])
        typing.visible = false; st.forceActiveFocus()
    }

    function save() {
        commitWord()
        canvas.grabToImage(r => {
            if (!r.saveToFile(root.shot)) return
            Quickshell.execDetached(["sh", "-c", 'wl-copy -t image/png < "$1"', "sh", root.shot])
            root.close()
        }, Qt.size(img.implicitWidth, img.implicitHeight))
    }

    PanelWindow {
        id: win
        property bool shown: false
        property real t: shown ? 1 : 0
        Behavior on t { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        screen: root.scr; visible: t > 0
        anchors { left: true; right: true; top: true; bottom: true }
        color: "transparent"; exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "tzeuk-shot"

        Rectangle { anchors.fill: parent; color: fade(Theme.bg, 0.96); opacity: win.t }

        FocusScope {
            id: st
            focus: true
            Keys.onPressed: e => {
                const t = root.hotkeys.indexOf(e.key)
                if (e.key === Qt.Key_Escape) root.close()
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || (e.key === Qt.Key_S && e.modifiers & Qt.ControlModifier)) root.save()
                else if (e.key === Qt.Key_Z && e.modifiers & Qt.ControlModifier) root.marks = root.marks.slice(0, -1)
                else if (t >= 0) root.tool = t
                else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_4) root.ink = e.key - Qt.Key_1
                else if (e.key === Qt.Key_BracketLeft) root.size = Math.max(0, root.size - 1)
                else if (e.key === Qt.Key_BracketRight) root.size = Math.min(2, root.size + 1)
                else return
                e.accepted = true
            }

            Item {
                id: frame
                readonly property real fit: Math.min(1, (st.width - 240) / Math.max(1, img.implicitWidth), (st.height - 140 - 220) / Math.max(1, img.implicitHeight))
                width: img.implicitWidth * fit; height: img.implicitHeight * fit
                x: (st.width - width) / 2; y: 140 + (st.height - 140 - 220 - height) / 2
                opacity: win.t; scale: 0.96 + 0.04 * win.t

                Item {
                    id: canvas; width: img.implicitWidth; height: img.implicitHeight; scale: frame.fit; transformOrigin: Item.TopLeft
                    Image { id: img; source: root.shot ? "file://" + root.shot : ""; cache: false; smooth: true; mipmap: true }

                    Repeater {
                        model: root.marks
                        delegate: Item {
                            required property var modelData
                            property var m: modelData
                            readonly property real x0: Math.min(m.x1, m.x2); readonly property real y0: Math.min(m.y1, m.y2)
                            readonly property real w0: Math.abs(m.x2 - m.x1); readonly property real h0: Math.abs(m.y2 - m.y1)

                            Loader {
                                sourceComponent: {
                                    if (m.k === "pen") return pen
                                    if (m.k === "arrow") return arrow
                                    if (m.k === "rect") return rectC
                                    if (m.k === "blur") return blur
                                    if (m.k === "text") return word
                                    return null
                                }
                            }

                            Component { id: pen; Shape { preferredRendererType: Shape.CurveRenderer; ShapePath { strokeColor: m.c; strokeWidth: m.w; fillColor: "transparent"; capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin; PathPolyline { path: m.pts } } } }
                            Component { id: arrow; Shape { id: ar; readonly property real a: Math.atan2(m.y2 - m.y1, m.x2 - m.x1); readonly property real hl: m.w * 4; readonly property point base: Qt.point(m.x2 - Math.cos(a) * hl * 0.8, m.y2 - Math.sin(a) * hl * 0.8); preferredRendererType: Shape.CurveRenderer; ShapePath { strokeColor: m.c; strokeWidth: m.w; fillColor: "transparent"; capStyle: ShapePath.RoundCap; PathPolyline { path: [Qt.point(m.x1, m.y1), ar.base] } }; ShapePath { strokeColor: "transparent"; fillColor: m.c; PathPolyline { path: [Qt.point(m.x2, m.y2), Qt.point(m.x2 - Math.cos(ar.a - 0.45) * ar.hl, m.y2 - Math.sin(ar.a - 0.45) * ar.hl), Qt.point(m.x2 - Math.cos(ar.a + 0.45) * ar.hl, m.y2 - Math.sin(ar.a + 0.45) * ar.hl), Qt.point(m.x2, m.y2)] } } } }
                            Component { id: rectC; Rectangle { x: x0 - m.w / 2; y: y0 - m.w / 2; width: w0 + m.w; height: h0 + m.w; color: "transparent"; border { width: m.w; color: m.c } } }
                            Component { id: blur; ShaderEffectSource { readonly property real px: m.w * 3; x: x0; y: y0; width: w0; height: h0; sourceItem: img; sourceRect: Qt.rect(x0, y0, w0, h0); textureSize: Qt.size(Math.max(1, Math.ceil(w0 / px)), Math.max(1, Math.ceil(h0 / px))); smooth: false } }
                            Component { id: word; Text { x: m.x; y: m.y; text: m.t; font { family: Theme.fontMono; pixelSize: m.s; weight: Font.DemiBold }; color: m.c; style: Text.Outline; styleColor: m.c === "#000000" ? "#FFFFFF" : "#000000" } }
                        }
                    }

                    Repeater {
                        model: root.live ? [root.live] : []
                        delegate: Item {
                            required property var modelData
                            property var m: modelData
                            readonly property real x0: Math.min(m.x1, m.x2); readonly property real y0: Math.min(m.y1, m.y2)
                            readonly property real w0: Math.abs(m.x2 - m.x1); readonly property real h0: Math.abs(m.y2 - m.y1)

                            Loader {
                                sourceComponent: {
                                    if (m.k === "pen") return pen
                                    if (m.k === "arrow") return arrow
                                    if (m.k === "rect") return rectC
                                    if (m.k === "blur") return blur
                                    if (m.k === "text") return word
                                    return null
                                }
                            }
                            Component { id: pen; Shape { preferredRendererType: Shape.CurveRenderer; ShapePath { strokeColor: m.c; strokeWidth: m.w; fillColor: "transparent"; capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin; PathPolyline { path: m.pts } } } }
                            Component { id: arrow; Shape { id: ar; readonly property real a: Math.atan2(m.y2 - m.y1, m.x2 - m.x1); readonly property real hl: m.w * 4; readonly property point base: Qt.point(m.x2 - Math.cos(a) * hl * 0.8, m.y2 - Math.sin(a) * hl * 0.8); preferredRendererType: Shape.CurveRenderer; ShapePath { strokeColor: m.c; strokeWidth: m.w; fillColor: "transparent"; capStyle: ShapePath.RoundCap; PathPolyline { path: [Qt.point(m.x1, m.y1), ar.base] } }; ShapePath { strokeColor: "transparent"; fillColor: m.c; PathPolyline { path: [Qt.point(m.x2, m.y2), Qt.point(m.x2 - Math.cos(ar.a - 0.45) * ar.hl, m.y2 - Math.sin(ar.a - 0.45) * ar.hl), Qt.point(m.x2 - Math.cos(ar.a + 0.45) * ar.hl, m.y2 - Math.sin(ar.a + 0.45) * ar.hl), Qt.point(m.x2, m.y2)] } } } }
                            Component { id: rectC; Rectangle { x: x0 - m.w / 2; y: y0 - m.w / 2; width: w0 + m.w; height: h0 + m.w; color: "transparent"; border { width: m.w; color: m.c } } }
                            Component { id: blur; ShaderEffectSource { readonly property real px: m.w * 3; x: x0; y: y0; width: w0; height: h0; sourceItem: img; sourceRect: Qt.rect(x0, y0, w0, h0); textureSize: Qt.size(Math.max(1, Math.ceil(w0 / px)), Math.max(1, Math.ceil(h0 / px))); smooth: false } }
                            Component { id: word; Text { x: m.x; y: m.y; text: m.t; font { family: Theme.fontMono; pixelSize: m.s; weight: Font.DemiBold }; color: m.c; style: Text.Outline; styleColor: m.c === "#000000" ? "#FFFFFF" : "#000000" } }
                        }
                    }

                    TextInput {
                        id: typing; visible: false
                        font { family: Theme.fontMono; pixelSize: root.w * 6; weight: Font.DemiBold }
                        color: root.inks[root.ink]; selectionColor: Theme.nText
                        cursorDelegate: Rectangle { width: 2 * root.dpr; color: Theme.accent }
                        onAccepted: root.commitWord()
                        Keys.onEscapePressed: { visible = false; st.forceActiveFocus() }
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: root.tool === 4 ? Qt.IBeamCursor : Qt.CrossCursor
                        onPressed: e => {
                            root.commitWord()
                            const c = root.inks[root.ink]
                            if (root.tool === 0) root.live = { k: "pen", c, w: root.w, pts: [Qt.point(e.x, e.y)] }
                            else if (root.tool === 4) { typing.text = ""; typing.x = e.x; typing.y = e.y - typing.height / 2; typing.visible = true; typing.forceActiveFocus() }
                            else root.live = { k: root.tools[root.tool], c, w: root.w, x1: e.x, y1: e.y, x2: e.x, y2: e.y }
                        }
                        onPositionChanged: e => {
                            const l = root.live; if (!l) return
                            if (l.k === "pen") root.live = Object.assign({}, l, { pts: l.pts.concat([Qt.point(e.x, e.y)]) })
                            else root.live = Object.assign({}, l, { x2: e.x, y2: e.y })
                        }
                        onReleased: {
                            const l = root.live; root.live = null
                            if (l && (l.k === "pen" ? l.pts.length > 1 : Math.hypot(l.x2 - l.x1, l.y2 - l.y1) > 4 * root.dpr)) root.marks = root.marks.concat([l])
                        }
                    }
                }

                Rectangle { anchors.fill: parent; anchors.margins: -1; color: "transparent"; border { width: 1; color: Theme.nText } }
                Repeater {
                    model: 4
                    Rectangle {
                        required property int index
                        x: (index % 2 ? frame.width : 0) - 6; y: (index > 1 ? frame.height : 0) - 6
                        width: 12; height: 12; radius: 6; color: Theme.fg
                    }
                }
                Item {
                    y: -height - 18; width: parent.width; height: dims.height
                    Row {
                        anchors.right: parent.right; anchors.rightMargin: 2; spacing: 14
                        Text { anchors.bottom: parent.bottom; text: `${root.marks.length} marks`; font.family: Theme.fontMono; font.pixelSize: 11; color: Theme.nText }
                        Text { id: dims; text: `${img.implicitWidth}×${img.implicitHeight}`; font.family: Theme.fontDoto; font.weight: Font.Black; font.pixelSize: 14; color: Theme.fg }
                    }
                }
            }

            Column {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 44 }
                opacity: win.t; spacing: 12
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: pillRow.width + 40; height: 56; radius: 28
                    color: Theme.surfaceHi; border { width: 1; color: Theme.line }
                    Row {
                        id: pillRow; anchors.centerIn: parent; spacing: 6
                        Repeater {
                            model: root.tools
                            delegate: Rectangle {
                                required property string modelData; required property int index
                                width: txt.width + 24; height: 36; radius: 18
                                color: index === root.tool ? Theme.fg : "transparent"
                                Text {
                                    id: txt; anchors.centerIn: parent; text: modelData
                                    font.family: Theme.fontMono; font.pixelSize: 11
                                    color: index === root.tool ? Theme.bg : Theme.nText
                                }
                                TapHandler { onTapped: { root.commitWord(); root.tool = index } }
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                            }
                        }
                        Item { width: 18; height: 36; Rectangle { anchors.centerIn: parent; width: 4; height: 4; radius: 2; color: Theme.nText } }
                        Repeater {
                            model: root.inks
                            delegate: Item {
                                required property color modelData; required property int index; width: 30; height: 36
                                Rectangle { anchors.centerIn: parent; width: 26; height: 26; radius: 13; color: "transparent"; border { width: 1.5; color: index === root.ink ? Theme.fg : "transparent" } }
                                Rectangle { anchors.centerIn: parent; width: 16; height: 16; radius: 8; color: modelData; border { width: 1; color: Theme.nText } }
                                TapHandler { onTapped: root.ink = index }
                            }
                        }
                        Item { width: 18; height: 36; Rectangle { anchors.centerIn: parent; width: 4; height: 4; radius: 2; color: Theme.nText } }
                        Repeater {
                            model: root.sizes
                            delegate: Item {
                                required property int modelData; required property int index; width: 26; height: 36
                                Rectangle { anchors.centerIn: parent; width: modelData + 4; height: width; radius: width / 2; color: index === root.size ? Theme.fg : Theme.nText }
                                TapHandler { onTapped: root.size = index }
                            }
                        }
                        Item { width: 8; height: 36 }
                    }
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: hintRow.width + 44; height: 36; radius: 18
                    color: Theme.surfaceHi; border { width: 1; color: Theme.line }
                    Row {
                        id: hintRow; anchors.centerIn: parent; spacing: 28
                        Repeater {
                            model: ["p a r b t tool", "1–4 ink", "[ ] size", "ctrl+z undo", "↵ save · copy", "esc discard"]
                            delegate: Text {
                                required property string modelData; text: modelData
                                font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.nText
                            }
                        }
                    }
                }
            }
        }
    }
}
