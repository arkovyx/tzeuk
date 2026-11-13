import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
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

    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    readonly property var ad: Bluetooth.defaultAdapter

    readonly property var player: MediaPlayer.player
    readonly property bool isPlaying: MediaPlayer.isPlaying
    readonly property bool hasMedia: MediaPlayer.hasMedia

    SystemClock { id: clock; precision: SystemClock.Minutes }

    function fmtTime(s) {
        if (!s || s <= 0) return "0:00"
        s = Math.floor(s)
        var m = Math.floor(s / 60)
        var r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
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
            spacing: 20

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

                    Rectangle { width: 40; height: 3; color: page.nRed }

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
                        font.letterSpacing: 2
                        font.bold: true
                    }
                }

                Item { Layout.fillWidth: true }
            }

            Canvas {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                property color dotColor: Theme.fg
                onDotColorChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.fillStyle = Qt.rgba(dotColor.r, dotColor.g, dotColor.b, 0.5)
                    for (var x = 2; x < width; x += 8) {
                        ctx.beginPath()
                        ctx.arc(x, 3, 1.2, 0, Math.PI * 2)
                        ctx.fill()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: page.hasMedia
                implicitHeight: page.hasMedia ? 210 : 0
                color: page.nSurface
                border.width: 1
                border.color: page.nDim

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 28

                    Rectangle {
                        id: disc
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 160
                        Layout.alignment: Qt.AlignVCenter
                        radius: width / 2
                        color: page.nBlack
                        border.width: 2
                        border.color: page.nDim

                        Rectangle {
                            id: circleMask
                            anchors.fill: parent
                            radius: width / 2
                            color: "white"
                            visible: false
                            layer.enabled: true
                        }

                        Item {
                            id: rotator
                            anchors.fill: parent
                            rotation: MediaPlayer.discAngle
                            transformOrigin: Item.Center

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: page.nDim
                                visible: coverSource.status !== Image.Ready
                                z: 0
                            }

                            Image {
                                id: coverSource
                                anchors.fill: parent
                                source: page.player ? (page.player.trackArtUrl || "") : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: false
                                layer.enabled: true
                                z: 1
                            }

                            MultiEffect {
                                anchors.fill: parent
                                source: coverSource
                                maskEnabled: coverSource.status === Image.Ready
                                maskSource: circleMask
                                z: 2
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 30
                                height: width
                                radius: width / 2
                                color: "transparent"
                                border.width: 1
                                border.color: page.nWhite
                                opacity: 0.1
                                z: 3
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 60
                                height: width
                                radius: width / 2
                                color: "transparent"
                                border.width: 1
                                border.color: page.nWhite
                                opacity: 0.1
                                z: 3
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 56
                                height: 56
                                radius: 28
                                color: page.nBlack
                                border.width: 2
                                border.color: page.nRed
                                z: 4

                                Canvas {
                                    id: noteCanvas
                                    anchors.centerIn: parent
                                    width: 40
                                    height: 44

                                    Component.onCompleted: requestPaint()

                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)
                                        ctx.fillStyle = page.nRed

                                        var pattern = [
                                            [0,0,0,0,0,0,1,1,1,0],
                                            [0,0,0,0,0,0,1,1,1,1],
                                            [0,0,0,0,0,0,1,0,1,1],
                                            [0,0,0,0,0,0,1,0,0,0],
                                            [0,0,0,0,0,0,1,0,0,0],
                                            [0,0,0,0,0,0,1,0,0,0],
                                            [0,0,0,0,0,0,1,0,0,0],
                                            [0,0,0,0,0,0,1,0,0,0],
                                            [0,0,0,0,0,0,1,0,0,0],
                                            [0,0,0,0,1,1,1,0,0,0],
                                            [0,0,0,1,1,1,1,0,0,0],
                                            [0,0,0,1,1,1,1,0,0,0],
                                            [0,0,0,0,1,1,1,0,0,0],
                                            [0,0,0,0,0,0,0,0,0,0]
                                        ]

                                        var rows = pattern.length
                                        var cols = pattern[0].length
                                        var cellW = width / cols
                                        var cellH = height / rows
                                        var dotR = Math.min(cellW, cellH) * 0.42

                                        for (var j = 0; j < rows; j++) {
                                            for (var i = 0; i < cols; i++) {
                                                if (pattern[j][i] === 1) {
                                                    ctx.beginPath()
                                                    ctx.arc(
                                                        i * cellW + cellW / 2,
                                                        j * cellH + cellH / 2,
                                                        dotR, 0, Math.PI * 2
                                                    )
                                                    ctx.fill()
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 8
                                height: 8
                                radius: 4
                                color: page.nSurface
                                z: 5
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            Row {
                                spacing: 8

                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: page.nRed
                                    anchors.verticalCenter: parent.verticalCenter
                                    SequentialAnimation on opacity {
                                        running: page.isPlaying
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.3; duration: 700 }
                                        NumberAnimation { to: 1.0; duration: 700 }
                                    }
                                }

                                Text {
                                    text: page.isPlaying ? "NOW PLAYING" : "PAUSED"
                                    color: page.nRed
                                    font.family: page.fSans
                                    font.pixelSize: 10
                                    font.letterSpacing: 4
                                    font.bold: true
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: (page.player ? (page.player.trackTitle || "UNKNOWN TRACK") : "UNKNOWN TRACK").toUpperCase()
                                color: page.nWhite
                                font.family: page.fSans
                                font.pixelSize: 18
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: (page.player ? (page.player.trackArtist || "UNKNOWN ARTIST") : "UNKNOWN ARTIST").toUpperCase()
                                color: page.nText
                                font.family: page.fMonoStr
                                font.pixelSize: 11
                                font.letterSpacing: 2
                                elide: Text.ElideRight
                            }
                        }

                        Item { Layout.fillHeight: true }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            visible: MediaPlayer.length > 0

                            readonly property real trackLength: MediaPlayer.length
                            readonly property real trackPos: MediaPlayer.position
                            readonly property real progress: trackLength > 0 ? Math.min(1, Math.max(0, trackPos / trackLength)) : 0

                            Rectangle {
                                id: progTrack
                                Layout.fillWidth: true
                                Layout.preferredHeight: 8
                                color: page.nBlack
                                border.width: 1
                                border.color: page.nDim

                                Rectangle {
                                    width: parent.width * parent.parent.progress
                                    height: parent.height
                                    color: page.nWhite
                                }

                                Rectangle {
                                    x: Math.max(0, Math.min(progTrack.width - width, progTrack.width * progTrack.parent.progress - width / 2))
                                    width: 3
                                    height: parent.height + 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: page.nRed
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.topMargin: -10
                                    anchors.bottomMargin: -10
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (m) => {
                                        if (page.player && page.player.length > 0) {
                                            var newPos = (m.x / progTrack.width) * page.player.length
                                            page.player.position = newPos
                                            MediaPlayer.position = newPos
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: page.fmtTime(progTrack.parent.trackPos)
                                    color: page.nText
                                    font.family: page.fDot
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: page.fmtTime(progTrack.parent.trackLength)
                                    color: page.nText
                                    font.family: page.fDot
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 40
                                color: prevHover.containsMouse ? page.nDim : "transparent"
                                border.width: 1
                                border.color: page.nDim
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "◀◀"
                                    color: page.nWhite
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    id: prevHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (page.player && page.player.canGoPrevious) page.player.previous()
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 72
                                Layout.preferredHeight: 44
                                color: playHover.containsMouse ? page.nRed : page.nWhite
                                border.width: 1
                                border.color: page.nWhite
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: page.isPlaying ? "❚❚" : "▶"
                                    color: playHover.containsMouse ? page.nWhite : page.nBlack
                                    font.pixelSize: 17
                                    font.bold: true
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    id: playHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (page.player && page.player.canTogglePlaying) page.player.togglePlaying()
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 40
                                color: nextHover.containsMouse ? page.nDim : "transparent"
                                border.width: 1
                                border.color: page.nDim
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "▶▶"
                                    color: page.nWhite
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    id: nextHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (page.player && page.player.canGoNext) page.player.next()
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }
                }
            }

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
                        { icon: (page.audio && !page.audio.muted) ? "󰕾" : "󰝟", label: "MUTE", active: page.audio ? page.audio.muted : false }
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
