import QtQuick
import QtQuick.Layouts

Item {
    id: page

    // --- The Circular Ring Component ---
    component StatRing: Item {
        id: ring
        property real value: 0
        property color ringColor: Theme.accent
        property string label: ""
        property string valueText: ""
        property int size: 90
        property real strokeWidth: 6

        implicitWidth: size
        implicitHeight: size + 26

        Canvas {
            id: canvas
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: ring.size
            height: ring.size

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var cx = width / 2
                var cy = height / 2
                var r = (width - ring.strokeWidth) / 2

                // Background track (faint circle)
                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, Math.PI * 2)
                ctx.strokeStyle = "rgba(255,255,255,0.08)"
                ctx.lineWidth = ring.strokeWidth
                ctx.stroke()

                // Progress arc (starts at top, goes clockwise)
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

        // Center value text
        Text {
            anchors.centerIn: canvas
            text: ring.valueText
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: ring.valueText.length > 5 ? 11 : 14
            font.bold: true
        }

        // Label below the ring
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

    // --- Content ---
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

            // Header
            Text {
                text: "SYSTEM"
                color: Theme.accent
                font.family: Theme.font
                font.pixelSize: 16
                font.bold: true
                font.letterSpacing: 3
            }

            // Top row: CPU, MEM, BAT, UPTIME
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

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
                    ringColor: Qt.color("#e5a25c")
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

            // Details row (for mem/uptime text)
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                Text {
                    text: "Mem: " + SysStats.fmtSize(SysStats.memUsed) + " / " + SysStats.fmtSize(SysStats.memTotal)
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 10
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.line
            }

            // Storage Section
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
                spacing: 12

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

                // No disks fallback
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
