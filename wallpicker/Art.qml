import QtQuick
import QtQuick.Shapes

// image rendered as dots inside a circle; falls back to the full image if the thumb is missing,
// and to a conic gradient while nothing is loaded
Item {
    id: root

    property string url
    property string fallback
    property real step: 6
    property bool useFallback: false

    layer.enabled: true
    layer.effect: Dm { step: root.step; circle: true }

    Shape {
        anchors.fill: parent
        visible: img.status !== Image.Ready
        ShapePath {
            strokeWidth: -1
            fillGradient: ConicalGradient {
                centerX: root.width / 2; centerY: root.height / 2; angle: 50
                GradientStop { position: 0; color: "#FFFFFF" }
                GradientStop { position: 0.2; color: "#444444" }
                GradientStop { position: 0.4; color: "#DDDDDD" }
                GradientStop { position: 0.6; color: "#111111" }
                GradientStop { position: 0.8; color: "#BBBBBB" }
                GradientStop { position: 1; color: "#FFFFFF" }
            }
            PathRectangle { width: root.width; height: root.height }
        }
    }
    Image {
        id: img
        anchors.fill: parent
        source: root.useFallback && root.fallback !== "" ? root.fallback : root.url
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(256, 256)
        asynchronous: true
        onStatusChanged: if (status === Image.Error && !root.useFallback && root.fallback !== "") root.useFallback = true
    }
}
