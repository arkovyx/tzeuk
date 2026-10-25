import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: win
    property bool opened: false

    visible: opened
    anchors { top: true; right: true }
    margins { top: 50; right: 12 } // Just below the bar
    implicitWidth: 400
    implicitHeight: 500
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tzeuk-panel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    HyprlandFocusGrab {
        windows: [win]
        active: win.opened
        onCleared: win.opened = false
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.barBg
        radius: 16
        border.width: 1
        border.color: Theme.line

        Text {
            anchors.centerIn: parent
            text: "Main Panel (Empty for now)"
            color: Theme.fg
            font.family: Theme.font
        }
    }
}
