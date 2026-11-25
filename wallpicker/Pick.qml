import QtQuick

import "../themes"

// row of pills: label + options, one selected
Row {
    id: root

    property string label
    property var opts: []
    property int cur: 0
    signal picked(int i)

    spacing: 8
    readonly property string fMono: Theme.fontMono !== "" ? Theme.fontMono : "monospace"

    Text {
        anchors.verticalCenter: parent.verticalCenter
        rightPadding: 8
        text: root.label
        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.5)
        font { family: root.fMono; pixelSize: 12; letterSpacing: 12 * 0.14; capitalization: Font.AllUppercase }
    }
    Repeater {
        model: root.opts
        Rectangle {
            id: pill
            required property string modelData
            required property int index
            readonly property bool on: index === root.cur
            height: 30
            width: txt.implicitWidth + 28
            radius: 15
            color: on ? Theme.fg : hov.hovered ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.14) : "transparent"
            border.width: on ? 0 : 1
            border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.3)

            Text {
                id: txt
                anchors.centerIn: parent
                text: pill.modelData
                color: pill.on ? Theme.bg : Theme.fg
                font { family: root.fMono; pixelSize: 11; letterSpacing: 1.5; capitalization: Font.AllUppercase }
            }
            HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.picked(pill.index) }
        }
    }
}
