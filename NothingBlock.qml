import QtQuick
import QtQuick.Shapes
import "Shapes.js" as Shapes

Item {
    id: block
    property string text: ""
    property string icon: ""
    property bool active: false

    // pywal-driven (still overridable per block)
    property color nRed: Wal.color1
    property color nWhite: Wal.foreground
    property color nDim: Wal.color8
    property color shapeColor: Wal.color8

    property string fMonoStr: "monospace"
    property string fGroteskStr: "sans-serif"
    property real barHeight: 36

    // any of: circle square diamond triangle pentagon hexagon sunny verySunny
    //         cookie4 cookie6 cookie7 cookie9 cookie12 burst softBurst star
    property string hoverShape: "cookie6"

    signal clicked()

    implicitWidth: Math.max(blockRow.implicitWidth + 20, 36)
    implicitHeight: barHeight

    // 0 = resting circle, 1 = full target shape (overshoots for the spring)
    property real morph: mouse.containsMouse ? 1 : 0
    Behavior on morph {
        NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
    }

    Shape {
        id: shapeView
        anchors.centerIn: parent
        width: 34
        height: 34
        opacity: Math.min(1, block.morph * 1.5)
        scale: 0.55 + 0.45 * Math.min(block.morph, 1.15)
        rotation: (1 - Math.min(block.morph, 1)) * -40
        preferredRendererType: Shape.CurveRenderer // Qt 6.6+; on older Qt use layer.enabled + layer.samples: 4

        ShapePath {
            fillColor: block.shapeColor
            strokeColor: "transparent"
            PathPolyline { id: poly }
        }
    }

    function rebuild() {
        var h = shapeView.width / 2 - 1
        var cx = shapeView.width / 2, cy = shapeView.height / 2
        var pts = Shapes.morph("circle", block.hoverShape, block.morph)
        var out = []
        for (var i = 0; i < pts.length; i++)
            out.push(Qt.point(cx + pts[i].x * h, cy + pts[i].y * h))
        poly.path = out
    }
    onMorphChanged: rebuild()
    onHoverShapeChanged: rebuild()
    Component.onCompleted: rebuild()

    Row {
        id: blockRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: block.icon !== ""
            text: block.icon
            color: block.active ? block.nRed : block.nWhite
            font.family: block.fMonoStr
            font.pixelSize: 15
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: block.text !== ""
            text: block.text.toUpperCase()
            color: block.active ? block.nRed : block.nWhite
            font.family: block.fGroteskStr
            font.pixelSize: 12
            font.bold: true
            font.letterSpacing: 1
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: block.clicked()
    }
}
