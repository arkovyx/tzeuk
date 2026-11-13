import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../themes"

Item {
    id: page

    FontLoader { id: fDoto; source: "../../fonts/Doto.ttf" }
    FontLoader { id: fMono; source: "../../fonts/SpaceMono-Regular.ttf" }
    FontLoader { id: fGrotesk; source: "../../fonts/SpaceGrotesk-Regular.otf" }

    readonly property string fDot: fDoto.name !== "" ? fDoto.name : "monospace"
    readonly property string fMonoStr: fMono.name !== "" ? fMono.name : "monospace"
    readonly property string fSans: fGrotesk.name !== "" ? fGrotesk.name : "sans-serif"

    // ═══ dynamic palette ═══
    readonly property color nBlack: Theme.bg
    readonly property color nWhite: Theme.fg
    readonly property color nRed: Theme.accent
    readonly property color nDim: Theme.line
    readonly property color nSurface: Theme.surfaceHi
    readonly property color nText: Theme.nText

    component StatRing: Item {
        id: ring
        property real value: 0
        property string label: ""
        property string valueText: ""
        property color ringColor: "#ffffff"
        property int size: 140

        implicitWidth: size
        implicitHeight: size + 40

        Canvas {
            id: canvas
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: ring.size
            height: ring.size

            // theme-reactive inputs
            property color trackColor: page.nDim
            property color markerColor: page.nRed
            onTrackColorChanged: requestPaint()
            onMarkerColorChanged: requestPaint()

            Component.onCompleted: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var cx = width / 2, cy = height / 2
                var r = width / 2 - 10

                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, Math.PI * 2)
                ctx.strokeStyle = String(trackColor)
                ctx.lineWidth = 3
                ctx.stroke()

                if (ring.value > 0) {
                    ctx.beginPath()
                    var start = -Math.PI / 2
                    var end = start + (Math.PI * 2 * Math.min(1, Math.max(0, ring.value)))
                    ctx.arc(cx, cy, r, start, end)
                    ctx.strokeStyle = ring.ringColor
                    ctx.lineWidth = 3
                    ctx.lineCap = "square"
                    ctx.stroke()
                }

                if (ring.value > 0 && ring.value < 1) {
                    var angle = -Math.PI / 2 + Math.PI * 2 * ring.value
                    var mx = cx + Math.cos(angle) * r
                    var my = cy + Math.sin(angle) * r
                    ctx.beginPath()
                    ctx.arc(mx, my, 4, 0, Math.PI * 2)
                    ctx.fillStyle = String(markerColor)
                    ctx.fill()
                }
            }
        }

        onValueChanged: canvas.requestPaint()
        onRingColorChanged: canvas.requestPaint()

        Text {
            anchors.centerIn: canvas
            text: ring.valueText
            color: page.nWhite
            font.family: page.fDot
            font.pixelSize: ring.valueText.length > 5 ? 18 : 22
            font.bold: true
        }

        Text {
            anchors.top: canvas.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            text: ring.label.toUpperCase()
            color: page.nText
            font.family: page.fSans
            font.pixelSize: 11
            font.letterSpacing: 3
            font.bold: true
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 24

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "SYSTEM"
                    color: page.nWhite
                    font.family: page.fDot
                    font.pixelSize: 42
                    font.bold: true
                    font.letterSpacing: 4
                }

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 3
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 20
                    color: page.nRed
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "UPTIME " + SysStats.fmtTime(SysStats.uptime).toUpperCase()
                    color: page.nText
                    font.family: page.fMonoStr
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: page.nDim }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 40

                StatRing {
                    value: SysStats.cpu
                    valueText: Math.round(SysStats.cpu * 100) + "%"
                    label: "CPU"
                    ringColor: SysStats.cpu > 0.85 ? page.nRed : page.nWhite
                }

                StatRing {
                    value: SysStats.memTotal > 0 ? SysStats.memUsed / SysStats.memTotal : 0
                    valueText: Math.round((SysStats.memTotal > 0 ? SysStats.memUsed / SysStats.memTotal : 0) * 100) + "%"
                    label: "MEMORY"
                    ringColor: page.nWhite
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                color: page.nSurface
                border.width: 1
                border.color: page.nDim

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12

                    Text {
                        text: SysStats.fmtSize(SysStats.memUsed) + " / " + SysStats.fmtSize(SysStats.memTotal)
                        color: page.nWhite
                        font.family: page.fMonoStr
                        font.pixelSize: 12
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "MEM"
                        color: page.nText
                        font.family: page.fSans
                        font.pixelSize: 10
                        font.letterSpacing: 3
                        font.bold: true
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: page.nDim; Layout.topMargin: 8 }

            Text {
                text: "STORAGE"
                color: page.nRed
                font.family: page.fSans
                font.pixelSize: 11
                font.letterSpacing: 4
                font.bold: true
            }

            Repeater {
                model: SysStats.disks
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 64
                    color: page.nSurface
                    border.width: 1
                    border.color: page.nDim

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: modelData.label.toUpperCase()
                                color: page.nWhite
                                font.family: page.fSans
                                font.pixelSize: 12
                                font.bold: true
                                font.letterSpacing: 2
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: SysStats.fmtSize(modelData.used) + " / " + SysStats.fmtSize(modelData.size)
                                color: page.nText
                                font.family: page.fMonoStr
                                font.pixelSize: 10
                            }

                            Text {
                                text: Math.round((modelData.used / modelData.size) * 100) + "%"
                                color: (modelData.used / modelData.size) > 0.9 ? page.nRed : page.nWhite
                                font.family: page.fDot
                                font.pixelSize: 18
                                font.bold: true
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6
                            color: page.nBlack

                            Rectangle {
                                width: parent.width * Math.min(1, modelData.used / modelData.size)
                                height: parent.height
                                color: (modelData.used / modelData.size) > 0.9 ? page.nRed : page.nWhite
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
