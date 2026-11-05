import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../services"
import "../workspaces"

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    signal togglePanel(string name, var scr)

    anchors { top: true; left: true; right: true }
    margins { top: 8; left: 20; right: 20 }
    implicitHeight: 44
    color: "transparent"
    WlrLayershell.namespace: "tzeuk-bar-nothing"

    FontLoader { id: fDoto; source: "../fonts/Doto.ttf" }
    FontLoader { id: fMono; source: "../fonts/SpaceMono-Regular.ttf" }
    FontLoader { id: fGrotesk; source: "../fonts/SpaceGrotesk-Regular.otf" }

    readonly property string fDotStr: fDoto.name !== "" ? fDoto.name : "monospace"
    readonly property string fMonoStr: fMono.name !== "" ? fMono.name : "monospace"
    readonly property string fGroteskStr: fGrotesk.name !== "" ? fGrotesk.name : "sans-serif"

    readonly property color nBlack: "#000000"
    readonly property color nWhite: "#ffffff"
    readonly property color nRed: "#d71921"
    readonly property color nDim: "#333333"
    readonly property color nSurface: "#1A1A1A"

    readonly property var hmon: Hyprland.monitorFor(modelData)
    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

    // Battery via sysfs
    property real batPct: 0
    property bool charging: false
    property bool plugged: false
    property bool hasBat: false

    Process {
        id: batPctProc
        command: ["sh", "-c", "for d in /sys/class/power_supply/BAT*; do [ -f \"$d/capacity\" ] && cat \"$d/capacity\" && exit; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var p = parseInt(text.trim())
                if (!isNaN(p) && p >= 0) {
                    bar.batPct = p / 100
                    bar.hasBat = true
                }
            }
        }
    }

    Process {
        id: batStateProc
        command: ["sh", "-c", "for d in /sys/class/power_supply/BAT*; do [ -f \"$d/status\" ] && cat \"$d/status\" && exit; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var s = text.trim()
                bar.charging = (s === "Charging")
                bar.plugged = (s === "Full")
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            batPctProc.running = false; batStateProc.running = false
            batPctProc.running = true; batStateProc.running = true
        }
    }

    function getBatteryIcon() {
        if (charging || plugged) return "\uf1e6"
        if (batPct >= 0.75) return "\uf240"
        if (batPct >= 0.50) return "\uf241"
        if (batPct >= 0.25) return "\uf242"
        if (batPct >= 0.10) return "\uf243"
        return "\uf244"
    }

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

        // LEFT: Workspaces (extracted component)
        Workspaces {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            hmon: bar.hmon
            colWhite: bar.nWhite
            colDim: bar.nDim
            colRed: bar.nRed
            colBlack: bar.nBlack
            fontDot: bar.fDotStr
            rowHeight: 28
        }

        // CENTER: Time & Date
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

        // RIGHT: System Stats
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            NothingBlock {
                icon: Notifs.dnd ? "󰂛" : "󰂚"
                text: Notifs.count > 0 ? String(Notifs.count) : ""
                active: Notifs.dnd || Notifs.count > 0
                nRed: bar.nRed
                nWhite: bar.nWhite
                nDim: bar.nDim
                fMonoStr: bar.fMonoStr
                fGroteskStr: bar.fGroteskStr
                barHeight: bar.height - 8
                onClicked: bar.togglePanel("notif", bar.modelData)
            }

            NothingBlock {
                icon: Net.connected !== "" ? "󰤨" : "󰤮"
                nRed: bar.nRed
                nWhite: bar.nWhite
                nDim: bar.nDim
                fMonoStr: bar.fMonoStr
                fGroteskStr: bar.fGroteskStr
                barHeight: bar.height - 8
                onClicked: bar.togglePanel("net", bar.modelData)
            }

            NothingBlock {
                text: audio ? Math.round(audio.volume * 100) + "%" : "0%"
                icon: "󰕾"
                nRed: bar.nRed
                nWhite: bar.nWhite
                nDim: bar.nDim
                fMonoStr: bar.fMonoStr
                fGroteskStr: bar.fGroteskStr
                barHeight: bar.height - 8
                onClicked: bar.togglePanel("audio", bar.modelData)
            }

            NothingBlock {
                visible: bar.hasBat
                icon: bar.getBatteryIcon()
                text: bar.hasBat ? Math.round(bar.batPct * 100) + "%" : ""
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
