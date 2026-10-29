import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth

Item {
    id: page

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
            spacing: 20

            Text {
                text: "HOME"
                color: Theme.accent
                font.family: Theme.font
                font.pixelSize: 16
                font.bold: true
                font.letterSpacing: 3
            }

            // --- Brightness ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Text { text: "󰃠"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 16 }
                    Text { Layout.fillWidth: true; text: "Brightness"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 13 }
                    Text { text: Bright.percent + "%"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 13; font.bold: true }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    radius: 4
                    color: Theme.surfaceHi

                    Rectangle {
                        width: parent.width * (Bright.percent / 100)
                        height: parent.height
                        radius: 4
                        color: Theme.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: (mouse) => {
                            if (pressed) Bright.setPercent(Math.max(1, Math.min(100, (mouse.x / width) * 100)))
                        }
                        onPressed: (mouse) => Bright.setPercent(Math.max(1, Math.min(100, (mouse.x / width) * 100)))
                    }
                }
            }

            // --- Quick Toggles ---
            Text {
                text: "TOGGLES"
                color: Theme.accent
                font.family: Theme.font
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 2
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // WiFi
                Rectangle {
                    Layout.fillWidth: true
                    height: 36; radius: 10
                    color: Net.wifiEnabled ? Theme.accent : Theme.surfaceHi
                    Text { anchors.centerIn: parent; text: Theme.iWifiHigh; color: Net.wifiEnabled ? Theme.bg : Theme.fg; font.family: Theme.font; font.pixelSize: 16 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Net.setWifi(!Net.wifiEnabled) }
                }

                // BT
                Rectangle {
                    Layout.fillWidth: true
                    height: 36; radius: 10
                    readonly property var ad: Bluetooth.defaultAdapter
                    color: (ad && ad.enabled) ? Theme.accent : Theme.surfaceHi
                    Text { anchors.centerIn: parent; text: "󰂯"; color: (parent.ad && parent.ad.enabled) ? Theme.bg : Theme.fg; font.family: Theme.font; font.pixelSize: 16 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (parent.ad) parent.ad.enabled = !parent.ad.enabled }
                }

                // DND
                Rectangle {
                    Layout.fillWidth: true
                    height: 36; radius: 10
                    color: Notifs.dnd ? Theme.accent : Theme.surfaceHi
                    Text { anchors.centerIn: parent; text: Notifs.dnd ? Theme.iBellOff : Theme.iBell; color: Notifs.dnd ? Theme.bg : Theme.fg; font.family: Theme.font; font.pixelSize: 16 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.dnd = !Notifs.dnd }
                }

                // Mic
                Rectangle {
                    Layout.fillWidth: true
                    height: 36; radius: 10
                    readonly property var mic: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio : null
                    color: (mic && !mic.muted) ? Theme.accent : Theme.surfaceHi
                    Text { anchors.centerIn: parent; text: (parent.mic && !parent.mic.muted) ? "󰍬" : "󰍭"; color: (parent.mic && !parent.mic.muted) ? Theme.bg : Theme.fg; font.family: Theme.font; font.pixelSize: 16 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (parent.mic) parent.mic.muted = !parent.mic.muted }
                }
            }

            // --- Media Player ---
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: visible ? 90 : 0
                visible: MediaPlayer.hasMedia
                color: Theme.surfaceHi
                radius: 12

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // Album Art
                    Rectangle {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        radius: 8
                        color: Theme.bg

                        Image {
                            anchors.fill: parent
                            source: MediaPlayer.player ? MediaPlayer.player.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                            asynchronous: true
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: parent.children[0].status !== Image.Ready
                            text: "󰎆"
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 24
                        }
                    }

                    // Track Info & Controls
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            text: MediaPlayer.player ? (MediaPlayer.player.trackTitle || "Unknown") : ""
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 14
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: MediaPlayer.player ? (MediaPlayer.player.trackArtist || "Unknown Artist") : ""
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            spacing: 8
                            Rectangle {
                                width: 24; height: 24; radius: 12
                                color: m1.containsMouse ? Theme.surfaceHi : "transparent"
                                Text { anchors.centerIn: parent; text: "󰒮"; color: Theme.fg; font.family: Theme.font }
                                MouseArea { id: m1; anchors.fill: parent; hoverEnabled: true; onClicked: if(MediaPlayer.player?.canGoPrevious) MediaPlayer.player.previous() }
                            }
                            Rectangle {
                                width: 24; height: 24; radius: 12
                                color: m2.containsMouse ? Theme.surfaceHi : "transparent"
                                Text { anchors.centerIn: parent; text: MediaPlayer.player?.isPlaying ? "󰏤" : "󰐊"; color: Theme.accent; font.family: Theme.font }
                                MouseArea { id: m2; anchors.fill: parent; hoverEnabled: true; onClicked: if(MediaPlayer.player?.canTogglePlaying) MediaPlayer.player.togglePlaying() }
                            }
                            Rectangle {
                                width: 24; height: 24; radius: 12
                                color: m3.containsMouse ? Theme.surfaceHi : "transparent"
                                Text { anchors.centerIn: parent; text: "󰒭"; color: Theme.fg; font.family: Theme.font }
                                MouseArea { id: m3; anchors.fill: parent; hoverEnabled: true; onClicked: if(MediaPlayer.player?.canGoNext) MediaPlayer.player.next() }
                            }
                        }
                    }
                }
            }

            // --- Power ---
            Text {
                text: "POWER"
                color: Theme.accent
                font.family: Theme.font
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 2
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { id: "lock", icon: "󰌾" },
                        { id: "sleep", icon: "󰒲" },
                        { id: "leave", icon: "󰗽" },
                        { id: "reboot", icon: "󰜉" },
                        { id: "shutdown", icon: "󰐥" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 36; radius: 10
                        color: mouse.containsMouse ? Theme.err : Theme.surfaceHi
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            color: mouse.containsMouse ? Theme.bg : Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 16
                        }
                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Session.run(modelData.id)
                        }
                    }
                }
            }

            // --- Circular Audio Visualizer ---
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(col.width - 20, 260)
                Layout.topMargin: 4

                Visualizer {
                    anchors.centerIn: parent
                    diameter: Math.min(parent.width - 20, 240)
                }
            }

            // Bottom padding
            Item { Layout.preferredHeight: 8 }
        }
    }
}
