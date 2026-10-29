import QtQuick
import Quickshell

Item {
    id: root
    property int diameter: 220
    property color vizColor: Theme.accent
    property color trackColor: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)

    implicitWidth: diameter
    implicitHeight: diameter

    readonly property var displayValues: Cava.values

    Canvas {
        id: canvas
        anchors.fill: parent
        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: Cava
            function onValuesChanged() { canvas.requestPaint() }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var cx = width / 2
            var cy = height / 2
            var maxR = Math.min(width, height) / 2 - 10
            var minR = maxR * 0.48
            var vals = root.displayValues
            var barCount = vals.length

            // Idle ring
            ctx.beginPath()
            ctx.arc(cx, cy, minR, 0, Math.PI * 2)
            ctx.strokeStyle = root.trackColor
            ctx.lineWidth = 1
            ctx.stroke()

            if (barCount === 0) {
                // Subtle outer idle ring when silent
                ctx.beginPath()
                ctx.arc(cx, cy, minR + (maxR - minR) * 0.3, 0, Math.PI * 2)
                ctx.strokeStyle = Qt.rgba(root.vizColor.r, root.vizColor.g, root.vizColor.b, 0.15)
                ctx.lineWidth = 1
                ctx.stroke()
                return
            }

            var step = (Math.PI * 2) / barCount
            var barWidth = Math.max(2, minR * step * 0.7)

            for (var i = 0; i < barCount; i++) {
                var angle = -Math.PI / 2 + i * step
                var v = Math.max(0.04, Math.min(1, vals[i]))
                var outerR = minR + (maxR - minR) * v

                var x1 = cx + Math.cos(angle) * minR
                var y1 = cy + Math.sin(angle) * minR
                var x2 = cx + Math.cos(angle) * outerR
                var y2 = cy + Math.sin(angle) * outerR

                ctx.beginPath()
                ctx.moveTo(x1, y1)
                ctx.lineTo(x2, y2)
                ctx.strokeStyle = root.vizColor
                ctx.lineWidth = barWidth
                ctx.lineCap = "round"
                ctx.stroke()
            }
        }
    }

    // Center icon
    Text {
        anchors.centerIn: parent
        text: Cava.active ? "󰎆" : "󰝛"
        color: root.vizColor
        opacity: 0.5
        font.family: Theme.font
        font.pixelSize: root.diameter * 0.1
    }
}
