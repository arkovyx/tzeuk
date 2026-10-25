import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    margins { top: 6; left: 12; right: 12 }
    implicitHeight: 36
    color: "transparent"
    WlrLayershell.namespace: "tzeuk-bar"

    // The visual background
    Rectangle {
        anchors.fill: parent
        color: Theme.barBg
        radius: 16
        border.width: 1
        border.color: Theme.line
    }
}
