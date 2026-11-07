import QtQuick

Rectangle {
    id: r
    property string icon: ""
    signal clicked()
    implicitWidth: 48
    implicitHeight: 48
    radius: width / 2
    color: ma.containsMouse ? "#252525" : "transparent"

    Icon {
        anchors.centerIn: parent
        text: r.icon
        color: "#ffffff"
        font.pixelSize: 16
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: r.clicked()
    }
}
