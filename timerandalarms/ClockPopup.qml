import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../themes"
import "."

PanelWindow {
    id: win
    property bool opened: false
    signal closeRequested()

    readonly property string fDot: Theme.fontDoto !== "" ? Theme.fontDoto : "Space Mono"
    readonly property string fMono: Theme.fontMono !== "" ? Theme.fontMono : "Space Mono"
    readonly property color cBg: Theme.bg
    readonly property color cFg: Theme.fg
    readonly property color cAccent: Theme.accent
    readonly property color cDim: Theme.line
    readonly property color cSurf: Theme.surfaceHi
    readonly property color cText: Theme.nText

    readonly property string m: {
        var x = ClockService.mode
        if (x === "timer" || x === "stopwatch" || x === "alarm") return x
        return "clock"
    }

    readonly property int cardH: m === "alarm" ? 320 : 260

    visible: opened
    anchors { bottom: true; left: true; right: true }
    margins { bottom: 24 }
    implicitWidth: 460
    implicitHeight: cardH
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tzeuk-clock"
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    Shortcut {
        sequence: "Escape"
        enabled: win.opened
        onActivated: win.closeRequested()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: win.closeRequested()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 460
        height: win.cardH
        radius: 20
        color: cBg
        border.width: 1
        border.color: cDim
        clip: true

        MouseArea { anchors.fill: parent }

        RowLayout {
            id: header
            x: 14
            y: 14
            width: parent.width - 28
            height: 40
            spacing: 6

            Repeater {
                model: [
                    { id: "clock", label: "CLOCK" },
                    { id: "timer", label: "TIMER" },
                    { id: "stopwatch", label: "STOP" },
                    { id: "alarm", label: "ALARM" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool active: win.m === modelData.id
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: active ? cAccent : (mh.containsMouse ? cSurf : "transparent")
                    border.width: active ? 0 : 1
                    border.color: cDim

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: parent.active ? cBg : cText
                        font.family: fMono
                        font.pixelSize: 10
                        font.letterSpacing: 2
                        font.bold: true
                    }
                    MouseArea {
                        id: mh
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ClockService.mode = modelData.id
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 40
                Layout.fillHeight: true
                radius: 10
                color: xh.containsMouse ? cSurf : "transparent"
                border.width: 1
                border.color: cDim
                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: xh.containsMouse ? cAccent : cText
                    font.pixelSize: 12
                    font.bold: true
                }
                MouseArea {
                    id: xh
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.closeRequested()
                }
            }
        }

        Item {
            id: content
            x: 14
            y: 64
            width: parent.width - 28
            height: parent.height - 78

            // ── CLOCK ──
            Item {
                anchors.fill: parent
                visible: win.m === "clock"
                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(ClockService.now, "HH:mm")
                    color: cAccent
                    font.family: fDot
                    font.weight: Font.Black
                    font.pixelSize: 84
                    font.variableAxes: { "ROND": 100 }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    text: Qt.formatDateTime(ClockService.now, "dddd · d MMMM yyyy").toUpperCase()
                    color: cText
                    font.family: fMono
                    font.pixelSize: 10
                    font.letterSpacing: 3
                }
            }

            // ── TIMER ──
            Item {
                anchors.fill: parent
                visible: win.m === "timer"
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4

                        // Hours
                        Rectangle {
                            Layout.preferredWidth: 80
                            Layout.preferredHeight: 70
                            radius: 12
                            color: timerHourInput.activeFocus ? cSurf : cBg
                            border.width: timerHourInput.activeFocus ? 3 : 1
                            border.color: timerHourInput.activeFocus ? cAccent : cDim

                            TextInput {
                                id: timerHourInput
                                anchors.centerIn: parent
                                width: parent.width - 10
                                text: String(Math.floor(ClockService.timerSet / 3600)).padStart(2, "0")
                                color: cAccent
                                font.family: fDot
                                font.weight: Font.Black
                                font.pixelSize: 48
                                font.variableAxes: { "ROND": 100 }
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                inputMethodHints: Qt.ImhDigitsOnly
                                maximumLength: 2
                                selectByMouse: true

                                onEditingFinished: {
                                    let val = parseInt(text)
                                    if (!isNaN(val) && val >= 0 && val <= 99) {
                                        let newSeconds = (val * 3600) +
                                                       (Math.floor((ClockService.timerSet % 3600) / 60) * 60) +
                                                       (ClockService.timerSet % 60)
                                        ClockService.timerSetTo(newSeconds)
                                    }
                                    text = String(Math.floor(ClockService.timerSet / 3600)).padStart(2, "0")
                                }

                                Keys.onReturnPressed: focus = false
                                Keys.onEnterPressed: focus = false
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.IBeamCursor
                                onClicked: {
                                    timerHourInput.focus = true
                                    timerHourInput.selectAll()
                                }
                            }
                        }

                        Text {
                            text: ":"
                            color: cAccent
                            font.family: fDot
                            font.weight: Font.Black
                            font.pixelSize: 48
                            font.variableAxes: { "ROND": 100 }
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Minutes
                        Rectangle {
                            Layout.preferredWidth: 80
                            Layout.preferredHeight: 70
                            radius: 12
                            color: timerMinInput.activeFocus ? cSurf : cBg
                            border.width: timerMinInput.activeFocus ? 3 : 1
                            border.color: timerMinInput.activeFocus ? cAccent : cDim

                            TextInput {
                                id: timerMinInput
                                anchors.centerIn: parent
                                width: parent.width - 10
                                text: String(Math.floor((ClockService.timerSet % 3600) / 60)).padStart(2, "0")
                                color: cAccent
                                font.family: fDot
                                font.weight: Font.Black
                                font.pixelSize: 48
                                font.variableAxes: { "ROND": 100 }
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                inputMethodHints: Qt.ImhDigitsOnly
                                maximumLength: 2
                                selectByMouse: true

                                onEditingFinished: {
                                    let val = parseInt(text)
                                    if (!isNaN(val) && val >= 0 && val <= 59) {
                                        let newSeconds = (Math.floor(ClockService.timerSet / 3600) * 3600) +
                                                       (val * 60) +
                                                       (ClockService.timerSet % 60)
                                        ClockService.timerSetTo(newSeconds)
                                    }
                                    text = String(Math.floor((ClockService.timerSet % 3600) / 60)).padStart(2, "0")
                                }

                                Keys.onReturnPressed: focus = false
                                Keys.onEnterPressed: focus = false
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.IBeamCursor
                                onClicked: {
                                    timerMinInput.focus = true
                                    timerMinInput.selectAll()
                                }
                            }
                        }

                        Text {
                            text: ":"
                            color: cAccent
                            font.family: fDot
                            font.weight: Font.Black
                            font.pixelSize: 48
                            font.variableAxes: { "ROND": 100 }
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Seconds
                        Rectangle {
                            Layout.preferredWidth: 80
                            Layout.preferredHeight: 70
                            radius: 12
                            color: timerSecInput.activeFocus ? cSurf : cBg
                            border.width: timerSecInput.activeFocus ? 3 : 1
                            border.color: timerSecInput.activeFocus ? cAccent : cDim

                            TextInput {
                                id: timerSecInput
                                anchors.centerIn: parent
                                width: parent.width - 10
                                text: String(ClockService.timerSet % 60).padStart(2, "0")
                                color: cAccent
                                font.family: fDot
                                font.weight: Font.Black
                                font.pixelSize: 48
                                font.variableAxes: { "ROND": 100 }
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                inputMethodHints: Qt.ImhDigitsOnly
                                maximumLength: 2
                                selectByMouse: true

                                onEditingFinished: {
                                    let val = parseInt(text)
                                    if (!isNaN(val) && val >= 0 && val <= 59) {
                                        let newSeconds = (Math.floor(ClockService.timerSet / 3600) * 3600) +
                                                       (Math.floor((ClockService.timerSet % 3600) / 60) * 60) +
                                                       val
                                        ClockService.timerSetTo(newSeconds)
                                    }
                                    text = String(ClockService.timerSet % 60).padStart(2, "0")
                                }

                                Keys.onReturnPressed: focus = false
                                Keys.onEnterPressed: focus = false
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.IBeamCursor
                                onClicked: {
                                    timerSecInput.focus = true
                                    timerSecInput.selectAll()
                                }
                            }
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6
                        Repeater {
                            model: [
                                { l: "-1m", d: -60 }, { l: "+1m", d: 60 }, { l: "5m", d: 300 }, { l: "25m", d: 1500 }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                width: 56; height: 30; radius: 8
                                color: bh.containsMouse ? cSurf : "transparent"
                                border.width: 1; border.color: cDim
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.l
                                    color: cFg
                                    font.family: fMono
                                    font.pixelSize: 10
                                }
                                MouseArea {
                                    id: bh
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.d === 1500) ClockService.timerSetTo(1500)
                                        else ClockService.timerAdd(modelData.d)
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8
                        Rectangle {
                            width: 120; height: 38; radius: 19
                            color: cAccent
                            Text {
                                anchors.centerIn: parent
                                text: !ClockService.timerOn ? "START" : (ClockService.timerPaused ? "RESUME" : "PAUSE")
                                color: cBg
                                font.family: fMono
                                font.pixelSize: 11
                                font.letterSpacing: 2
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ClockService.timerToggle()
                            }
                        }
                        Rectangle {
                            visible: ClockService.timerOn
                            width: 38; height: 38; radius: 19
                            color: sh.containsMouse ? cSurf : "transparent"
                            border.width: 1; border.color: cDim
                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: cAccent
                                font.pixelSize: 14
                                font.bold: true
                            }
                            MouseArea {
                                id: sh
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ClockService.timerStop()
                            }
                        }
                    }
                }
            }

            // ── STOPWATCH ──
            Item {
                anchors.fill: parent
                visible: win.m === "stopwatch"
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: ClockService.swFmt(ClockService.swMs)
                        color: ClockService.swOn ? cAccent : cFg
                        font.family: fDot
                        font.weight: Font.Black
                        font.pixelSize: 60
                        font.variableAxes: { "ROND": 100 }
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8
                        Rectangle {
                            width: 120; height: 38; radius: 19
                            color: ClockService.swOn ? cAccent : cFg
                            Text {
                                anchors.centerIn: parent
                                text: ClockService.swOn ? "STOP" : (ClockService.swMs > 0 ? "RESUME" : "START")
                                color: cBg
                                font.family: fMono
                                font.pixelSize: 11
                                font.letterSpacing: 2
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ClockService.swToggle()
                            }
                        }
                        Rectangle {
                            visible: !ClockService.swOn && ClockService.swMs > 0
                            width: 90; height: 38; radius: 19
                            color: rh.containsMouse ? cSurf : "transparent"
                            border.width: 1; border.color: cDim
                            Text {
                                anchors.centerIn: parent
                                text: "RESET"
                                color: cText
                                font.family: fMono
                                font.pixelSize: 11
                                font.letterSpacing: 2
                                font.bold: true
                            }
                            MouseArea {
                                id: rh
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ClockService.swReset()
                            }
                        }
                    }
                }
            }

            // ── ALARM ──
            Item {
                anchors.fill: parent
                visible: win.m === "alarm"
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    Rectangle {
                        visible: ClockService.alarmRinging
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 260
                        Layout.preferredHeight: 46
                        radius: 12
                        color: cAccent

                        SequentialAnimation on opacity {
                            running: ClockService.alarmRinging
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.5; duration: 500 }
                            NumberAnimation { to: 1.0; duration: 500 }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "🔔 RINGING — CLICK TO DISMISS"
                            color: cBg
                            font.family: fMono
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ClockService.dismissAlarm()
                        }
                    }

                    AlarmEditor {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 260
                        Layout.preferredHeight: 140
                        hour: ClockService.alarmH
                        minute: ClockService.alarmM
                        onPicked: (h, m) => ClockService.alarmSet(h, m)
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 6
                        Repeater {
                            model: ["S", "M", "T", "W", "T", "F", "S"]
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: 32; height: 32; radius: 16
                                color: ClockService.alarmDays.indexOf(index) >= 0 ? cAccent : "transparent"
                                border.width: 1
                                border.color: ClockService.alarmDays.indexOf(index) >= 0 ? cAccent : cDim
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: parent.color === cAccent ? cBg : cText
                                    font.family: fMono
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ClockService.alarmToggleDay(index)
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 160; height: 36; radius: 18
                        color: ClockService.alarmOn ? cAccent : "transparent"
                        border.width: 1
                        border.color: ClockService.alarmOn ? cAccent : cDim
                        Text {
                            anchors.centerIn: parent
                            text: ClockService.alarmOn ? "TURN OFF" : "TURN ON"
                            color: ClockService.alarmOn ? cBg : cFg
                            font.family: fMono
                            font.pixelSize: 11
                            font.letterSpacing: 2
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ClockService.alarmToggle()
                        }
                    }
                }
            }
        }
    }
}
