import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../themes"

Item {
    id: page

    FontLoader { id: fDoto; source: "../../fonts/Doto.ttf" }
    FontLoader { id: fMono; source: "../../fonts/SpaceMono-Regular.ttf" }
    FontLoader { id: fGrotesk; source: "../../fonts/SpaceGrotesk-Regular.otf" }

    readonly property string fDot: fDoto.name !== "" ? fDoto.name : "monospace"
    readonly property string fMonoStr: fMono.name !== "" ? fMono.name : "monospace"
    readonly property string fSans: fGrotesk.name !== "" ? fGrotesk.name : "sans-serif"

    // ═══ dynamic palette ═══
    readonly property color nBlack: Theme.bg
    readonly property color nWhite: Theme.fg
    readonly property color nRed: Theme.accent
    readonly property color nDim: Theme.line
    readonly property color nSurface: Theme.surfaceHi
    readonly property color nText: Theme.nText

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 20

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "NOTIFS"
                    color: page.nWhite
                    font.family: page.fDot
                    font.pixelSize: 42
                    font.bold: true
                    font.letterSpacing: 4
                }

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 3
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 20
                    color: page.nRed
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 40
                    color: Notifs.dnd ? page.nWhite : page.nSurface
                    border.width: 1
                    border.color: Notifs.dnd ? page.nWhite : page.nDim
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: Notifs.dnd ? page.nBlack : page.nText
                        }

                        Text {
                            text: "DND"
                            color: Notifs.dnd ? page.nBlack : page.nText
                            font.family: page.fSans
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 3
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.leftMargin: 8
                    color: clearHover.containsMouse ? page.nRed : page.nSurface
                    border.width: 1
                    border.color: page.nDim
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰆴"
                        color: clearHover.containsMouse ? page.nWhite : page.nWhite
                        font.pixelSize: 16
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

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: page.nDim }

            Row {
                spacing: 12

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: Notifs.count > 0 ? page.nRed : page.nText
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifs.count + " " + (Notifs.count === 1 ? "NOTIFICATION" : "NOTIFICATIONS")
                    color: Notifs.count > 0 ? page.nWhite : page.nText
                    font.family: page.fMonoStr
                    font.pixelSize: 12
                    font.letterSpacing: 2
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 400
                visible: Notifs.count === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 24

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰂜"
                        color: page.nDim
                        font.pixelSize: 80
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "ALL QUIET"
                        color: page.nText
                        font.family: page.fDot
                        font.pixelSize: 24
                        font.letterSpacing: 6
                    }
                }
            }

            Repeater {
                model: Notifs.history()
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: cardLayout.implicitHeight + 24
                    color: page.nSurface
                    border.width: 1
                    border.color: modelData.urgency === 2 ? page.nRed : page.nDim

                    Rectangle {
                        width: 3
                        height: parent.height - 16
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        color: page.nRed
                        visible: modelData.urgency === 2
                    }

                    RowLayout {
                        id: cardLayout
                        anchors.fill: parent
                        anchors.margins: 14
                        anchors.leftMargin: modelData.urgency === 2 ? 20 : 14
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Row {
                                spacing: 8

                                Text {
                                    text: (modelData.appName || "APP").toUpperCase()
                                    color: page.nRed
                                    font.family: page.fSans
                                    font.pixelSize: 10
                                    font.letterSpacing: 3
                                    font.bold: true
                                }

                                Rectangle {
                                    width: 4
                                    height: 4
                                    radius: 2
                                    color: page.nDim
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: modelData.urgency === 2
                                }

                                Text {
                                    visible: modelData.urgency === 2
                                    text: "URGENT"
                                    color: page.nRed
                                    font.family: page.fSans
                                    font.pixelSize: 10
                                    font.letterSpacing: 3
                                    font.bold: true
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.summary || ""
                                color: page.nWhite
                                font.family: page.fSans
                                font.pixelSize: 14
                                font.bold: true
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: (modelData.body || "") !== ""
                                text: modelData.body || ""
                                color: page.nText
                                font.family: page.fSans
                                font.pixelSize: 11
                                wrapMode: Text.Wrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            Layout.alignment: Qt.AlignTop
                            color: disHover.containsMouse ? page.nRed : "transparent"
                            border.width: 1
                            border.color: page.nDim
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: disHover.containsMouse ? page.nWhite : page.nText
                                font.pixelSize: 18
                                font.bold: true
                            }

                            MouseArea {
                                id: disHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.dismiss()
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
