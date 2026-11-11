import QtQuick
import "../../themes"
import "../../services"

Canvas {
    id: root

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()

        const bars = Cava.values
        if (!bars || bars.length === 0 || !MediaPlayer.isPlaying) {
            ctx.strokeStyle = Theme.fade(Theme.fg, 0.15)
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.moveTo(0, height / 2)
            ctx.lineTo(width, height / 2)
            ctx.stroke()
            return
        }

        const n = bars.length
        const barW = width / n
        const cx = height / 2
        const maxH = height / 2 - 3

        for (let i = 0; i < n; i++) {
            const v = Math.min(1, Math.max(0, bars[i] || 0))
            const h = 2 + v * maxH
            const t = i / Math.max(1, n - 1)
            const r = t < 0.5 ? 0.84 : 1.0
            const g = t < 0.5 ? 0.10 : 1.0
            const b = t < 0.5 ? 0.13 : 1.0
            const a = 0.55 + v * 0.45
            ctx.fillStyle = Qt.rgba(r, g, b, a)
            ctx.fillRect(i * barW + barW * 0.2, cx - h, barW * 0.6, h * 2)
        }
    }

    Connections {
        target: Cava
        function onValuesChanged() { root.requestPaint() }
    }
    Connections {
        target: MediaPlayer
        function onIsPlayingChanged() { root.requestPaint() }
    }
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
}
