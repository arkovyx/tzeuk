import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../themes"
import "../services"
import "../powermenu"
import "../glyphs"

PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "tzeuk-desktop"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property var hmon: Hyprland.monitorFor(modelData)
    readonly property bool home: hmon && hmon.activeWorkspace
        ? hmon.activeWorkspace.toplevels.values.length === 0
        : true

    readonly property string iMusic: Theme.cp(0xF075A)
    readonly property string iPause: Theme.cp(0xF03E4)
    readonly property bool blinkOn: true

    // ── NEUTRAL SAFE COLOR (readable on any wallpaper) ──
    readonly property color neutral:     "#B8B8B8"
    readonly property color neutralDim:  "#7A7A7A"

    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property var player: MediaPlayer.player

    property bool dim: false
    Timer {
        running: win.home && win.blinkOn
        interval: 500
        repeat: true
        onTriggered: win.dim = !win.dim
    }

    Column {
        x: 48
        y: 76
        spacing: 2

        // Time — pywal accent (dynamic)
        Row {
            Num { text: Qt.formatDateTime(clock.date, "HH"); font.pixelSize: 96; color: Theme.accent; font.variableAxes: { "ROND": 100 } }
            Num { text: ":"; font.pixelSize: 96; color: Theme.accent; font.variableAxes: { "ROND": 100 } }
            Num { text: Qt.formatDateTime(clock.date, "mm"); font.pixelSize: 96; color: Theme.accent; font.variableAxes: { "ROND": 100 } }
        }

        // Date — neutral dash + neutral text
        Row {
            topPadding: 14
            spacing: 12
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 2
                color: win.neutral
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.locale("en_US").toString(clock.date, "dddd · d MMMM").toUpperCase()
                color: win.neutral
                font.family: Theme.fontMono
                font.pixelSize: 16
                font.letterSpacing: 1.5
            }
        }

        // Underline
        Item {
            width: 56
            height: 5
            Rectangle {
                width: 56
                height: 1
                y: 4
                color: win.neutralDim
            }
        }

        Item { width: 1; height: 14 }

        // Stats — neutral
        Row {
            spacing: 22

            Row {
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.iCpu
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: win.neutral
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(SysStats.cpu * 100) + "%"
                    color: win.neutral
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                }
            }

            Row {
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.iMem
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: win.neutral
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: SysStats.fmtSize(SysStats.memUsed) + " / " + SysStats.fmtSize(SysStats.memTotal)
                    color: win.neutral
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                }
            }

            Row {
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.iClock
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: win.neutral
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "up " + SysStats.fmtTime(SysStats.uptime)
                    color: win.neutral
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                }
            }
        }

        // Music — neutral
        Row {
            topPadding: 8
            spacing: 10
            visible: win.player !== null && (win.player.trackTitle || "") !== ""
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: win.player && win.player.isPlaying ? win.iMusic : win.iPause
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                color: win.neutral
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: win.player
                    ? win.player.trackTitle + (win.player.trackArtist ? "  ·  " + win.player.trackArtist : "")
                    : ""
                color: win.neutral
                font.family: Theme.fontSans
                font.pixelSize: 15
            }
        }
    }

    // Cava viz — pywal accent (dynamic)
    Row {
        id: viz
        visible: Cava.available && win.home
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        anchors.horizontalCenter: parent.horizontalCenter

        readonly property int rows: 14
        readonly property real d: 6
        readonly property real gap: Math.max(2, (win.width - 72) / Cava.bars - d)

        spacing: gap

        Repeater {
            model: Cava.bars
            delegate: Column {
                required property int index
                readonly property real v: index < Cava.values.length ? Cava.values[index] : 0
                readonly property int lit: Math.round(v * viz.rows)
                spacing: 4
                Repeater {
                    model: viz.rows
                    Rectangle {
                        required property int index
                        readonly property int up: viz.rows - index
                        width: viz.d
                        height: viz.d
                        radius: viz.d / 2
                        color: up === parent.lit
                            ? Theme.accent
                            : up < parent.lit
                                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)
                                : Qt.rgba(Theme.s3.r, Theme.s3.g, Theme.s3.b, 0.5)
                    }
                }
            }
        }
    }
}
