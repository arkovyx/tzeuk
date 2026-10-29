import QtQuick
import QtQuick.Layouts

Item {
    id: page

    Flickable {
        anchors.fill: parent
        anchors.margins: 20
        contentWidth: width
        contentHeight: col.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "NOTIFICATIONS"
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: 16
                    font.bold: true
                    font.letterSpacing: 3
                }

                Item { Layout.fillWidth: true }

                // DND toggle
                Rectangle {
                    width: 32; height: 32; radius: 8
                    color: Notifs.dnd ? Theme.accent : (dndHover.containsMouse ? Theme.surfaceHi : "transparent")
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text {
                        anchors.centerIn: parent
                        text: Notifs.dnd ? Theme.iBellOff : Theme.iBell
                        color: Notifs.dnd ? Theme.bg : Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: dndHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                }

                // Clear all
                Rectangle {
                    width: 32; height: 32; radius: 8
                    color: clearHover.containsMouse ? Theme.err : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰆴"
                        color: clearHover.containsMouse ? Theme.bg : Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: clearHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.clearAll()
                    }
                }
            }

            // Count + DND status
            Text {
                Layout.fillWidth: true
                text: Notifs.count + (Notifs.count === 1 ? " notification" : " notifications")
                      + (Notifs.dnd ? "  ·  DND on" : "")
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 10
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.line
            }

            // Empty state
            Text {
                visible: Notifs.count === 0
                Layout.fillWidth: true
                Layout.topMargin: 60
                horizontalAlignment: Text.AlignHCenter
                text: "󰂜\n\nAll quiet"
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 14
                lineHeight: 1.5
            }

            // Notification cards
            Repeater {
                model: Notifs.history()
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: cardLayout.implicitHeight + 20
                    color: Theme.surfaceHi
                    radius: 10
                    border.width: 1
                    border.color: modelData.urgency === 2 ? Theme.err : Theme.line

                    RowLayout {
                        id: cardLayout
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                Layout.fillWidth: true
                                text: modelData.appName || "App"
                                color: Theme.accent
                                font.family: Theme.font
                                font.pixelSize: 9
                                font.letterSpacing: 1
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.summary || ""
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
                                visible: (modelData.body || "") !== ""
                                text: modelData.body || ""
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: 10
                                wrapMode: Text.Wrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            width: 24; height: 24; radius: 12
                            Layout.alignment: Qt.AlignTop
                            color: delHover.containsMouse ? Theme.err : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                color: delHover.containsMouse ? Theme.bg : Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 11
                            }
                            MouseArea {
                                id: delHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.dismiss()
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 10 }
        }
    }
}
