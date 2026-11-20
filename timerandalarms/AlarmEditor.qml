import QtQuick
import QtQuick.Layouts
import "../themes"

Item {
    id: editor
    property int hour: 7
    property int minute: 30
    signal picked(int h, int m)

    readonly property string fDot: Theme.fontDoto !== "" ? Theme.fontDoto : "Space Mono"
    readonly property string fMono: Theme.fontMono !== "" ? Theme.fontMono : "Space Mono"
    readonly property color cFg: Theme.fg
    readonly property color cAccent: Theme.accent
    readonly property color cDim: Theme.line
    readonly property color cText: Theme.nText
    readonly property color cBg: Theme.bg
    readonly property color cSurf: Theme.surfaceHi

    function wrapHour(val) {
        if (val < 0) return 23
        if (val > 23) return 0
        return val
    }
    function wrapMinute(val) {
        if (val < 0) return 59
        if (val > 59) return 0
        return val
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 16

        // ── HOUR COLUMN ──
        ColumnLayout {
            spacing: 8
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 48; height: 32; radius: 8
                color: upH.containsMouse ? cSurf : "transparent"
                border.width: 1; border.color: cDim
                Text {
                    anchors.centerIn: parent
                    text: "▲"
                    color: cAccent
                    font.pixelSize: 16
                    font.bold: true
                }
                MouseArea {
                    id: upH
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        editor.hour = wrapHour(editor.hour + 1)
                        editor.picked(editor.hour, editor.minute)
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 72; height: 56; radius: 12
                color: hourInput.activeFocus ? cSurf : cBg
                border.width: 3
                border.color: cAccent

                TextInput {
                    id: hourInput
                    anchors.centerIn: parent
                    width: parent.width - 8
                    text: String(editor.hour).padStart(2, "0")
                    color: cAccent
                    font.family: fDot
                    font.weight: Font.Black
                    font.pixelSize: 40
                    font.variableAxes: { "ROND": 100 }
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    inputMethodHints: Qt.ImhDigitsOnly
                    maximumLength: 2
                    selectByMouse: true

                    onEditingFinished: {
                        let val = parseInt(text)
                        if (!isNaN(val)) {
                            editor.hour = wrapHour(val)
                            editor.picked(editor.hour, editor.minute)
                        }
                        text = String(editor.hour).padStart(2, "0")
                    }

                    Keys.onReturnPressed: focus = false
                    Keys.onEnterPressed: focus = false
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    onClicked: {
                        hourInput.focus = true
                        hourInput.selectAll()
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 48; height: 32; radius: 8
                color: downH.containsMouse ? cSurf : "transparent"
                border.width: 1; border.color: cDim
                Text {
                    anchors.centerIn: parent
                    text: "▼"
                    color: cAccent
                    font.pixelSize: 16
                    font.bold: true
                }
                MouseArea {
                    id: downH
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        editor.hour = wrapHour(editor.hour - 1)
                        editor.picked(editor.hour, editor.minute)
                    }
                }
            }
        }

        // ── SEPARATOR ──
        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.bottomMargin: 8
            text: ":"
            color: cAccent
            font.family: fDot
            font.weight: Font.Black
            font.pixelSize: 40
            font.variableAxes: { "ROND": 100 }
        }

        // ── MINUTE COLUMN ──
        ColumnLayout {
            spacing: 8
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 48; height: 32; radius: 8
                color: upM.containsMouse ? cSurf : "transparent"
                border.width: 1; border.color: cDim
                Text {
                    anchors.centerIn: parent
                    text: "▲"
                    color: cAccent
                    font.pixelSize: 16
                    font.bold: true
                }
                MouseArea {
                    id: upM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        editor.minute = wrapMinute(editor.minute + 1)
                        editor.picked(editor.hour, editor.minute)
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 72; height: 56; radius: 12
                color: minInput.activeFocus ? cSurf : cBg
                border.width: 3
                border.color: cAccent

                TextInput {
                    id: minInput
                    anchors.centerIn: parent
                    width: parent.width - 8
                    text: String(editor.minute).padStart(2, "0")
                    color: cAccent
                    font.family: fDot
                    font.weight: Font.Black
                    font.pixelSize: 40
                    font.variableAxes: { "ROND": 100 }
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    inputMethodHints: Qt.ImhDigitsOnly
                    maximumLength: 2
                    selectByMouse: true

                    onEditingFinished: {
                        let val = parseInt(text)
                        if (!isNaN(val)) {
                            editor.minute = wrapMinute(val)
                            editor.picked(editor.hour, editor.minute)
                        }
                        text = String(editor.minute).padStart(2, "0")
                    }

                    Keys.onReturnPressed: focus = false
                    Keys.onEnterPressed: focus = false
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    onClicked: {
                        minInput.focus = true
                        minInput.selectAll()
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 48; height: 32; radius: 8
                color: downM.containsMouse ? cSurf : "transparent"
                border.width: 1; border.color: cDim
                Text {
                    anchors.centerIn: parent
                    text: "▼"
                    color: cAccent
                    font.pixelSize: 16
                    font.bold: true
                }
                MouseArea {
                    id: downM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        editor.minute = wrapMinute(editor.minute - 1)
                        editor.picked(editor.hour, editor.minute)
                    }
                }
            }
        }
    }
}
