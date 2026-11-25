import QtQuick
import "../themes"

Rectangle {
    property alias text: lb.text
    property bool on
    signal clicked

    width: lb.width + 32
    height: 36
    radius: 18
    color: on ? Theme.fg : "transparent"
    Behavior on color { ColorAnimation { duration: 150 } }

    Text {
        id: lb; anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 11
        color: parent.on ? Theme.bg : Theme.nText
    }
    TapHandler { onTapped: parent.clicked() }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
