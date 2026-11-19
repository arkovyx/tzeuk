import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"
import "../themes"

PanelWindow {
    id: win
    property bool suppressed: false

    readonly property string fDot:  Theme.fontDoto !== "" ? Theme.fontDoto : "monospace"
    readonly property string fMono: Theme.fontMono !== "" ? Theme.fontMono : "monospace"
    readonly property string fSans: Theme.fontSans !== "" ? Theme.fontSans : "sans-serif"

    readonly property color nBlack: Theme.bg
    readonly property color nWhite: Theme.fg
    readonly property color nRed: Theme.accent
    readonly property color nDim: Theme.line
    readonly property color nSurface: Theme.surfaceHi
    readonly property color nText: Theme.nText

    visible: Notifs.popups.length > 0 && !suppressed
    anchors { top: true; right: true }
    margins { top: 60; right: 20 }
    implicitWidth: 420
    implicitHeight: col.implicitHeight
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tzeuk-notif-popup"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    ColumnLayout {
        id: col
        width: 420
        spacing: 8

        Repeater {
            model: Notifs.popups

            delegate: Rectangle {
                id: card
                required property var modelData
                required property int index
                readonly property bool critical: modelData.n.urgency === 2
                readonly property bool hovering: cardHover.containsMouse

                Layout.fillWidth: true
                implicitHeight: body.implicitHeight + 28
                radius: 14
                color: Qt.rgba(nBlack.r, nBlack.g, nBlack.b, 0.95)

                // Critical accent bar on left
                Rectangle {
                    visible: card.critical
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10
                    width: 3
                    radius: 1.5
                    color: nRed
                }

                // Faint border — accent on hover
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: 1
                    border.color: card.hovering
                        ? Qt.rgba(nRed.r, nRed.g, nRed.b, 0.6)
                        : Qt.rgba(nDim.r, nDim.g, nDim.b, 0.6)
                    Behavior on border.color { ColorAnimation { duration: 120 } }
                }

                // Slide-in animation
                opacity: 0
                transform: Translate { x: 40 }
                Component.onCompleted: introAnim.start()

                ParallelAnimation {
                    id: introAnim
                    NumberAnimation {
                        target: card
                        property: "opacity"
                        from: 0; to: 1
                        duration: 240
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: card.transform[0]
                        property: "x"
                        from: 40; to: 0
                        duration: 280
                        easing.type: Easing.OutBack
                        easing.overshoot: 0.9
                    }
                }

                MouseArea {
                    id: cardHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.dropPopup(modelData.n)
                }

                RowLayout {
                    id: body
                    anchors.fill: parent
                    anchors.margins: 14
                    anchors.leftMargin: card.critical ? 22 : 14
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // App name + status tag
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 5
                                Layout.preferredHeight: 5
                                radius: 2.5
                                color: card.critical ? nRed : nRed
                                opacity: card.critical ? 1.0 : 0.55
                            }

                            Text {
                                Layout.fillWidth: true
                                text: (modelData.n.appName || "APP").toUpperCase()
                                color: nText
                                font.family: fMono
                                font.pixelSize: 9
                                font.letterSpacing: 2.5
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: card.critical ? "URGENT" : "NOW"
                                color: card.critical ? nRed : nText
                                font.family: fMono
                                font.pixelSize: 9
                                font.letterSpacing: 2
                                font.bold: true
                            }
                        }

                        // Summary
                        Text {
                            Layout.fillWidth: true
                            text: modelData.n.summary || ""
                            color: nWhite
                            font.family: fSans
                            font.pixelSize: 15
                            font.bold: true
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            lineHeight: 1.2
                        }

                        // Body
                        Text {
                            Layout.fillWidth: true
                            visible: (modelData.n.body || "") !== ""
                            text: modelData.n.body || ""
                            color: nText
                            font.family: fSans
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            lineHeight: 1.35
                        }
                    }

                    // Close button
                    Rectangle {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        Layout.alignment: Qt.AlignTop
                        radius: 11
                        color: xHover.containsMouse
                            ? Qt.rgba(nWhite.r, nWhite.g, nWhite.b, 0.12)
                            : Qt.rgba(nWhite.r, nWhite.g, nWhite.b, 0.04)

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: xHover.containsMouse ? nRed : nText
                            font.pixelSize: 10
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
