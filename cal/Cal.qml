import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../themes"
import "../glyphs"

// Calendar + focus timer (ported from glyph Cal.qml). Drops down from the top bar, centered.
//   month grid 7x6 (Mon first, today = filled circle), arrows / ←→ change month, click month title = back to today
//   focus timer: dot ring fills clockwise, presets, start/pause/resume (Space), reset. Keeps running when closed;
//   a notification is sent when it finishes.
//   Esc or click outside = close.
// Driven by shell.qml: opened / screen / closeRequested(), opened by the bar clock (togglePanel "cal") or IPC.
Scope {
    id: cal

    property bool opened: false
    property var screen: null
    signal closeRequested
    property int shift: 0          // months from current
    property int topGap: 64        // distance from screen top to the panel: set to bar height + gap
    property int panelWidth: 380

    function close() { closeRequested() }
    onOpenedChanged: {
        if (opened) {
            shift = 0
            Qt.callLater(() => panel.forceActiveFocus())
        }
    }

    // ── look ──
    readonly property string fDot:  Theme.fontDoto !== "" ? Theme.fontDoto : "monospace"
    readonly property string fMono: Theme.fontMono !== "" ? Theme.fontMono : "monospace"
    function dim(a) { return Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, a) }

    // ── calendar state ──
    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property var en: Qt.locale("en_US")
    readonly property var month: new Date(clock.date.getFullYear(), clock.date.getMonth() + shift, 1)
    readonly property int lead: (month.getDay() + 6) % 7   // days of the previous month before Monday

    // ── focus timer ──
    property int pomMin: 25
    property int pomLeft: 25 * 60
    property bool pomRun: false
    property bool pomPause: false
    property real pomEnd: 0
    readonly property real pomF: (pomRun || pomPause) ? 1 - pomLeft / (pomMin * 60) : 0

    function mmss(s) {
        return String(Math.floor(s / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0")
    }
    function pomSet(m) {
        pomRun = false
        pomPause = false
        pomMin = m
        pomLeft = m * 60
    }
    function pomToggle() {
        if (pomRun) {
            pomRun = false
            pomPause = true
        } else {
            pomEnd = Date.now() + pomLeft * 1000
            pomPause = false
            pomRun = true
        }
    }
    function pomReset() {
        pomRun = false
        pomPause = false
        pomLeft = pomMin * 60
    }
    Timer {
        interval: 250
        repeat: true
        running: cal.pomRun
        onTriggered: {
            const left = Math.max(0, Math.ceil((cal.pomEnd - Date.now()) / 1000))
            cal.pomLeft = left
            if (left <= 0) {
                cal.pomRun = false
                cal.pomPause = false
                cal.pomLeft = cal.pomMin * 60
                Quickshell.execDetached(["notify-send", "-a", "Focus", "Focus session finished", cal.pomMin + " min"])
            }
        }
    }

    // ── window ──
    PanelWindow {
        id: win

        screen: cal.screen

        property real t: cal.opened ? 1 : 0
        Behavior on t { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] } }

        visible: t > 0
        anchors { left: true; right: true; top: true; bottom: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: cal.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "tzeuk-cal"

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.30 * win.t
            MouseArea { anchors.fill: parent; onClicked: cal.close() }
        }

        Rectangle {
            id: panel
            x: (parent.width - width) / 2
            y: cal.topGap - 24 * (1 - win.t)
            width: cal.panelWidth
            height: col.height + 48
            opacity: win.t
            radius: 28
            color: Theme.bg
            border.width: 1
            border.color: cal.dim(0.25)
            focus: true

            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape) cal.close()
                else if (e.key === Qt.Key_Left) cal.shift--
                else if (e.key === Qt.Key_Right) cal.shift++
                else if (e.key === Qt.Key_Space) cal.pomToggle()
                else return
                e.accepted = true
            }

            MouseArea { anchors.fill: parent }   // clicks on the panel do not close it

            Column {
                id: col
                x: 24
                y: 24
                width: parent.width - 48
                spacing: 14

                // month header
                Item {
                    width: parent.width
                    height: 40

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: cal.en.standaloneMonthName(cal.month.getMonth(), Locale.ShortFormat)
                            color: Theme.fg
                            font { family: cal.fDot; pixelSize: 40; weight: Font.Black; variableAxes: ({ "ROND": 100, "wght": 900 }) }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: cal.month.getFullYear()
                            color: cal.dim(0.5)
                            font { family: cal.fMono; pixelSize: 12; letterSpacing: 12 * 0.14 }
                        }
                        TapHandler { onTapped: cal.shift = 0 }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                    Row {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: 8
                        Round { kind: "prev"; onClicked: cal.shift-- }
                        Round { kind: "next"; onClicked: cal.shift++ }
                    }
                }

                // weekday header + days
                Grid {
                    width: parent.width
                    columns: 7

                    Repeater {
                        model: ["M", "T", "W", "T", "F", "S", "S"]
                        Text {
                            required property string modelData
                            width: col.width / 7
                            height: 24
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: modelData
                            color: cal.dim(0.5)
                            font { family: cal.fMono; pixelSize: 11 }
                        }
                    }
                    Repeater {
                        model: 42
                        Item {
                            id: day
                            required property int index
                            readonly property var d: new Date(cal.month.getFullYear(), cal.month.getMonth(), index - cal.lead + 1)
                            readonly property bool own: d.getMonth() === cal.month.getMonth()
                            readonly property bool today: d.toDateString() === clock.date.toDateString()
                            width: col.width / 7
                            height: 38

                            Rectangle {
                                anchors.centerIn: parent
                                visible: day.today
                                width: 32; height: 32; radius: 16
                                color: Theme.fg
                            }
                            Text {
                                anchors.centerIn: parent
                                text: day.d.getDate()
                                font { family: cal.fMono; pixelSize: 13 }
                                color: day.today ? Theme.bg
                                    : !day.own ? cal.dim(0.25)
                                    : day.index % 7 > 4 ? cal.dim(0.55)
                                    : Theme.fg
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: cal.dim(0.15) }

                // focus timer
                Row {
                    spacing: 20

                    Item {
                        width: 136
                        height: 136

                        DotRing { anchors.fill: parent; n: 40; dot: 5; f: cal.pomF }
                        Column {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: cal.mmss(cal.pomLeft)
                                color: Theme.fg
                                font { family: cal.fDot; pixelSize: 30; weight: Font.Black; variableAxes: ({ "ROND": 100, "wght": 900 }) }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: cal.pomRun ? "focus" : cal.pomPause ? "paused" : "ready"
                                color: cal.pomRun ? Theme.fg : cal.dim(0.5)
                                font { family: cal.fMono; pixelSize: 10; letterSpacing: 10 * 0.14; capitalization: Font.AllUppercase }
                            }
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14

                        Text {
                            text: "focus · min"
                            color: cal.dim(0.5)
                            font { family: cal.fMono; pixelSize: 11; letterSpacing: 11 * 0.14; capitalization: Font.AllUppercase }
                        }
                        Row {
                            spacing: 8
                            Repeater {
                                model: [15, 25, 45, 60]
                                Rectangle {
                                    id: chip
                                    required property int modelData
                                    readonly property bool on: cal.pomMin === modelData
                                    width: 38; height: 38; radius: 19
                                    color: on ? Theme.fg : chipHov.hovered ? cal.dim(0.18) : cal.dim(0.10)
                                    Text {
                                        anchors.centerIn: parent
                                        text: chip.modelData
                                        color: chip.on ? Theme.bg : Theme.fg
                                        font { family: cal.fMono; pixelSize: 12 }
                                    }
                                    HoverHandler { id: chipHov; cursorShape: Qt.PointingHandCursor }
                                    TapHandler { onTapped: cal.pomSet(chip.modelData) }
                                }
                            }
                        }
                        Row {
                            spacing: 10
                            Rectangle {
                                width: 118; height: 40; radius: 20
                                color: cal.pomRun ? cal.dim(0.10) : Theme.fg
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Round {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 18; height: 18; radius: 9
                                        color: "transparent"
                                        hoverable: false
                                        kind: cal.pomRun ? "pause" : "play"
                                        ink: cal.pomRun ? Theme.fg : Theme.bg
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: cal.pomRun ? "pause" : cal.pomPause ? "resume" : "start"
                                        color: cal.pomRun ? Theme.fg : Theme.bg
                                        font { family: cal.fMono; pixelSize: 12; letterSpacing: 12 * 0.14; capitalization: Font.AllUppercase }
                                    }
                                }
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: cal.pomToggle() }
                            }
                            Round {
                                kind: "reset"
                                opacity: cal.pomRun || cal.pomPause ? 1 : 0.4
                                onClicked: cal.pomReset()
                            }
                        }
                    }
                }
            }
        }
    }
}
