import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: win
    property bool opened: false
    property bool grabActive: false

    visible: opened
    anchors { top: true; right: true }
    margins { top: 50; right: 12 }
    implicitWidth: 400
    implicitHeight: 500
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tzeuk-panel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Delay the focus grab so the panel has time to gain focus before
    // the grab watches for focus loss (prevents instant onCleared).
    onOpenedChanged: {
        if (opened) {
            grabDelay.start()
        } else {
            grabActive = false
        }
    }

    Timer {
        id: grabDelay
        interval: 150
        onTriggered: win.grabActive = win.opened
    }

    HyprlandFocusGrab {
        windows: [win]
        active: win.grabActive
        onCleared: win.opened = false
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.barBg
        radius: 16
        border.width: 2
        border.color: Theme.accent

        focus: true
        Keys.onEscapePressed: win.opened = false

        Column {
            anchors.centerIn: parent
            spacing: 12

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "TZEUK PANEL"
                color: Theme.accent
                font.family: Theme.font
                font.pixelSize: 22
                font.bold: true
                font.letterSpacing: 3
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Tabs coming soon..."
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 14
            }
        }
    }
}
