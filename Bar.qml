import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    signal togglePanel(string name, var scr)

    // Floating Capsule
    anchors { top: true; left: true; right: true }
    margins { top: 8; left: 20; right: 20 }
    implicitHeight: 44

    color: "transparent"
    WlrLayershell.namespace: "tzeuk-bar-nothing"

    // --- Fonts ---
    FontLoader { id: fDoto; source: "launcher/fonts/Doto[ROND,wght].ttf" }
    FontLoader { id: fMono; source: "launcher/fonts/SpaceMono-Regular.ttf" }
    FontLoader { id: fGrotesk; source: "launcher/fonts/SpaceGrotesk-Regular.otf" }

    readonly property string fDotStr: fDoto.name !== "" ? fDoto.name : "monospace"
    readonly property string fMonoStr: fMono.name !== "" ? fMono.name : "monospace"
    readonly property string fGroteskStr: fGrotesk.name !== "" ? fGrotesk.name : "sans-serif"

    // --- Nothing OS Colors ---
    readonly property color nBlack: "#000000"
    readonly property color nWhite: "#ffffff"
    readonly property color nRed: "#d71921"
    readonly property color nDim: "#333333"
    readonly property color nSurface: "#1A1A1A"

    readonly property var hmon: Hyprland.monitorFor(modelData)
    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

    // --- Battery Logic ---
    readonly property var bat: UPower.displayDevice
    readonly property bool hasBat: bat !== null

    // Calculate percentage (handle both 0-1 and 0-100 ranges)
    readonly property real batPct: {
        if (!hasBat) return 0
        var p = bat.percentage
        return p > 1 ? p / 100 : p
    }

    readonly property bool charging: hasBat && (bat.state === UPowerDeviceState.Charging)
    readonly property bool plugged: hasBat && (bat.state === UPowerDeviceState.FullyCharged)

    function getBatteryIcon() {
        if (charging || plugged) return "" // fa-plug
        if (batPct >= 0.75) return ""
        if (batPct >= 0.50) return ""
        if (batPct >= 0.25) return ""
        if (batPct >= 0.10) return ""
        return ""
    }

    // --- Background Capsule ---
    Rectangle {
        anchors.fill: parent
        radius: 22
        color: bar.nBlack
        border.width: 1
        border.color: bar.nDim
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15

        // ==========================================
        // LEFT: CIRCULAR WORKSPACES
        // ==========================================
        Row {
            id: wsRow
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            readonly property var activeWs: bar.hmon ? bar.hmon.activeWorkspace : null
            readonly property int offset: (activeWs && activeWs.id > 0) ? Math.floor((activeWs.id - 1) / 10) * 10 : 0
            readonly property var list: [1,2,3,4,5,6,7,8,9,10].map(function(i) { return offset + i })

            function find(id) {
                var l = Hyprland.workspaces.values
                for (var i = 0; i < l.length; i++) if (l[i].id === id) return l[i]
                return null
            }

            function switchTo(id) {
                Hyprland.dispatch('hl.dsp.focus({ workspace = "' + id + '" })')
            }

            function step(dir) {
                var cur = activeWs ? activeWs.id : (offset + 1)
                var next = cur + dir
                if (next < offset + 1) next = offset + 10
                if (next > offset + 10) next = offset + 1
                switchTo(next)
            }

            Repeater {
                model: wsRow.list
                delegate: Item {
                    id: wsItem
                    required property var modelData
                    readonly property var obj: wsRow.find(modelData)
                    readonly property bool active: wsRow.activeWs !== null && wsRow.activeWs.id === modelData
                    readonly property bool occupied: obj !== null && obj.toplevels.values.length > 0

                    width: 28
                    height: 28

                    Rectangle {
                        anchors.fill: parent
                        radius: 14 // Perfect circle
                        color: wsItem.active ? bar.nWhite : "transparent"
                        border.width: wsItem.active ? 0 : 1
                        border.color: wsItem.occupied ? bar.nRed : bar.nDim
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: String(wsItem.modelData)
                        color: wsItem.active ? bar.nBlack : (wsItem.occupied ? bar.nRed : bar.nDim)
                        font.family: bar.fDotStr
                        font.pixelSize: 16
                        font.bold: true
                    }

                    MouseArea {
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

        // ==========================================
        // CENTER: TIME & DATE CAPSULE
        // ==========================================
        Rectangle {
            anchors.centerIn: parent
            width: centerContent.implicitWidth + 30
            height: 28
            radius: 14
            color: bar.nSurface
            border.width: 1
            border.color: bar.nDim

            SystemClock { id: clock; precision: SystemClock.Minutes }

            Row {
                id: centerContent
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: bar.nWhite
                    font.family: bar.fGroteskStr
                    font.pixelSize: 13
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "·"
                    color: bar.nRed
                    font.family: bar.fGroteskStr
                    font.pixelSize: 16
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: Qt.formatDateTime(clock.date, "dd, MMM")
                    color: bar.nWhite
                    font.family: bar.fGroteskStr
                    font.pixelSize: 13
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // ==========================================
        // RIGHT: SYSTEM STATS
        // ==========================================
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            // 1. Notifications
            NothingBlock {
                icon: Notifs.dnd ? "󰂛" : "󰂚"
                text: Notifs.count > 0 ? String(Notifs.count) : ""

                // Turn red if DND is on OR if there are unread notifications
                active: Notifs.dnd || Notifs.count > 0

                hoverShape: "star"
                nRed: bar.nRed
                nWhite: bar.nWhite
                nDim: bar.nDim
                fMonoStr: bar.fMonoStr
                fGroteskStr: bar.fGroteskStr
                barHeight: bar.height - 8
                onClicked: bar.togglePanel("notif", bar.modelData)
            }

            // 2. Internet
            NothingBlock {
                icon: Net.connected !== "" ? "󰤨" : "󰤮"
                hoverShape: "pentagon"
                nRed: bar.nRed
                nWhite: bar.nWhite
                nDim: bar.nDim
                fMonoStr: bar.fMonoStr
                fGroteskStr: bar.fGroteskStr
                barHeight: bar.height - 8
                onClicked: bar.togglePanel("net", bar.modelData)
            }

            // 3. Volume
            NothingBlock {
                text: audio ? Math.round(audio.volume * 100) + "%" : "0%"
                icon: "󰕾"
                hoverShape: "hexagon"
                nRed: bar.nRed
                nWhite: bar.nWhite
                nDim: bar.nDim
                fMonoStr: bar.fMonoStr
                fGroteskStr: bar.fGroteskStr
                barHeight: bar.height - 8
                onClicked: bar.togglePanel("audio", bar.modelData)
            }

            // 4. Battery
            NothingBlock {
                visible: bar.hasBat
                icon: bar.getBatteryIcon()
                text: bar.hasBat ? Math.round(bar.batPct * 100) + "%" : ""
                hoverShape: "circle"
                nRed: bar.nRed
                nWhite: bar.nWhite
                nDim: bar.nDim
                fMonoStr: bar.fMonoStr
                fGroteskStr: bar.fGroteskStr
                barHeight: bar.height - 8
                onClicked: bar.togglePanel("sys", bar.modelData)
            }
        }
    }
}
