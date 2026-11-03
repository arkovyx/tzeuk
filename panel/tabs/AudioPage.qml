import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: page

    readonly property var sink: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    readonly property var source: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio : null

    // Only show output streams (apps playing audio)
    readonly property var streams: Pipewire.nodes.values.filter(function(n) {
        return n.isStream && n.audio && n.properties
            && n.properties["media.class"] === "Stream/Output/Audio"
    })

    // ---- Reusable Slider Component (inline, no extra file) ----
    component AudioSlider: RowLayout {
        id: sliderRow
        property string icon: ""
        property real value: 0
        property bool muted: false
        property string valueText: Math.round(value * 100) + "%"
        signal moved(real v)
        signal iconClicked()

        spacing: 12

        // Icon (click to toggle mute)
        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: 8
            color: iconMouse.containsMouse ? Theme.surfaceHi : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: sliderRow.icon
                color: sliderRow.muted ? Theme.dim : Theme.accent
                font.family: Theme.font
                font.pixelSize: 16
            }
            MouseArea {
                id: iconMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sliderRow.iconClicked()
            }
        }

        // Track + Knob
        Rectangle {
            id: track
            Layout.fillWidth: true
            Layout.preferredHeight: 8
            radius: 4
            color: Theme.surfaceHi

            // Filled portion
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, sliderRow.value))
                height: parent.height
                radius: 4
                color: sliderRow.muted ? Theme.dim : Theme.accent
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            // Knob
            Rectangle {
                x: Math.max(0, Math.min(track.width - width,
                        track.width * Math.max(0, Math.min(1, sliderRow.value)) - width / 2))
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 14
                radius: 7
                color: Theme.fg
                border.width: 2
                border.color: sliderRow.muted ? Theme.dim : Theme.accent
            }

            // Drag / Scroll / Click area
            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -10
                anchors.bottomMargin: -10
                cursorShape: Qt.PointingHandCursor

                function setFromX(mx) {
                    sliderRow.moved(Math.max(0, Math.min(1, mx / track.width)))
                }
                onPressed: (mouse) => setFromX(mouse.x)
                onPositionChanged: (mouse) => { if (pressed) setFromX(mouse.x) }
                onWheel: (w) => {
                    var delta = w.angleDelta.y > 0 ? 0.02 : -0.02
                    sliderRow.moved(Math.max(0, Math.min(1, sliderRow.value + delta)))
                }
            }
        }

        // Value
        Text {
            Layout.preferredWidth: 44
            horizontalAlignment: Text.AlignRight
            text: sliderRow.valueText
            color: sliderRow.muted ? Theme.dim : Theme.fg
            font.family: Theme.font
            font.pixelSize: 12
            font.bold: true
        }
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
            spacing: 20

            Text {
                text: "AUDIO"
                color: Theme.accent
                font.family: Theme.font
                font.pixelSize: 16
                font.bold: true
                font.letterSpacing: 3
            }

            // ---------- Output ----------
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "OUTPUT"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 2
                }

                AudioSlider {
                    Layout.fillWidth: true
                    icon: (page.sink && !page.sink.muted && page.sink.volume > 0) ? Theme.iVolHigh : Theme.iVolOff
                    value: page.sink ? page.sink.volume : 0
                    muted: page.sink ? page.sink.muted : true
                    onMoved: (v) => { if (page.sink) page.sink.volume = v }
                    onIconClicked: if (page.sink) page.sink.muted = !page.sink.muted
                }
            }

            // ---------- Input ----------
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "INPUT"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 2
                }

                AudioSlider {
                    Layout.fillWidth: true
                    icon: (page.source && !page.source.muted) ? "󰍬" : "󰍭"
                    value: page.source ? page.source.volume : 0
                    muted: page.source ? page.source.muted : true
                    onMoved: (v) => { if (page.source) page.source.volume = v }
                    onIconClicked: if (page.source) page.source.muted = !page.source.muted
                }
            }

            // ---------- Divider ----------
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.line
            }

            // ---------- Applications ----------
            Text {
                text: "APPLICATIONS"
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 2
            }

            Text {
                visible: page.streams.length === 0
                Layout.fillWidth: true
                text: "No applications playing audio"
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 11
                font.italic: true
            }

            Repeater {
                model: page.streams
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: (modelData.properties && modelData.properties["application.name"])
                              ? modelData.properties["application.name"]
                              : (modelData.description || "Unknown App")
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    AudioSlider {
                        Layout.fillWidth: true
                        icon: (modelData.audio && !modelData.audio.muted && modelData.audio.volume > 0) ? Theme.iVolHigh : Theme.iVolOff
                        value: modelData.audio ? modelData.audio.volume : 0
                        muted: modelData.audio ? modelData.audio.muted : true
                        onMoved: (v) => { if (modelData.audio) modelData.audio.volume = v }
                        onIconClicked: if (modelData.audio) modelData.audio.muted = !modelData.audio.muted
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
