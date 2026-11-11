import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../themes"
import "../services"
import "media"

PanelWindow {
    id: win
    property bool opened: false
    signal closeRequested()

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "tzeuk-media"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: opened

    readonly property var p: MediaPlayer.player

    onOpenedChanged: {
        if (opened) { card.dragX = 0; card.dragY = 0 }
    }

    Shortcut {
        sequence: "Escape"
        enabled: opened
        onActivated: win.closeRequested()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: win.closeRequested()
    }

    Rectangle {
        id: card
        width: 640
        height: 580
        radius: 28
        color: Qt.rgba(0.04, 0.04, 0.04, 0.68)
        border.color: dragging ? Theme.accent : Theme.fade(Theme.fg, 0.12)
        border.width: 1
        clip: true

        property bool dragging: false
        property real dragX: 0
        property real dragY: 0

        x: (win.width - width) / 2 + dragX
        y: (win.height - height) / 2 + dragY

        Behavior on border.color { ColorAnimation { duration: 180 } }

        MouseArea { anchors.fill: parent }

        // Blurred album art background
        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: 80
                blur: 0.92
                saturation: -0.15
            }
            Image {
                anchors.fill: parent
                source: win.p && win.p.trackArtUrl ? win.p.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: win.p && win.p.trackArtUrl ? 0.50 : 0
                Behavior on opacity { NumberAnimation { duration: 600 } }
            }
        }

        // Depth gradient
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.30) }
                GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.55) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.82) }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 26
            spacing: 16

            // HEADER
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 28

                MouseArea {
                    id: dragArea
                    anchors.left: parent.left
                    anchors.right: closeBtn.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    cursorShape: Qt.SizeAllCursor
                    property real startX: 0
                    property real startY: 0
                    property real pressX: 0
                    property real pressY: 0
                    onPressed: (m) => {
                        startX = card.dragX; startY = card.dragY
                        pressX = m.x; pressY = m.y
                        card.dragging = true
                    }
                    onPositionChanged: (m) => {
                        if (pressed) {
                            card.dragX = startX + (m.x - pressX)
                            card.dragY = startY + (m.y - pressY)
                        }
                    }
                    onReleased: card.dragging = false
                }

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    z: 1

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Repeater {
                            model: 3
                            Rectangle {
                                width: 20; height: 2; radius: 1
                                color: card.dragging ? Theme.accent : Theme.fade(Theme.fg, 0.4)
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "NOW PLAYING"
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 6; height: 6; radius: 3
                        color: MediaPlayer.isPlaying ? Theme.accent : Theme.fade(Theme.fg, 0.3)
                        SequentialAnimation on opacity {
                            running: MediaPlayer.isPlaying
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 800 }
                            NumberAnimation { to: 1.0; duration: 800 }
                        }
                    }
                }

                Rectangle {
                    id: closeBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28; height: 28; radius: 14
                    color: closeHover.containsMouse ? Theme.accent : Theme.fade(Theme.fg, 0.08)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    z: 2
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: closeHover.containsMouse ? Theme.bg : Theme.fg
                        font.pixelSize: 14
                        font.bold: true
                    }
                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.closeRequested()
                    }
                }
            }

            // ART + INFO
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 240
                spacing: 28

                MediaCover {
                    Layout.preferredWidth: 240
                    Layout.preferredHeight: 240
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6

                    Item { Layout.fillHeight: true }

                    Text {
                        Layout.fillWidth: true
                        text: win.p && win.p.trackTitle ? win.p.trackTitle : "Nothing Playing"
                        color: Theme.fg
                        font.family: Theme.sans
                        font.pixelSize: 26
                        font.bold: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 2
                        color: Theme.accent
                    }

                    Text {
                        Layout.fillWidth: true
                        text: win.p && win.p.trackArtist ? win.p.trackArtist : "—"
                        color: Theme.dim
                        font.family: Theme.sans
                        font.pixelSize: 15
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (!win.p) return ""
                            const parts = []
                            if (win.p.trackAlbum) parts.push(win.p.trackAlbum)
                            const md = win.p.metadata
                            if (md && md["xesam:contentCreated"]) {
                                const y = String(md["xesam:contentCreated"]).substring(0, 4)
                                if (/^\d{4}$/.test(y)) parts.push(y)
                            }
                            return parts.join(" · ")
                        }
                        color: Theme.fade(Theme.fg, 0.4)
                        font.family: Theme.font
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        visible: text !== ""
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // LIVE WAVE
            MediaWave {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
            }

            // PROGRESS
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    id: progressTrack
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                    radius: 2
                    color: Theme.fade(Theme.fg, 0.12)

                    Rectangle {
                        width: parent.width * (MediaPlayer.length > 0
                            ? Math.min(1, MediaPlayer.position / MediaPlayer.length) : 0)
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.topMargin: -10
                        anchors.bottomMargin: -10
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        function seek(mx) {
                            if (!win.p || !win.p.canSeek) return
                            const pct = Math.max(0, Math.min(1, mx / progressTrack.width))
                            win.p.position = pct * MediaPlayer.length
                        }
                        onPressed: (mouse) => seek(mouse.x)
                        onPositionChanged: (mouse) => { if (pressed) seek(mouse.x) }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: win.formatTime(MediaPlayer.position)
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 11
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: win.formatTime(MediaPlayer.length)
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 11
                    }
                }
            }

            // CONTROLS
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                spacing: 12

                Rectangle {
                    id: shuffleBtn
                    readonly property bool shuffleActive: win.p ? win.p.shuffle === true : false

                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 20
                    color: shuffleBtn.shuffleActive ? Theme.accent
                        : (shuffleHover.containsMouse ? Theme.fade(Theme.fg, 0.12) : "transparent")
                    border.color: shuffleBtn.shuffleActive ? Theme.accent : Theme.fade(Theme.fg, 0.15)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰒝"
                        color: shuffleBtn.shuffleActive ? Theme.bg : Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 16
                    }
                    MouseArea {
                        id: shuffleHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: win.p !== null && win.p !== undefined
                        onClicked: if (win.p) win.p.shuffle = !win.p.shuffle
                    }
                }

                Item { Layout.fillWidth: true }

                MediaControls {
                    Layout.alignment: Qt.AlignHCenter
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    id: repeatBtn
                    readonly property int repeatState: win.p ? (Number(win.p.loopState) || 0) : 0

                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 20
                    color: repeatBtn.repeatState > 0 ? Theme.accent
                        : (repeatHover.containsMouse ? Theme.fade(Theme.fg, 0.12) : "transparent")
                    border.color: repeatBtn.repeatState > 0 ? Theme.accent : Theme.fade(Theme.fg, 0.15)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: repeatBtn.repeatState === 2 ? "󰑖" : "󰑗"
                        color: repeatBtn.repeatState > 0 ? Theme.bg : Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 16
                    }
                    MouseArea {
                        id: repeatHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: win.p !== null && win.p !== undefined
                        onClicked: {
                            if (!win.p) return
                            const current = Number(win.p.loopState) || 0
                            win.p.loopState = (current + 1) % 3
                        }
                    }
                }
            }

            // VOLUME + PLAYER SOURCE
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                spacing: 12

                Text {
                    text: (!win.p || win.p.volume === 0) ? "󰝟" : "󰕾"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 14
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 3
                    radius: 1.5
                    color: Theme.fade(Theme.fg, 0.12)

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, win.p ? win.p.volume : 0))
                        height: parent.height
                        radius: parent.radius
                        color: Theme.fg
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.topMargin: -8
                        anchors.bottomMargin: -8
                        cursorShape: Qt.PointingHandCursor
                        function setVol(mx) {
                            if (!win.p) return
                            win.p.volume = Math.max(0, Math.min(1, mx / parent.width))
                        }
                        onPressed: (m) => setVol(m.x)
                        onPositionChanged: (m) => { if (pressed) setVol(m.x) }
                    }
                }

                Text {
                    text: win.p && win.p.volume !== undefined
                        ? Math.round(win.p.volume * 100) + "%" : "—"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 11
                    Layout.preferredWidth: 36
                    horizontalAlignment: Text.AlignRight
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 14
                    color: Theme.fade(Theme.fg, 0.15)
                }

                Text {
                    text: (win.p && win.p.identity) || "No Player"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    elide: Text.ElideRight
                    Layout.maximumWidth: 140
                }
            }
        }
    }

    function formatTime(sec) {
        const s = Math.floor(sec || 0)
        const m = Math.floor(s / 60)
        const r = s % 60
        return (m < 10 ? "0" : "") + m + ":" + (r < 10 ? "0" : "") + r
    }
}
