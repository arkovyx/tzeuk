import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    signal togglePanel(string name, var scr)

    anchors { top: true; left: true; right: true }
    margins { top: 6; left: 12; right: 12 }
    implicitHeight: 36
    color: "transparent"
    WlrLayershell.namespace: "tzeuk-bar"

    readonly property var hmon: Hyprland.monitorFor(modelData)
    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

    // ---------- Reusable Pill ----------
    component BarPill: Rectangle {
        id: pill
        property string icon: ""
        property string text: ""
        property color tint: Theme.fg
        signal clicked()

        implicitWidth: pillRow.implicitWidth + 16
        implicitHeight: 28
        radius: 8
        color: pillMouse.containsMouse ? Theme.surfaceHi : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 6
            Text {
                visible: pill.icon !== ""
                text: pill.icon
                color: pill.tint
                font.family: Theme.font
                font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: pill.text !== ""
                text: pill.text
                color: pill.tint
                font.family: Theme.font
                font.pixelSize: 12
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        MouseArea {
            id: pillMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }
    }

    // ---------- Background ----------
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

        // ---------- Workspaces (20 persistent) ----------
        Row {
            id: wsRow
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            readonly property var activeWs: bar.hmon ? bar.hmon.activeWorkspace : null
            readonly property var list: [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]

            readonly property var icons: [
                "󰈹", "󰅩", "󰂺", "󰒓", "󰍩",
                "󰈙", "󰉋", "󰆍", "󰂕", "󰋩"
            ]

            function find(id) {
                var l = Hyprland.workspaces.values
                for (var i = 0; i < l.length; i++)
                    if (l[i].id === id) return l[i]
                return null
            }

            function switchTo(id) {
                Hyprland.dispatch('hl.dsp.focus({ workspace = "' + id + '" })')
            }

            function step(dir) {
                var cur = activeWs ? activeWs.id : 1
                var next = cur + dir
                if (next < 1) next = 20
                if (next > 20) next = 1
                switchTo(next)
            }

            Repeater {
                model: wsRow.list
                delegate: Rectangle {
                    id: wsItem
                    required property var modelData
                    readonly property var obj: wsRow.find(modelData)
                    readonly property bool active: wsRow.activeWs !== null && wsRow.activeWs.id === modelData
                    readonly property bool occupied: obj !== null && obj.toplevels.values.length > 0

                    width: 26
                    height: 26
                    radius: 7
                    color: active ? Theme.accent
                         : (wsHover.containsMouse ? Theme.surfaceHi : "transparent")
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: wsRow.icons[(wsItem.modelData - 1) % 10]
                        color: wsItem.active ? Theme.bg
                             : wsItem.occupied ? Theme.fg
                             : Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: wsHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wsRow.switchTo(wsItem.modelData)
                        onWheel: function(w) {
                            wsRow.step(w.angleDelta.y > 0 ? -1 : 1)
                        }
                    }
                }
            }
        }

        // ---------- Right Side ----------
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            SystemClock { id: clock; precision: SystemClock.Minutes }

            BarPill {
                icon: (audio && !audio.muted && audio.volume > 0) ? Theme.iVolHigh : Theme.iVolOff
                text: audio ? Math.round(audio.volume * 100) + "%" : "—"
                onClicked: bar.togglePanel("audio", bar.modelData)
            }

            BarPill {
                icon: Theme.iCal
                text: Qt.formatDateTime(clock.date, "dd MMM")
                onClicked: bar.togglePanel("cal", bar.modelData)
            }

            BarPill {
                icon: Theme.iClock
                text: Qt.formatDateTime(clock.date, "HH:mm")
                onClicked: {}
            }
        }
    }
}
