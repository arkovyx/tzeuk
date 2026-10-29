import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth

Item {
    id: page

    // Helper to format seconds to m:ss
    function fmtTime(s) {
        if (!s || s <= 0) return "0:00"
        var m = Math.floor(s / 60)
        var r = Math.floor(s % 60)
        return m + ":" + (r < 10 ? "0" : "") + r
    }

    // Timer to poke MPRIS for position updates
    Timer {
        running: MediaPlayer.hasMedia && MediaPlayer.player && MediaPlayer.player.isPlaying
        interval: 500
        repeat: true
        onTriggered: if (MediaPlayer.player) MediaPlayer.player.positionChanged()
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
            spacing: 14

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

            // --- Media Player ---
            Rectangle {
                id: mediaCard
                Layout.fillWidth: true
                implicitHeight: visible ? 95 : 0
                visible: MediaPlayer.hasMedia
                color: Theme.surfaceHi
                radius: 12

                readonly property var p: MediaPlayer.player

                // Robust duration reading (MPD's `length` is often 0)
                readonly property real duration: {
                    if (!p) return 0
                    // Try the direct property first
                    var l = p.length
                    if (l && l > 0 && l < 86400 * 7) return l
                    // Fallback to metadata (microseconds per MPRIS spec)
                    var meta = p.metadata || {}
                    var raw = meta["mpris:length"]
                    if (raw) {
                        var ml = Number(raw)
                        if (ml > 0) return ml > 10000 ? ml / 1000000 : ml
                    }
                    return 0
                }

                // Robust position reading
                readonly property real position: {
                    if (!p) return 0
                    var pos = p.position || 0
                    // If position exceeds duration and dividing by 1e6 fits, it's microseconds
                    if (duration > 0 && pos > duration && (pos / 1000000) <= duration) {
                        return pos / 1000000
                    }
                    return pos
                }

                readonly property real progress: duration > 0
                    ? Math.min(1.0, Math.max(0.0, position / duration))
                    : 0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        radius: 8
                        color: Theme.bg
                        Layout.alignment: Qt.AlignVCenter

                        Image {
                            anchors.fill: parent
                            source: mediaCard.p ? mediaCard.p.trackArtUrl : ""
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

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: mediaCard.p ? (mediaCard.p.trackTitle || "Unknown") : ""
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: mediaCard.p ? (mediaCard.p.trackArtist || "Unknown Artist") : ""
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        // Interactive Progress Bar
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 12
                            visible: mediaCard.duration > 0

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: page.fmtTime(mediaCard.position)
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: 9
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: page.fmtTime(mediaCard.duration)
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: 9
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 28
                                anchors.rightMargin: 28
                                anchors.verticalCenter: parent.verticalCenter
                                height: 4
                                radius: 2
                                color: Theme.surface

                                Rectangle {
                                    width: parent.width * mediaCard.progress
                                    height: parent.height
                                    radius: 2
                                    color: Theme.accent
                                }
                            }

                            MouseArea {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 28
                                anchors.rightMargin: 28
                                anchors.verticalCenter: parent.verticalCenter
                                height: 16
                                cursorShape: Qt.PointingHandCursor

                                function seek(mx) {
                                    if (mediaCard.p && mediaCard.p.canSeek && mediaCard.duration > 0) {
                                        var ratio = Math.max(0, Math.min(1, mx / width))
                                        mediaCard.p.position = ratio * mediaCard.duration
                                    }
                                }
                                onPressed: (mouse) => seek(mouse.x)
                                onPositionChanged: (mouse) => { if (pressed) seek(mouse.x) }
                            }
                        }

                        RowLayout {
                            spacing: 8
                            Rectangle {
                                width: 24; height: 24; radius: 12
                                color: m1.containsMouse ? Theme.surfaceHi : "transparent"
                                Text { anchors.centerIn: parent; text: "󰒮"; color: Theme.fg; font.family: Theme.font }
                                MouseArea { id: m1; anchors.fill: parent; hoverEnabled: true; onClicked: if(mediaCard.p?.canGoPrevious) mediaCard.p.previous() }
                            }
                            Rectangle {
                                width: 24; height: 24; radius: 12
                                color: m2.containsMouse ? Theme.surfaceHi : "transparent"
                                Text { anchors.centerIn: parent; text: mediaCard.p?.isPlaying ? "󰏤" : "󰐊"; color: Theme.accent; font.family: Theme.font }
                                MouseArea { id: m2; anchors.fill: parent; hoverEnabled: true; onClicked: if(mediaCard.p?.canTogglePlaying) mediaCard.p.togglePlaying() }
                            }
                            Rectangle {
                                width: 24; height: 24; radius: 12
                                color: m3.containsMouse ? Theme.surfaceHi : "transparent"
                                Text { anchors.centerIn: parent; text: "󰒭"; color: Theme.fg; font.family: Theme.font }
                                MouseArea { id: m3; anchors.fill: parent; hoverEnabled: true; onClicked: if(mediaCard.p?.canGoNext) mediaCard.p.next() }
                            }
                        }
                    }
                }
            }

                        // Controls
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

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: Net.wifiEnabled ? Theme.accent : Theme.surfaceHi
                    Text { anchors.centerIn: parent; text: Theme.iWifiHigh; color: Net.wifiEnabled ? Theme.bg : Theme.fg; font.family: Theme.font; font.pixelSize: 16 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Net.setWifi(!Net.wifiEnabled) }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    readonly property var ad: Bluetooth.defaultAdapter
                    color: (ad && ad.enabled) ? Theme.accent : Theme.surfaceHi
                    Text { anchors.centerIn: parent; text: "󰂯"; color: (parent.ad && parent.ad.enabled) ? Theme.bg : Theme.fg; font.family: Theme.font; font.pixelSize: 16 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (parent.ad) parent.ad.enabled = !parent.ad.enabled }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: Notifs.dnd ? Theme.accent : Theme.surfaceHi
                    Text { anchors.centerIn: parent; text: Notifs.dnd ? Theme.iBellOff : Theme.iBell; color: Notifs.dnd ? Theme.bg : Theme.fg; font.family: Theme.font; font.pixelSize: 16 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.dnd = !Notifs.dnd }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    readonly property var mic: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio : null
                    color: (mic && !mic.muted) ? Theme.accent : Theme.surfaceHi
                    Text { anchors.centerIn: parent; text: (parent.mic && !parent.mic.muted) ? "󰍬" : "󰍭"; color: (parent.mic && !parent.mic.muted) ? Theme.bg : Theme.fg; font.family: Theme.font; font.pixelSize: 16 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (parent.mic) parent.mic.muted = !parent.mic.muted }
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
                        height: 32
                        radius: 8
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
                Layout.preferredHeight: Math.min(col.width - 20, 210)
                Layout.topMargin: 0

                Visualizer {
                    anchors.centerIn: parent
                    diameter: Math.min(parent.width - 20, 200)
                }
            }

            // Small fixed spacer at the bottom
            Item { Layout.preferredHeight: 10 }
        }
    }
}
