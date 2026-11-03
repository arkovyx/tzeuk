import QtQuick
import QtQuick.Layouts

Item {
    id: page

    component StatRing: Item {
        id: ring
        property real value: 0
        property color ringColor: Theme.accent
        property string label: ""
        property string valueText: ""
        property int size: 84
        property real strokeWidth: 6

        implicitWidth: size
        implicitHeight: size + 24
        Layout.preferredWidth: size
        Layout.preferredHeight: size + 24

        Canvas {
            id: canvas
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: ring.size
            height: ring.size

            // Force the first paint
            Component.onCompleted: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var cx = width / 2
                var cy = height / 2
                var r = (width - ring.strokeWidth) / 2

                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, Math.PI * 2)
                ctx.strokeStyle = "rgba(255,255,255,0.10)"
                ctx.lineWidth = ring.strokeWidth
                ctx.stroke()

                if (ring.value > 0) {
                    ctx.beginPath()
                    var start = -Math.PI / 2
                    var end = start + (Math.PI * 2 * Math.min(1, Math.max(0, ring.value)))
                    ctx.arc(cx, cy, r, start, end)
                    ctx.strokeStyle = ring.ringColor
                    ctx.lineWidth = ring.strokeWidth
                    ctx.lineCap = "round"
                    ctx.stroke()
                }
            }
        }

        onValueChanged: canvas.requestPaint()
        onRingColorChanged: canvas.requestPaint()

        Text {
            anchors.centerIn: canvas
            text: ring.valueText
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: ring.valueText.length > 5 ? 10 : 13
            font.bold: true
        }

        Text {
            anchors.top: canvas.bottom
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            text: ring.label
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 10
            font.bold: true
            font.letterSpacing: 1
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 20
        contentWidth: width
        contentHeight: col.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 24

            Text {
                text: "SYSTEM"
                color: Theme.accent
                font.family: Theme.font
                font.pixelSize: 16
                font.bold: true
                font.letterSpacing: 3
            }

            Flow {
                Layout.fillWidth: true
                spacing: 14

                StatRing {
                    value: SysStats.cpu
                    valueText: Math.round(SysStats.cpu * 100) + "%"
                    label: "CPU"
                    ringColor: SysStats.cpu > 0.85 ? Theme.err : Theme.accent
                }
                StatRing {
                    value: SysStats.memTotal > 0 ? SysStats.memUsed / SysStats.memTotal : 0
                    valueText: Math.round((SysStats.memTotal > 0 ? SysStats.memUsed / SysStats.memTotal : 0) * 100) + "%"
                    label: "MEM"
                    ringColor: "#e5a25c"
                }
                StatRing {
                    visible: SysStats.hasBat
                    value: SysStats.batPct
                    valueText: Math.round(SysStats.batPct * 100) + "%"
                    label: "BAT"
                    ringColor: SysStats.batPct <= 0.15 ? Theme.err : (SysStats.charging ? "#5ccfe5" : "#5ce58a")
                }
                StatRing {
                    value: 1
                    valueText: SysStats.fmtTime(SysStats.uptime)
                    label: "UPTIME"
                    ringColor: Theme.dim
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Memory: " + SysStats.fmtSize(SysStats.memUsed) + " / " + SysStats.fmtSize(SysStats.memTotal)
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 11
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.line
            }

            Text {
                text: "STORAGE"
                color: Theme.accent
                font.family: Theme.font
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 2
            }

            Flow {
                Layout.fillWidth: true
                spacing: 14

                Repeater {
                    model: SysStats.disks
                    delegate: StatRing {
                        required property var modelData
                        value: modelData.size > 0 ? modelData.used / modelData.size : 0
                        valueText: Math.round((modelData.size > 0 ? modelData.used / modelData.size : 0) * 100) + "%"
                        label: modelData.label.toUpperCase()
                        ringColor: (modelData.used / modelData.size) > 0.9 ? Theme.err : Theme.accent
                    }
                }

                Text {
                    visible: SysStats.disks.length === 0
                    text: "No local partitions detected"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 11
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
