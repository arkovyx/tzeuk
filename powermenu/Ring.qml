import QtQuick

Canvas {
    id: root
    property int n: 60
    property real f: 0
    property real dot: 10
    property color activeColor: "#D71921"
    property color idleColor: "#40FFFFFF"

    onNChanged: requestPaint()
    onFChanged: requestPaint()
    onDotChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        var cx = width / 2
        var cy = height / 2
        var r = Math.min(width, height) / 2 - dot
        var lit = Math.round(n * Math.max(0, Math.min(1, f)))
        for (var i = 0; i < n; i++) {
            var a = (i / n) * Math.PI * 2 - Math.PI / 2
            ctx.beginPath()
            ctx.arc(cx + Math.cos(a) * r, cy + Math.sin(a) * r, dot / 2, 0, Math.PI * 2)
            ctx.fillStyle = i < lit ? activeColor : idleColor
            ctx.fill()
        }
    }
}
