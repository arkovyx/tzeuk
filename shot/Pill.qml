import QtQuick
import "../themes"

Rectangle {
    default property alias content: row.data
    property alias spacing: row.spacing
    property real pad: 10

    width: row.width + pad * 2
    height: 56
    radius: height / 2
    color: Theme.surfaceHi
    border { width: 1; color: Theme.line }

    MouseArea { anchors.fill: parent }
    Row { id: row; anchors.centerIn: parent }
}
