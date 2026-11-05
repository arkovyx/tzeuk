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
    // Full-width strip below the bar so we can center & detect outside clicks
    anchors { top: true; left: true; right: true }
    margins { top: 56 }
    implicitHeight: 440
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

    // ==== Full-width transparent backdrop (click outside to close) ====
    MouseArea {
        anchors.fill: parent
        onClicked: win.closeRequested()
    }

    // ==== Centered calendar ====
    Rectangle {
        id: calendar
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        width: 360
        height: 430
        radius: 24
        color: win.nBlack
        border.width: 1
        border.color: win.nDim

        // Scale-in on open
        scale: win.opened ? 1.0 : 0.92
        opacity: win.opened ? 1.0 : 0.0
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 160 } }

        focus: true
        Keys.onEscapePressed: win.closeRequested()
        Keys.onLeftPressed: win.shift(-1)
        Keys.onRightPressed: win.shift(1)
        Keys.onSpacePressed: win.today()

        // Backdrop — absorbs clicks inside the calendar so the outer MouseArea
        // (which closes the popup) doesn't fire when clicking calendar elements
        MouseArea { anchors.fill: parent }

        // Wheel to navigate months
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: w => win.shift(w.angleDelta.y > 0 ? -1 : 1)
        }

        // Subtle dot texture
        Canvas {
            anchors.fill: parent
            opacity: 0.03
            onPaint: {
                var ctx = getContext("2d")
                ctx.fillStyle = "white"
                for (var x = 0; x < width; x += 20) {
                    for (var y = 0; y < height; y += 20) {
                        ctx.beginPath()
                        ctx.arc(x, y, 1, 0, Math.PI * 2)
                        ctx.fill()
                    }
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14

            // ===== Big dot-matrix clock =====
            Text {
                Layout.fillWidth: true
                text: Qt.formatDateTime(win.now, "HH:mm")
                color: win.nWhite
                font.family: win.fDot
                font.pixelSize: 48
                font.bold: true
                font.letterSpacing: 2
            }

            // ===== Weekday · date line =====
            Row {
                spacing: 10
                Rectangle {
                    width: 20
                    height: 3
                    radius: 1.5
                    color: win.nRed
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: Qt.formatDateTime(win.now, "dddd, d MMMM").toUpperCase()
                    color: win.nWhite
                    font.family: win.fSans
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // ===== Red pill divider =====
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 3
                radius: 1.5
                color: win.nRed
                opacity: 0.35
                Layout.topMargin: 2
                Layout.bottomMargin: 2
            }

            // ===== Month nav =====
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Prev month — circular button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: prevHover.containsMouse ? win.nRed : win.nSurface
                    border.width: 1
                    border.color: prevHover.containsMouse ? win.nRed : win.nDim
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "‹"
                        color: prevHover.containsMouse ? win.nWhite : win.nWhite
                        font.pixelSize: 20
                        font.bold: true
                    }

                    MouseArea {
                        id: prevHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.shift(-1)
                    }
                }

                // Month label — pill shape
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 16
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
                        font.letterSpacing: 3
                    }

                    MouseArea {
                        id: monthHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.today()
                    }
                }

                // Next month — circular button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: nextHover.containsMouse ? win.nRed : win.nSurface
                    border.width: 1
                    border.color: nextHover.containsMouse ? win.nRed : win.nDim
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        color: win.nWhite
                        font.pixelSize: 20
                        font.bold: true
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

            // ===== Weekday header =====
            GridLayout {
                Layout.fillWidth: true
                columns: 8
                columnSpacing: 2
                rowSpacing: 4

                Repeater {
                    model: ["WK", "M", "T", "W", "T", "F", "S", "S"]
                    delegate: Text {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: index === 0 ? win.nText
                             : index >= 6 ? win.nRed : win.nText
                        font.family: win.fSans
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1
                    }
                }
            }

            // ===== Days grid =====
            GridLayout {
                Layout.fillWidth: true
                columns: 8
                columnSpacing: 2
                rowSpacing: 2

                Repeater {
                    model: 48
                    delegate: Item {
                        id: cellWrap
                        required property int index
                        readonly property bool isWeek: index % 8 === 0
                        readonly property var d: win.days[Math.floor(index / 8) * 7 + Math.max(0, (index % 8) - 1)]
                        readonly property bool inMonth: d.getMonth() === win.month
                        readonly property bool isToday: !isWeek && d.toDateString() === win.now.toDateString()
                        readonly property bool weekend: (index % 8) >= 6

                        Layout.fillWidth: true
                        Layout.preferredHeight: 30

                        // Rounded pill background
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: 15
                            color: cellWrap.isToday ? win.nRed
                                 : (cellHover.containsMouse && !cellWrap.isWeek ? win.nSurface : "transparent")
                            border.width: 0
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        // Red dot under today
                        Rectangle {
                            visible: cellWrap.isToday
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            width: 4
                            height: 4
                            radius: 2
                            color: win.nWhite
                        }

                        Text {
                            anchors.centerIn: parent
                            text: cellWrap.isWeek ? win.isoWeek(cellWrap.d) : cellWrap.d.getDate()
                            color: cellWrap.isToday ? win.nWhite
                                 : cellWrap.isWeek ? win.nText
                                 : !cellWrap.inMonth ? win.nText
                                 : cellWrap.weekend ? win.nRed : win.nWhite
                            opacity: cellWrap.inMonth || cellWrap.isWeek ? 1.0 : 0.35
                            font.family: cellWrap.isWeek ? win.fMonoStr : win.fSans
                            font.pixelSize: cellWrap.isWeek ? 9 : 12
                            font.bold: cellWrap.isToday
                        }

                        MouseArea {
                            id: cellHover
                            anchors.fill: parent
                            hoverEnabled: !cellWrap.isWeek
                            cursorShape: cellWrap.isWeek ? Qt.ArrowCursor : Qt.PointingHandCursor
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // ===== Footer hint =====
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "‹ ›  NAVIGATE   ·   ESC  CLOSE"
                    color: win.nText
                    font.family: win.fMonoStr
                    font.pixelSize: 9
                    font.letterSpacing: 1
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "W" + win.isoWeek(win.now)
                    color: win.nRed
                    font.family: win.fMonoStr
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1
                }
            }
        }
    }
}
