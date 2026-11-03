import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: win
    property bool suppressed: false

    FontLoader { id: fDoto; source: "../fonts/Doto[ROND,wght].ttf" }
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

    visible: Notifs.popups.length > 0 && !suppressed
    anchors { top: true; right: true }
    margins { top: 56; right: 20 }
    implicitWidth: 360
    implicitHeight: col.implicitHeight
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tzeuk-notif-popup"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    ColumnLayout {
        id: col
        width: 360
        spacing: 8

        Repeater {
            model: Notifs.popups
            delegate: Rectangle {
                id: card
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: body.implicitHeight + 24
                color: win.nBlack
                border.width: 1
                border.color: modelData.n.urgency === 2 ? win.nRed : win.nDim

                // Red indicator
                Rectangle {
                    width: 3
                    height: parent.height - 16
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: win.nRed
                    visible: modelData.n.urgency === 2
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Notifs.dropPopup(modelData.n)
                }

                RowLayout {
                    id: body
                    anchors.fill: parent
                    anchors.margins: 14
                    anchors.leftMargin: 20
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            text: (modelData.n.appName || "APP").toUpperCase()
                            color: win.nRed
                            font.family: win.fSans
                            font.pixelSize: 9
                            font.letterSpacing: 3
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.n.summary || ""
                            color: win.nWhite
                            font.family: win.fSans
                            font.pixelSize: 13
                            font.bold: true
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: (modelData.n.body || "") !== ""
                            text: modelData.n.body || ""
                            color: win.nText
                            font.family: win.fSans
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignTop
                        color: xHover.containsMouse ? win.nRed : "transparent"
                        border.width: 1
                        border.color: win.nDim
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: xHover.containsMouse ? win.nWhite : win.nText
                            font.pixelSize: 16
                            font.bold: true
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
