import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

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

            // Placeholders for now
            Item { Layout.fillHeight: true }
        }
    }
}
