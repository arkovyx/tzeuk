import QtQuick

import "../themes"
import "../glyphs"

// dot-ring dial: drag around the ring, click, or use the mouse wheel
Item {
    id: root

    property real size: 120
    property string label
    property real from: 0
    property real to: 100
    property real step: 1
    property real value: 0
    signal moved(real v)

    readonly property string fDot: Theme.fontDoto !== "" ? Theme.fontDoto : "monospace"
    readonly property string fMono: Theme.fontMono !== "" ? Theme.fontMono : "monospace"
    readonly property real frac: (value - from) / (to - from)

    width: size
    height: size + 30

    function clamp(v) { return Math.max(from, Math.min(to, v)) }
    function setFrom(x, y) {
        const dx = x - size / 2, dy = y - size / 2;
        let a = Math.atan2(dx, -dy);
        if (a < 0) a += 2 * Math.PI;
        let f = a / (2 * Math.PI);
        if (frac < 0.25 && f > 0.75) f = 0;      // do not jump over the top
        else if (frac > 0.75 && f < 0.25) f = 1;
        const v = clamp(from + Math.round(f * (to - from) / step) * step);
        if (v !== value) moved(v);
    }

    DotRing { width: root.size; height: root.size; n: 36; dot: 4; f: root.frac }
    Text {
        x: 0; y: 0; width: root.size; height: root.size
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: Math.round(root.value)
        color: Theme.fg
        font { family: root.fDot; pixelSize: 30; weight: Font.Black; variableAxes: ({ "ROND": 100, "wght": 900 }) }
    }
    Text {
        y: root.size + 12
        width: root.size
        horizontalAlignment: Text.AlignHCenter
        text: root.label
        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.5)
        font { family: root.fMono; pixelSize: 10; letterSpacing: 10 * 0.14; capitalization: Font.AllUppercase }
    }
    MouseArea {
        x: 0; y: 0; width: root.size; height: root.size
        cursorShape: Qt.PointingHandCursor
        onPressed: m => root.setFrom(m.x, m.y)
        onPositionChanged: m => { if (pressed) root.setFrom(m.x, m.y) }
        onWheel: w => {
            const v = root.clamp(root.value + (w.angleDelta.y > 0 ? root.step : -root.step));
            if (v !== root.value) root.moved(v);
            w.accepted = true;
        }
    }
}
