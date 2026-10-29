import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win
    property bool suppressed: false

    visible: Notifs.popups.length > 0 && !suppressed
    anchors { top: true; right: true }
    margins { top: 56; right: 12 }
    implicitWidth: 340
    implicitHeight: col.implicitHeight
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tzeuk-notifs-popup"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    ColumnLayout {
        id: col
        width: 340
        spacing: 8

        Repeater {
            model: Notifs.popups
            delegate: Rectangle {
                id: card
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: body.implicitHeight + 20
                color: Theme.bg
                opacity: 0.96
                radius: 12
                border.width: 2
                border.color: modelData.n.urgency === 2 ? Theme.err : Theme.accent

                // Card background click (dismiss)
                MouseArea {
                    anchors.fill: parent
                    onClicked: Notifs.dropPopup(modelData.n)
                }

                RowLayout {
                    id: body
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            text: modelData.n.appName || "App"
                            color: Theme.accent
                            font.family: Theme.font
                            font.pixelSize: 9
                            font.letterSpacing: 1
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.n.summary || ""
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.bold: true
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: (modelData.n.body || "") !== ""
                            text: modelData.n.body || ""
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 10
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }

                    // X — on top of the card MouseArea since it comes later
                    Rectangle {
                        width: 22; height: 22; radius: 11
                        Layout.alignment: Qt.AlignTop
                        color: xHover.containsMouse ? Theme.surfaceHi : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: xHover.containsMouse ? Theme.err : Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 10
                        }
                        MouseArea {
                            id: xHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifs.dropPopup(modelData.n)
                        }
                    }
                }
            }
        }
    }
}
