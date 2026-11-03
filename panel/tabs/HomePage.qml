import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import "../../themes"
import "../../services"

Item {
    id: page

    FontLoader { id: fDoto; source: "../../fonts/Doto[ROND,wght].ttf" }
    FontLoader { id: fMono; source: "../../fonts/SpaceMono-Regular.ttf" }
    FontLoader { id: fGrotesk; source: "../../fonts/SpaceGrotesk-Regular.otf" }

    readonly property string fDot: fDoto.name !== "" ? fDoto.name : "monospace"
    readonly property string fMonoStr: fMono.name !== "" ? fMono.name : "monospace"
    readonly property string fSans: fGrotesk.name !== "" ? fGrotesk.name : "sans-serif"

    readonly property color nBlack: "#000000"
    readonly property color nWhite: "#ffffff"
    readonly property color nRed: "#d71921"
    readonly property color nDim: "#2a2a2a"
    readonly property color nSurface: "#0d0d0d"
    readonly property color nText: "#666666"

    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    readonly property var ad: Bluetooth.defaultAdapter

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 20

            // ===== HEADER: Big Clock + Date =====
            RowLayout {
                Layout.fillWidth: true
                spacing: 24

                Text {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: page.nWhite
                    font.family: page.fDot
                    font.pixelSize: 110
                    font.bold: true
                    font.letterSpacing: 2
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 22
                    spacing: 6

                    Rectangle {
                        width: 40
                        height: 3
                        color: page.nRed
                    }

                    Text {
                        text: Qt.formatDateTime(clock.date, "dddd").toUpperCase()
                        color: page.nWhite
                        font.family: page.fSans
                        font.pixelSize: 13
                        font.letterSpacing: 4
                        font.bold: true
                    }

                    Text {
                        text: Qt.formatDateTime(clock.date, "dd MMM yyyy").toUpperCase()
                        color: page.nText
                        font.family: page.fSans
                        font.pixelSize: 12
                        letterSpacing: 2
                        font.bold: true
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // ===== DOT RULE =====
            Canvas {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.fillStyle = "rgba(255,255,255,0.5)"
                    for (var x = 2; x < width; x += 8) {
                        ctx.beginPath()
                        ctx.arc(x, 3, 1.2, 0, Math.PI * 2)
                        ctx.fill()
                    }
                }
            }

            // ===== MEDIA PLAYER =====
            Rectangle {
                Layout.fillWidth: true
                visible: MediaPlayer.hasMedia
                implicitHeight: visible ? 100 : 0
                color: page.nSurface
                border.width: 1
                border.color: page.nDim

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 16

                    Rectangle {
                        Layout.preferredWidth: 72
                        Layout.preferredHeight: 72
                        color: page.nDim

                        Image {
                            id: artImg
                            anchors.fill: parent
                            source: MediaPlayer.player ? MediaPlayer.player.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                            asynchronous: true
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: artImg.status !== Image.Ready
                            text: "♪"
                            color: page.nText
                            font.family: page.fSans
                            font.pixelSize: 32
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            text: MediaPlayer.player ? (MediaPlayer.player.trackTitle || "Unknown") : ""
                            color: page.nWhite
                            font.family: page.fSans
                            font.pixelSize: 16
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: MediaPlayer.player ? (MediaPlayer.player.trackArtist || "") : ""
                            color: page.nText
                            font.family: page.fSans
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            spacing: 20
                            Layout.topMargin: 6

                            Text {
                                text: "◀◀"
                                color: page.nWhite
                                font.pixelSize: 14
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -10
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (MediaPlayer.player?.canGoPrevious) MediaPlayer.player.previous()
                                }
                            }

                            Text {
                                text: MediaPlayer.player?.isPlaying ? "❚❚" : "▶"
                                color: page.nRed
                                font.pixelSize: 18
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -10
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (MediaPlayer.player?.canTogglePlaying) MediaPlayer.player.togglePlaying()
                                }
                            }

                            Text {
                                text: "▶▶"
                                color: page.nWhite
                                font.pixelSize: 14
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -10
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (MediaPlayer.player?.canGoNext) MediaPlayer.player.next()
                                }
                            }
                        }
                    }
                }
            }

            // ===== BRIGHTNESS =====
            Text {
                text: "BRIGHTNESS"
                color: page.nText
                font.family: page.fSans
                font.pixelSize: 11
                font.letterSpacing: 4
                font.bold: true
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 50
                color: page.nSurface
                border.width: 1
                border.color: page.nDim

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * (Bright.percent / 100)
                    color: page.nDim
                }

                Rectangle {
                    x: Math.max(0, Math.min(parent.width - width, parent.width * (Bright.percent / 100) - width / 2))
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: parent.height
                    color: page.nRed
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16

                    Text {
                        text: Bright.percent.toString().padStart(3, "0") + "%"
                        color: page.nWhite
                        font.family: page.fDot
                        font.pixelSize: 20
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "☀"
                        color: page.nWhite
                        font.pixelSize: 18
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (m) => Bright.setPercent(Math.max(1, Math.min(100, (m.x / width) * 100)))
                    onPositionChanged: (m) => { if (pressed) Bright.setPercent(Math.max(1, Math.min(100, (m.x / width) * 100))) }
                }
            }

            // ===== TOGGLES =====
            Text {
                text: "TOGGLES"
                color: page.nText
                font.family: page.fSans
                font.pixelSize: 11
                font.letterSpacing: 4
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { icon: Net.wifiEnabled ? "󰤨" : "󰤮", label: "WI-FI", active: Net.wifiEnabled },
                        { icon: "󰂯", label: "BT", active: page.ad ? page.ad.enabled : false },
                        { icon: Notifs.dnd ? "󰂛" : "󰂚", label: "DND", active: Notifs.dnd },
                        { icon: (page.audio && !page.audio.muted) ? "󰍬" : "󰍭", label: "MIC", active: page.audio ? !page.audio.muted : false }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: 80
                        color: modelData.active ? page.nWhite : page.nSurface
                        border.width: 1
                        border.color: modelData.active ? page.nWhite : page.nDim

                        Column {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon
                                color: modelData.active ? page.nBlack : page.nWhite
                                font.family: page.fMonoStr
                                font.pixelSize: 24
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: modelData.active ? page.nBlack : page.nText
                                font.family: page.fSans
                                font.pixelSize: 10
                                font.letterSpacing: 2
                                font.bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (index === 0) Net.setWifi(!Net.wifiEnabled)
                                else if (index === 1) { if (page.ad) page.ad.enabled = !page.ad.enabled }
                                else if (index === 2) Notifs.dnd = !Notifs.dnd
                                else if (index === 3) { if (page.audio) page.audio.muted = !page.audio.muted }
                            }
                        }
                    }
                }
            }

            // ===== POWER =====
            Text {
                text: "POWER"
                color: page.nText
                font.family: page.fSans
                font.pixelSize: 11
                font.letterSpacing: 4
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { icon: "󰌾", label: "LOCK", action: "lock" },
                        { icon: "󰒲", label: "SLEEP", action: "sleep" },
                        { icon: "󰗽", label: "LOGOUT", action: "leave" },
                        { icon: "󰜉", label: "REBOOT", action: "reboot" },
                        { icon: "󰐥", label: "OFF", action: "shutdown" }
                    ]

                    delegate: Rectangle {
                        id: pwrBtn
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: 80
                        color: pwrMouse.containsMouse ? page.nDim : page.nSurface
                        border.width: 1
                        border.color: pwrMouse.containsMouse ? page.nRed : page.nDim
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: pwrBtn.modelData.icon
                                color: pwrMouse.containsMouse ? page.nRed : page.nWhite
                                font.family: page.fMonoStr
                                font.pixelSize: 24
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: pwrBtn.modelData.label
                                color: page.nWhite
                                font.family: page.fSans
                                font.pixelSize: 10
                                font.letterSpacing: 2
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: pwrMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Session.run(pwrBtn.modelData.action)
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
