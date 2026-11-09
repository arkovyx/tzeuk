import QtQuick

Item {
    id: block
    property string text: ""
    property string icon: ""
    property bool active: false

    property color nRed: "#d71921"
    property color nWhite: "#ffffff"
    property color nDim: "#555555"

    property string fMonoStr: "monospace"
    property string fGroteskStr: "sans-serif"
    property string fIconStr: "JetBrainsMono Nerd Font"
    property real barHeight: 36

    signal clicked()

    implicitWidth: Math.max(blockRow.implicitWidth + 24, 36)
    implicitHeight: barHeight

    Rectangle {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height - 8
        radius: 8
        color: block.nDim
        opacity: mouse.containsMouse ? 0.3 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Row {
        id: blockRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: block.icon !== ""
            text: block.icon
            color: block.active ? block.nRed : block.nWhite
            font.family: block.fIconStr
            font.pixelSize: 15
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: block.text !== ""
            text: block.text.toUpperCase()
            color: block.active ? block.nRed : block.nWhite
            font.family: block.fGroteskStr
            font.pixelSize: 12
            font.bold: true
            font.letterSpacing: 1
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: block.clicked()
    }
}
