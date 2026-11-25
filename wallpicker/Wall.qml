import QtQuick

import "../themes"

// Preview: picture as a dot matrix (look 0), gray photo (1), color photo (2) or color dots (3), see shaders/wall.frag.
// Two images: the one on screen and the incoming one. When the new one is loaded a wave runs from `origin`,
// then they swap roles and the old one is unloaded. Empty path = transparent.
Item {
    id: root

    property string path
    property int look: 0
    property real pitch: 10
    property real bright: 0.85
    property point origin: Qt.point(width / 2, height / 2)
    property bool animate: true
    readonly property bool opaque: fx.hasA > 0 && !run.running
    readonly property bool light: Theme.bg.hslLightness > Theme.fg.hslLightness

    property bool flip: false
    readonly property Image cur: flip ? ib : ia
    readonly property Image next: flip ? ia : ib

    function urlOf(p) { return p ? "file://" + String(p).split("/").map(encodeURIComponent).join("/") : "" }

    function crop(img) {
        const iar = img.implicitWidth / Math.max(1, img.implicitHeight), sa = width / Math.max(1, height);
        return iar > sa ? Qt.size(sa / iar, 1) : Qt.size(1, iar / sa);
    }

    property string shown: ""
    property string coming: ""
    property bool pending: false
    readonly property bool sized: width > 0 && height > 0

    onSizedChanged: change()
    onPathChanged: change()
    function change() {
        if (!sized) return;
        if (run.running) { // flipped faster than the wave: finish the current one right away
            run.stop();
            swap();
        }
        if (path === shown) {
            pending = false;
            next.source = "";
            return;
        }
        coming = path;
        pending = true;
        next.source = urlOf(path);
        check();
    }
    function check() {
        if (!pending || next.status === Image.Loading) return;
        pending = false;
        if (animate) run.restart();
        else swap();
    }
    function swap() {
        flip = !flip;
        shown = coming;
        fx.wave = 0;
        next.source = "";
    }

    NumberAnimation { id: run; target: fx; property: "wave"; from: 0; to: 1; duration: 1500; easing.type: Easing.InOutSine; onFinished: root.swap() }

    // texture sources are siblings of the effect, not children (an invisible Image is not updated by the scene)
    Image { id: ia; opacity: 0; asynchronous: true; cache: false; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(root.width, root.height); onStatusChanged: if (root.next === ia) root.check() }
    Image { id: ib; opacity: 0; asynchronous: true; cache: false; fillMode: Image.PreserveAspectCrop; sourceSize: ia.sourceSize; onStatusChanged: if (root.next === ib) root.check() }

    ShaderEffect {
        id: fx
        anchors.fill: parent
        visible: hasA > 0 || hasB > 0 || run.running

        readonly property size size: Qt.size(width, height)
        readonly property point origin: root.origin
        readonly property var srcA: root.cur
        readonly property var srcB: root.next
        readonly property size cropA: root.crop(root.cur)
        readonly property size cropB: root.crop(root.next)
        readonly property real hasA: root.cur.status === Image.Ready ? 1 : 0
        readonly property real hasB: root.next.status === Image.Ready ? 1 : 0
        readonly property color lo: root.light ? Theme.fg : Theme.bg
        readonly property color hi: root.light ? Theme.bg : Theme.fg
        readonly property color bg: Theme.bg
        readonly property real pitch: root.pitch
        readonly property real bright: root.bright
        property real dots: root.look === 0 || root.look === 3 ? 1 : 0
        property real mono: root.look < 2 ? 1 : 0
        property real wave: 0
        Behavior on dots { NumberAnimation { duration: 700; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] } }
        Behavior on mono { NumberAnimation { duration: 700 } }

        fragmentShader: Qt.resolvedUrl("shaders/wall.frag.qsb")
    }
}
