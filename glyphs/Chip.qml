import QtQuick

Rectangle {
    id: r
    property string text: ""
    property bool selected: false
    property bool filled: false
    property int px: 12
    signal clicked()

    implicitWidth: label.implicitWidth + px * 2
    height: 32
    radius: 16
    color: r.selected ? "#ffffff"
         : ma.containsMouse ? "#252525"
         : r.filled ? "#171717"
         : "transparent"

    Text {
        id: label
        anchors.centerIn: parent
        text: r.text
        color: r.selected ? "#000000" : "#ffffff"
        font.family: "Space Grotesk"
        font.pixelSize: 13
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: r.clicked()
    }
}
