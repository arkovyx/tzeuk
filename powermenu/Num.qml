import QtQuick

Item {
    id: root
    property alias font: txt.font
    property alias color: txt.color
    property string text: ""
    property int topPadding: 0
    property int bottomPadding: 0
    readonly property real lead: 0

    implicitWidth: txt.implicitWidth
    implicitHeight: txt.implicitHeight + topPadding + bottomPadding
    width: implicitWidth
    height: implicitHeight

    Text {
        id: txt
        y: root.topPadding
        text: root.text
        color: root.color
        font.family: "Doto"
        font.weight: Font.Black
    }
}
