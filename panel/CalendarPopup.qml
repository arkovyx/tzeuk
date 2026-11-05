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
    margins { top: 56; right: 20 }
    implicitWidth: 360
    implicitHeight: 420
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tzeuk-calendar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    FontLoader { id: fDoto; source: "../fonts/Doto.ttf" }
    FontLoader { id: fMono; source: "../fonts/SpaceMono-Regular.ttf" }
    FontLoader { id: fGrotesk; source: "../fonts/SpaceGrotesk-Regular.otf" }

    readonly property string fDot: fDoto.name !== "" ? fDoto.name : "monospace"
    readonly property string fMonoStr: fMono.name !== "" ? fMono.name : "monospace"
    readonly property string fSans: fGrotesk.name !== "" ? fGrotesk.name : "sans-serif"

    readonly property color nBlack: "#000000"
    readonly property color nWhite: "#ffffff"
    readonly property color nRed: "#d71921"
    readonly property color nDim: "#2a2a2a"
    readonly property color nSurface: "#0d0d0d"
    readonly property color nText: "#666666"

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

    SystemClock { id: sysClock; precision: SystemClock.Seconds }

    property int year: 0
    property int month: 0

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

    Rectangle {
        anchors.fill: parent
        color: win.nBlack
        border.width: 1
        border.color: win.nDim

        focus: true
        Keys.onEscapePressed: win.closeRequested()
        Keys.onLeftPressed: win.shift(-1)
        Keys.onRightPressed: win.shift(1)
        Keys.onSpacePressed: win.today()

        MouseArea {
            anchors.fill: parent
            onWheel: w => win.shift(w.angleDelta.y > 0 ? -1 : 1)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 12

            // Big Clock
            Text {
                Layout.fillWidth: true
                text: Qt.formatDateTime(win.now, "HH:mm:ss")
                color: win.nWhite
                font.family: win.fDot
                font.pixelSize: 44
                font.bold: true
                font.letterSpacing: 2
            }

            // Date
            Row {
                spacing: 12
                Rectangle {
                    width: 24
                    height: 2
                    color: win.nRed
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: Qt.formatDateTime(win.now, "dddd, d MMMM yyyy").toUpperCase()
                    color: win.nWhite
                    font.family: win.fSans
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Red divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: win.nRed
                opacity: 0.4
                Layout.topMargin: 4
                Layout.bottomMargin: 4
            }

            // Month navigation
            RowLayout {
                Layout.fillWidth: true

                Rectangle {
                    width: 28
                    height: 28
                    color: prevHover.containsMouse ? win.nDim : "transparent"
                    border.width: 1
                    border.color: win.nDim

                    Text {
                        anchors.centerIn: parent
                        text: "◀"
                        color: prevHover.containsMouse ? win.nRed : win.nWhite
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: prevHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.shift(-1)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDate(new Date(win.year, win.month, 1), "MMMM yyyy").toUpperCase()
                    color: win.nRed
                    font.family: win.fSans
                    font.pixelSize: 13
                    font.bold: true
                    font.letterSpacing: 4
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.today()
                    }
                }

                Rectangle {
                    width: 28
                    height: 28
                    color: nextHover.containsMouse ? win.nDim : "transparent"
                    border.width: 1
                    border.color: win.nDim

                    Text {
                        anchors.centerIn: parent
                        text: "▶"
                        color: nextHover.containsMouse ? win.nRed : win.nWhite
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: nextHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.shift(1)
                    }
                }
            }

            // Weekday headers
            GridLayout {
                Layout.fillWidth: true
                columns: 8
                columnSpacing: 0
                rowSpacing: 6

                Repeater {
                    model: ["WK", "MO", "TU", "WE", "TH", "FR", "SA", "SU"]
                    delegate: Text {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: index === 0 ? win.nText : (index >= 6 ? win.nRed : win.nWhite)
                        font.family: win.fMonoStr
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 1
                    }
                }
            }

            // Days
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
                        Layout.preferredHeight: 26
                        color: isToday ? win.nRed : (cellHover.containsMouse && !isWeek ? win.nSurface : "transparent")
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: cell.isWeek ? win.isoWeek(cell.d) : cell.d.getDate()
                            color: cell.isToday ? win.nWhite
                                 : cell.isWeek ? win.nText
                                 : !cell.inMonth ? win.nText
                                 : cell.weekend ? win.nRed : win.nWhite
                            opacity: cell.inMonth || cell.isWeek ? 1.0 : 0.4
                            font.family: cell.isWeek ? win.fMonoStr : win.fDot
                            font.pixelSize: cell.isWeek ? 9 : 12
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
