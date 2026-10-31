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

        // ---------- Left: Workspaces (10 per monitor) ----------
        Row {
            id: wsRow
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            readonly property var activeWs: bar.hmon ? bar.hmon.activeWorkspace : null

            readonly property int offset: (activeWs && activeWs.id > 0)
                ? Math.floor((activeWs.id - 1) / 10) * 10
                : 0
            readonly property var list: [1,2,3,4,5,6,7,8,9,10].map(function(i) { return offset + i })

            readonly property var icons: [
                "󰈹", "", "", "", "󰍩",
                "󰈙", "󰉋", "󰆍", "󰹑", "󰫔"
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
                var cur = activeWs ? activeWs.id : (offset + 1)
                var blockStart = offset + 1
                var blockEnd = offset + 10
                var next = cur + dir
                if (next < blockStart) next = blockEnd
                if (next > blockEnd) next = blockStart
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

        // ---------- Center: Active Window Title ----------
        Text {
            id: windowTitle
            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width * 0.35)
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter

            readonly property string title: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.title : ""

            visible: title !== ""
            text: title
            color: Theme.fg
            opacity: 0.8
            font.family: Theme.font
            font.pixelSize: 12
            font.bold: true

            Behavior on text {
                SequentialAnimation {
                    NumberAnimation { target: windowTitle; property: "opacity"; to: 0; duration: 100 }
                    NumberAnimation { target: windowTitle; property: "opacity"; to: 0.8; duration: 100 }
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
                icon: !Net.wifiEnabled ? Theme.iWifiOff
                      : (Net.connected !== "" ? Theme.wifiIcon(Net.activeSignal) : Theme.iWifiOff)
                tint: Net.wifiEnabled && Net.connected !== "" ? Theme.fg : Theme.dim
                onClicked: bar.togglePanel("net", bar.modelData)
            }

            BarPill {
                icon: Notifs.dnd ? Theme.iBellOff : Theme.iBell
                text: Notifs.count > 0 ? String(Notifs.count) : ""
                tint: Notifs.dnd ? Theme.dim : Theme.fg
                onClicked: bar.togglePanel("notif", bar.modelData)
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
