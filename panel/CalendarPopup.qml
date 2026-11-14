import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import "../themes"

PanelWindow {
    id: win
    property bool opened: false
    property bool grabActive: false
    signal closeRequested()

    visible: opened
    anchors { top: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    margins { top: 52 }
    implicitHeight: 490
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tzeuk-calendar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand


    readonly property string fDot: Theme.fontDoto !== "" ? Theme.fontDoto : "monospace"
    readonly property string fMonoStr: Theme.fontMono !== "" ? Theme.fontMono : "monospace"
    readonly property string fSans: Theme.fontSans !== "" ? Theme.fontSans : "sans-serif"

    // ═══ dynamic palette ═══
    readonly property color nBlack: Theme.bg
    readonly property color nWhite: Theme.fg
    readonly property color nRed: Theme.accent
    readonly property color nDim: Theme.line
    readonly property color nSurface: Theme.surfaceHi
    readonly property color nText: Theme.nText

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

    readonly property var days: {
        var first = new Date(year, month, 1)
        var start = new Date(year, month, 1 - ((first.getDay() + 6) % 7))
        var out = []
        for (var i = 0; i < 42; i++)
            out.push(new Date(start.getFullYear(), start.getMonth(), start.getDate() + i))
        return out
    }

    readonly property var now: sysClock.date

    MouseArea {
        anchors.fill: parent
        onClicked: win.closeRequested()
    }

    Rectangle {
        id: calendar
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        width: 380
        height: 460
        color: win.nBlack
        border.width: 1
        border.color: win.nDim
        radius: 24

        opacity: win.opened ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        focus: true
        Keys.onEscapePressed: win.closeRequested()
        Keys.onLeftPressed: win.shift(-1)
        Keys.onRightPressed: win.shift(1)
        Keys.onSpacePressed: win.today()

        MouseArea { anchors.fill: parent }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: w => win.shift(w.angleDelta.y > 0 ? -1 : 1)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 34
            anchors.bottomMargin: 18
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            spacing: 12

            Row {
                Layout.fillWidth: true
                Layout.preferredHeight: 62
                spacing: 0

                Text {
                    text: Qt.formatDateTime(win.now, "HH:mm")
                    color: win.nWhite
                    font.family: win.fDot
                    font.pixelSize: 56
                    font.bold: true
                    anchors.bottom: parent.bottom
                }
                Text {
                    text: ":" + Qt.formatDateTime(win.now, "ss")
                    color: win.nRed
                    font.family: win.fDot
                    font.pixelSize: 56
                    font.bold: true
                    anchors.bottom: parent.bottom
                }
            }

            Row {
                spacing: 10
                Rectangle {
                    width: 24
                    height: 3
                    radius: 1.5
                    color: win.nRed
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: Qt.formatDateTime(win.now, "dddd").toUpperCase()
                    color: win.nWhite
                    font.family: win.fSans
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 4
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "·"
                    color: win.nRed
                    font.pixelSize: 14
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: Qt.formatDateTime(win.now, "dd MMM yyyy").toUpperCase()
                    color: win.nText
                    font.family: win.fSans
                    font.pixelSize: 11
                    font.letterSpacing: 3
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 2
                radius: 1
                color: win.nRed
                opacity: 0.4
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 34
                    height: 34
                    radius: 17
                    color: prevHover.containsMouse ? win.nRed : win.nSurface
                    border.width: 1
                    border.color: prevHover.containsMouse ? win.nRed : win.nDim
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Text {
                        anchors.centerIn: parent
                        text: "‹"
                        color: win.nWhite
                        font.pixelSize: 22
                        font.bold: true
                        anchors.verticalCenterOffset: -1
                    }
                    MouseArea {
                        id: prevHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.shift(-1)
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 17
                    color: monthHover.containsMouse ? win.nSurface : "transparent"
                    border.width: 1
                    border.color: win.nDim
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text {
                        anchors.centerIn: parent
                        text: Qt.formatDate(new Date(win.year, win.month, 1), "MMMM yyyy").toUpperCase()
                        color: win.nRed
                        font.family: win.fSans
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 4
                    }
                    MouseArea {
                        id: monthHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.today()
                    }
                }

                Rectangle {
                    width: 34
                    height: 34
                    radius: 17
                    color: nextHover.containsMouse ? win.nRed : win.nSurface
                    border.width: 1
                    border.color: nextHover.containsMouse ? win.nRed : win.nDim
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        color: win.nWhite
                        font.pixelSize: 22
                        font.bold: true
                        anchors.verticalCenterOffset: -1
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

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                columnSpacing: 0
                rowSpacing: 0

                Repeater {
                    model: ["M", "T", "W", "T", "F", "S", "S"]
                    delegate: Item {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: index >= 5 ? win.nRed : win.nText
                            font.family: win.fSans
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                columnSpacing: 0
                rowSpacing: 2

                Repeater {
                    model: 42
                    delegate: Item {
                        id: cellWrap
                        required property int index
                        readonly property var d: win.days[index]
                        readonly property bool inMonth: d.getMonth() === win.month
                        readonly property bool isToday: d.toDateString() === win.now.toDateString()
                        readonly property bool weekend: (index % 7) >= 5

                        Layout.fillWidth: true
                        Layout.preferredHeight: 34

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 15
                            color: cellWrap.isToday ? win.nRed
                                 : (cellHover.containsMouse ? win.nSurface : "transparent")
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: cellWrap.d.getDate()
                            color: cellWrap.isToday ? win.nWhite
                                 : !cellWrap.inMonth ? win.nText
                                 : cellWrap.weekend ? win.nRed : win.nWhite
                            opacity: cellWrap.inMonth ? 1.0 : 0.35
                            font.family: win.fSans
                            font.pixelSize: 13
                            font.bold: cellWrap.isToday
                        }

                        MouseArea {
                            id: cellHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
