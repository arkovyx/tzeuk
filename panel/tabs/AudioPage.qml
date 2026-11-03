import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

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

    readonly property var sink: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    readonly property var source: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio : null
    readonly property var streams: Pipewire.nodes.values.filter(function(n) {
        return n.isStream && n.audio && n.properties
            && n.properties["media.class"] === "Stream/Output/Audio"
    })

    component NothingSlider: ColumnLayout {
        id: slider
        property string label: ""
        property string icon: ""
        property real value: 0
        property bool muted: false
        signal moved(real v)
        signal iconClicked()

        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Icon button
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
                    cursorShape: Qt.PointingHandCursor
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

        // Slider track
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

            // Red indicator line
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
                cursorShape: Qt.PointingHandCursor
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

            // Header
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

            // Output
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
                onMoved: (v) => { if (sink) sink.volume = v }
                onIconClicked: if (sink) sink.muted = !sink.muted
            }

            // Input
            Text {
                text: "INPUT"
                color: page.nRed
                font.family: page.fSans
                font.pixelSize: 11
                font.letterSpacing: 4
                font.bold: true
                Layout.topMargin: 8
            }

            NothingSlider {
                Layout.fillWidth: true
                label: "Microphone"
                icon: (source && !source.muted) ? "󰍬" : "󰍭"
                value: source ? source.volume : 0
                muted: source ? source.muted : true
                onMoved: (v) => { if (source) source.volume = v }
                onIconClicked: if (source) source.muted = !source.muted
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: page.nDim; Layout.topMargin: 8 }

            // Applications
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

                        // Slider
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
