import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: win
    property bool opened: false
    property bool grabActive: false
    signal closeRequested()

    visible: opened
    anchors { top: true; right: true }
    margins { top: 56; right: 12 } // Right under the calendar pill
    implicitWidth: 340
    implicitHeight: 400
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tzeuk-calendar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    onOpenedChanged: {
        if (opened) {
            grabDelay.start()
            today()
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
        onCleared: win.closeRequested()
    }

    // --- State ---
    SystemClock { id: sysClock; precision: SystemClock.Seconds }

    property int year: 0
    property int month: 0 // 0..11

    function today() {
        var d = new Date()
        year = d.getFullYear()
        month = d.getMonth()
    }

    function shift(n) {
        var m = month + n
        year += Math.floor(m / 12)
        month = ((m % 12) + 12) % 12
    }

    function isoWeek(d) {
        var t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        var day = t.getUTCDay() || 7
        t.setUTCDate(t.getUTCDate() + 4 - day)
        var y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1))
        return Math.ceil(((t - y0) / 86400000 + 1) / 7)
    }

    readonly property var days: {
        var first = new Date(year, month, 1)
        var start = new Date(year, month, 1 - ((first.getDay() + 6) % 7))
        var out = []
        for (var i = 0; i < 42; i++)
            out.push(new Date(start.getFullYear(), start.getMonth(), start.getDate() + i))
        return out
    }

    readonly property var now: sysClock.date

    // --- UI ---
    Item {
        anchors.fill: parent
        scale: win.opened ? 1.0 : 0.95
        opacity: win.opened ? 1.0 : 0.0
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

        Rectangle {
            anchors.fill: parent
            color: Theme.bg
            opacity: 0.95
            radius: 16
            border.width: 1
            border.color: Theme.line

            focus: true
            Keys.onEscapePressed: win.closeRequested()
            Keys.onLeftPressed: win.shift(-1)
            Keys.onRightPressed: win.shift(1)
            Keys.onSpacePressed: win.today()

            // Scroll to change month
            MouseArea {
                anchors.fill: parent
                onWheel: w => win.shift(w.angleDelta.y > 0 ? -1 : 1)
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                // Big Clock
                Text {
                    Layout.fillWidth: true
                    text: Qt.formatDateTime(win.now, "HH:mm:ss")
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 32
                    font.bold: true
                }

                // Date
                Text {
                    Layout.fillWidth: true
                    text: Qt.formatDateTime(win.now, "dddd, d MMMM yyyy")
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 1
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.line
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                }

                // Month Navigation
                RowLayout {
                    Layout.fillWidth: true

                    Rectangle {
                        width: 24; height: 24; radius: 6
                        color: prevHover.containsMouse ? Theme.surfaceHi : "transparent"
                        Text { anchors.centerIn: parent; text: "󰅁"; color: Theme.fg; font.family: Theme.font }
                        MouseArea { id: prevHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.shift(-1) }
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.formatDate(new Date(win.year, win.month, 1), "MMMM yyyy").toUpperCase()
                        color: Theme.accent
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 2
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.today() }
                    }

                    Rectangle {
                        width: 24; height: 24; radius: 6
                        color: nextHover.containsMouse ? Theme.surfaceHi : "transparent"
                        Text { anchors.centerIn: parent; text: "󰅂"; color: Theme.fg; font.family: Theme.font }
                        MouseArea { id: nextHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.shift(1) }
                    }
                }

                // Weekdays Header
                GridLayout {
                    Layout.fillWidth: true
                    columns: 8
                    columnSpacing: 0
                    rowSpacing: 4

                    Repeater {
                        model: ["wk", "mo", "tu", "we", "th", "fr", "sa", "su"]
                        delegate: Text {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: index === 0 ? Theme.line : (index >= 6 ? Theme.accent : Theme.dim)
                            font.family: Theme.font
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                }

                // Days Grid
                GridLayout {
                    Layout.fillWidth: true
                    columns: 8
                    columnSpacing: 0
                    rowSpacing: 2

                    Repeater {
                        model: 48
                        delegate: Rectangle {
                            id: cell
                            required property int index
                            readonly property bool isWeek: index % 8 === 0
                            readonly property var d: win.days[Math.floor(index / 8) * 7 + Math.max(0, (index % 8) - 1)]
                            readonly property bool inMonth: d.getMonth() === win.month
                            readonly property bool isToday: !isWeek && d.toDateString() === win.now.toDateString()
                            readonly property bool weekend: (index % 8) >= 6

                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            radius: 6
                            color: isToday ? Theme.accent : (cellHover.containsMouse && !isWeek ? Theme.surfaceHi : "transparent")
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: cell.isWeek ? win.isoWeek(cell.d) : cell.d.getDate()
                                color: cell.isToday ? Theme.bg
                                     : cell.isWeek ? Theme.line
                                     : !cell.inMonth ? Theme.dim
                                     : cell.weekend ? Theme.accent : Theme.fg
                                opacity: cell.inMonth || cell.isWeek ? 1.0 : 0.4
                                font.family: Theme.font
                                font.pixelSize: cell.isWeek ? 9 : 11
                                font.bold: cell.isToday
                            }

                            MouseArea {
                                id: cellHover
                                anchors.fill: parent
                                hoverEnabled: !cell.isWeek
                                cursorShape: cell.isWeek ? Qt.ArrowCursor : Qt.PointingHandCursor
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
