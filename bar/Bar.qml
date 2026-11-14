import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../services"
import "../workspaces"
import "../themes"

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


    readonly property string fDotStr: Theme.fontDoto !== "" ? Theme.fontDoto : "monospace"
    readonly property string fMonoStr: Theme.fontMono !== "" ? Theme.fontMono : "monospace"
    readonly property string fGroteskStr: Theme.fontSans !== "" ? Theme.fontSans : "sans-serif"

    // ═══ dynamic palette ═══
    readonly property color nBlack: Theme.bg
    readonly property color nWhite: Theme.fg
    readonly property color nRed: Theme.accent
    readonly property color nDim: Theme.line
    readonly property color nSurface: Theme.surfaceHi

    readonly property var hmon: Hyprland.monitorFor(modelData)
    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

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
        interval: 5000; running: true; repeat: true
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

        Rectangle {
            id: timePill
            anchors.centerIn: parent
            width: centerContent.implicitWidth + 30
            height: 28
            radius: 14
            color: bar.nSurface
            border.width: 1
            border.color: timeHover.containsMouse ? bar.nRed : bar.nDim
            Behavior on border.color { ColorAnimation { duration: 150 } }

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

            MouseArea {
                id: timeHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: bar.togglePanel("cal", bar.modelData)
            }
        }

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
                icon: {
                    if (!audio) return "󰝟"
                    if (audio.muted) return "󰝟"
                    if (audio.volume <= 0.001) return "󰝟"
                    if (audio.volume < 0.33) return "󰕿"
                    if (audio.volume < 0.66) return "󰖀"
                    return "󰕾"
                }
                text: audio
                    ? (audio.muted ? "MUTE" : Math.round(audio.volume * 100) + "%")
                    : "—"
                active: audio ? audio.muted : false
                nRed: bar.nRed
                nWhite: bar.nWhite
                nDim: bar.nDim
                fMonoStr: bar.fMonoStr
                fGroteskStr: bar.fGroteskStr
                barHeight: bar.height - 8
                onClicked: bar.togglePanel("audio", bar.modelData)
                onWheelScrolled: (delta) => {
                    if (!bar.audio) return
                    const step = 0.05
                    const dir = delta > 0 ? 1 : -1
                    const nv = Math.max(0, Math.min(1, bar.audio.volume + dir * step))
                    bar.audio.volume = nv
                    if (dir > 0 && bar.audio.muted) bar.audio.muted = false
                }
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
