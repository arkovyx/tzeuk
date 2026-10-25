import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    margins { top: 6; left: 12; right: 12 }
    implicitHeight: 36
    color: "transparent"
    WlrLayershell.namespace: "tzeuk-bar"

    readonly property var hmon: Hyprland.monitorFor(modelData)

    // Background
    Rectangle {
        anchors.fill: parent
        color: Theme.barBg
        radius: 16
        border.width: 1
        border.color: Theme.line
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        // --- Workspaces ---
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            readonly property var activeWs: bar.hmon ? bar.hmon.activeWorkspace : null
            readonly property int offset: activeWs && activeWs.id > 0 ? Math.floor((activeWs.id - 1) / 10) * 10 : 0
            readonly property var list: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(function (i) { return offset + i })

            function find(id) {
                var l = Hyprland.workspaces.values
                for (var i = 0; i < l.length; i++) if (l[i].id === id) return l[i]
                return null
            }

            function step(dir) {
                var cur = activeWs ? activeWs.id : offset + 1
                for (var id = cur + dir; id >= offset + 1 && id <= offset + 10; id += dir) {
                    var o = find(id)
                    if (o !== null && o.toplevels.values.length > 0) {
                        Hyprland.dispatch('hl.dsp.focus({ workspace = "' + id + '" })')
                        return
                    }
                }
            }

            // Your exact Waybar icons
            readonly property var icons: [
                "󰈹", "", "󰂺", "󰒓", "󰍩", "󰈙", "󰉋", "󰆍", "󰂕", "󰎄"
            ]

            Repeater {
                model: parent.list
                delegate: Rectangle {
                    required property var modelData
                    readonly property var obj: parent.find(modelData)
                    readonly property bool active: parent.activeWs !== null && parent.activeWs.id === modelData
                    readonly property bool occupied: obj !== null && obj.toplevels.values.length > 0

                    width: 28
                    height: 28
                    radius: 8
                    color: active ? Theme.accent : (m.containsMouse ? Theme.surfaceHi : "transparent")
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: parent.icons[(modelData - 1) % 10]
                        color: parent.active ? Theme.bg : (parent.occupied ? Theme.fg : Theme.surfaceHi)
                        font.family: Theme.font
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: m
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch('hl.dsp.focus({ workspace = "' + modelData + '" })')
                        onWheel: w => parent.step(w.angleDelta.y > 0 ? -1 : 1)
                    }
                }
            }
        }
    }
}
