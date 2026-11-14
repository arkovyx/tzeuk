import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../themes"

Item {
    id: page


    readonly property string fDot: Theme.fontDoto !== "" ? Theme.fontDoto : "monospace"
    readonly property string fMonoStr: Theme.fontMono !== "" ? Theme.fontMono : "monospace"
    readonly property string fSans: Theme.fontSans !== "" ? Theme.fontSans : "sans-serif"

    // ═══ dynamic palette ═══
    readonly property color nBlack: Theme.bg
    readonly property color nWhite: Theme.fg
    readonly property color nRed: Theme.accent
    readonly property color nDim: Theme.line
    readonly property color nSurface: Theme.surfaceHi
    readonly property color nText: Theme.nText

    readonly property var sink: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    readonly property var streams: Pipewire.nodes.values.filter(function(n) {
        return n.isStream && n.audio && n.properties
            && n.properties["media.class"] === "Stream/Output/Audio"
    })

    property bool micAvailable: false
    property bool micMuted: true
    property real micVolume: 0

    Process {
        id: micStatusProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = text.trim()
                if (out === "" || out.indexOf("Volume") === -1) {
                    page.micAvailable = false
                    page.micMuted = true
                    page.micVolume = 0
                    return
                }
                page.micAvailable = true
                page.micMuted = out.indexOf("MUTED") >= 0
                var m = out.match(/Volume:\s*([\d.]+)/)
                page.micVolume = m ? parseFloat(m[1]) : 0
            }
        }
    }

    Timer {
        id: micPollTimer
        interval: 800
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: micStatusProc.running = true
    }

    Timer {
        id: micCooldown
        interval: 220
        onTriggered: micPollTimer.restart()
    }

    function setMicVolume(v) {
        var clamped = Math.max(0, Math.min(1, v))
        page.micVolume = clamped
        if (clamped > 0 && page.micMuted) page.micMuted = false
        micPollTimer.stop()
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", clamped.toFixed(2)])
        micCooldown.restart()
    }

    function toggleMicMute() {
        page.micMuted = !page.micMuted
        micPollTimer.stop()
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
        micCooldown.restart()
    }

    component NothingSlider: ColumnLayout {
        id: slider
        property string label: ""
        property string icon: ""
        property real value: 0
        property bool muted: false
        property bool interactive: true
        signal moved(real v)
        signal iconClicked()

        spacing: 10
        opacity: interactive ? 1.0 : 0.45
        Behavior on opacity { NumberAnimation { duration: 200 } }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                color: iconHover.containsMouse ? page.nDim : page.nSurface
                border.width: 1
                border.color: slider.muted ? page.nRed : page.nDim
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: slider.icon
                    color: slider.muted ? page.nRed : page.nWhite
                    font.family: page.fMonoStr
                    font.pixelSize: 18
                }

                MouseArea {
                    id: iconHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: slider.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: slider.interactive
                    onClicked: slider.iconClicked()
                }
            }

            Text {
                Layout.fillWidth: true
                text: slider.label.toUpperCase()
                color: page.nText
                font.family: page.fSans
                font.pixelSize: 11
                font.letterSpacing: 3
                font.bold: true
            }

            Text {
                text: Math.round(slider.value * 100).toString().padStart(3, "0") + "%"
                color: slider.muted ? page.nRed : page.nWhite
                font.family: page.fDot
                font.pixelSize: 22
                font.bold: true
            }
        }

        Rectangle {
            id: track
            Layout.fillWidth: true
            Layout.preferredHeight: 14
            color: page.nSurface
            border.width: 1
            border.color: page.nDim

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, slider.value))
                height: parent.height
                color: slider.muted ? page.nRed : page.nWhite
                opacity: slider.muted ? 0.3 : 1
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Rectangle {
                x: Math.max(0, Math.min(track.width - width, track.width * Math.max(0, Math.min(1, slider.value)) - width / 2))
                width: 3
                height: parent.height + 6
                anchors.verticalCenter: parent.verticalCenter
                color: page.nRed
            }

            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -8
                anchors.bottomMargin: -8
                cursorShape: slider.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: slider.interactive
                function setFromX(mx) { slider.moved(Math.max(0, Math.min(1, mx / track.width))) }
                onPressed: (m) => setFromX(m.x)
                onPositionChanged: (m) => { if (pressed) setFromX(m.x) }
                onWheel: (w) => slider.moved(Math.max(0, Math.min(1, slider.value + (w.angleDelta.y > 0 ? 0.03 : -0.03))))
            }
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
                    text: "AUDIO"
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
                    text: streams.length + " ACTIVE"
                    color: page.nText
                    font.family: page.fMonoStr
                    font.pixelSize: 11
                    font.letterSpacing: 3
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: page.nDim }

            Text {
                text: "OUTPUT"
                color: page.nRed
                font.family: page.fSans
                font.pixelSize: 11
                font.letterSpacing: 4
                font.bold: true
            }

            NothingSlider {
                Layout.fillWidth: true
                label: "Master Volume"
                icon: (sink && !sink.muted && sink.volume > 0) ? "󰕾" : "󰖁"
                value: sink ? sink.volume : 0
                muted: sink ? sink.muted : true
                interactive: sink !== null
                onMoved: (v) => { if (sink) sink.volume = v }
                onIconClicked: if (sink) sink.muted = !sink.muted
            }

            Text {
                text: "INPUT" + (page.micAvailable ? "" : " · NO SOURCE")
                color: page.micAvailable ? page.nRed : page.nText
                font.family: page.fSans
                font.pixelSize: 11
                font.letterSpacing: 4
                font.bold: true
                Layout.topMargin: 8
            }

            NothingSlider {
                Layout.fillWidth: true
                label: page.micAvailable ? "Microphone" : "Microphone (not connected)"
                icon: !page.micAvailable
                    ? "󰍮"
                    : (page.micMuted || page.micVolume <= 0.001) ? "󰍭" : "󰍬"
                value: page.micVolume
                muted: !page.micAvailable || page.micMuted
                interactive: page.micAvailable
                onMoved: (v) => page.setMicVolume(v)
                onIconClicked: page.toggleMicMute()
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: page.nDim; Layout.topMargin: 8 }

            Text {
                text: "APPLICATIONS"
                color: page.nRed
                font.family: page.fSans
                font.pixelSize: 11
                font.letterSpacing: 4
                font.bold: true
            }

            Text {
                visible: streams.length === 0
                Layout.fillWidth: true
                Layout.topMargin: 20
                text: "▸ No applications playing audio"
                color: page.nText
                font.family: page.fMonoStr
                font.pixelSize: 13
                font.italic: true
            }

            Repeater {
                model: streams
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 80
                    color: page.nSurface
                    border.width: 1
                    border.color: page.nDim

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true

                            Rectangle {
                                Layout.preferredWidth: 6
                                Layout.preferredHeight: 6
                                radius: 3
                                color: page.nRed
                            }

                            Text {
                                Layout.fillWidth: true
                                text: (modelData.properties && modelData.properties["application.name"])
                                      ? modelData.properties["application.name"].toUpperCase()
                                      : (modelData.description || "UNKNOWN").toUpperCase()
                                color: page.nWhite
                                font.family: page.fSans
                                font.pixelSize: 12
                                font.bold: true
                                font.letterSpacing: 2
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.audio ? Math.round(modelData.audio.volume * 100).toString().padStart(3, "0") + "%" : "000%"
                                color: modelData.audio && modelData.audio.muted ? page.nRed : page.nWhite
                                font.family: page.fDot
                                font.pixelSize: 18
                                font.bold: true
                            }
                        }

                        Rectangle {
                            id: appTrack
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                            color: page.nBlack

                            Rectangle {
                                width: parent.width * (modelData.audio ? modelData.audio.volume : 0)
                                height: parent.height
                                color: modelData.audio && modelData.audio.muted ? page.nRed : page.nWhite
                                opacity: modelData.audio && modelData.audio.muted ? 0.4 : 1
                            }

                            Rectangle {
                                x: Math.max(0, Math.min(appTrack.width - width, appTrack.width * (modelData.audio ? modelData.audio.volume : 0) - width / 2))
                                width: 3
                                height: parent.height + 4
                                anchors.verticalCenter: parent.verticalCenter
                                color: page.nRed
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.topMargin: -8
                                anchors.bottomMargin: -8
                                cursorShape: Qt.PointingHandCursor
                                onClicked: (m) => { if (modelData.audio) modelData.audio.volume = Math.max(0, Math.min(1, m.x / appTrack.width)) }
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
