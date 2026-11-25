import QtQuick

import "../themes"

// round icon button; icons are drawn, so no icon font is needed
Rectangle {
    id: rb

    property string kind
    property color ink: Theme.fg
    property bool hoverable: true
    signal clicked

    width: 40; height: 40; radius: 20
    color: hoverable && rbHov.hovered ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.18)
                                      : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.10)

    Canvas {
        anchors.centerIn: parent
        width: 18; height: 18
        property string k: rb.kind
        property color c: rb.ink
        onKChanged: requestPaint()
        onCChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = c
            ctx.fillStyle = c
            ctx.lineWidth = 2
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            if (k === "prev") {
                ctx.beginPath(); ctx.moveTo(11, 3); ctx.lineTo(5, 9); ctx.lineTo(11, 15); ctx.stroke()
            } else if (k === "next") {
                ctx.beginPath(); ctx.moveTo(7, 3); ctx.lineTo(13, 9); ctx.lineTo(7, 15); ctx.stroke()
            } else if (k === "play") {
                ctx.beginPath(); ctx.moveTo(5, 2); ctx.lineTo(16, 9); ctx.lineTo(5, 16); ctx.closePath(); ctx.fill()
            } else if (k === "pause") {
                ctx.fillRect(3.5, 2.5, 4, 13); ctx.fillRect(10.5, 2.5, 4, 13)
            } else if (k === "reset") {
                ctx.fillRect(4, 4, 10, 10)
            }
        }
    }
    HoverHandler { id: rbHov; enabled: rb.hoverable; cursorShape: Qt.PointingHandCursor }
    TapHandler { enabled: rb.hoverable; onTapped: rb.clicked() }
}
