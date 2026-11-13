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

    Component.onCompleted: Net.active = true
    Component.onDestruction: Net.active = false

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
                    text: "NETWORK"
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

                Row {
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: Net.connected !== "" ? page.nRed : page.nText
                        SequentialAnimation on opacity {
                            running: Net.connected !== ""
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 1000 }
                            NumberAnimation { to: 1.0; duration: 1000 }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Net.connected !== "" ? "CONNECTED" : "OFFLINE"
                        color: Net.connected !== "" ? page.nWhite : page.nText
                        font.family: page.fMonoStr
                        font.pixelSize: 11
                        font.letterSpacing: 3
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.leftMargin: 16
                    color: scanHover.containsMouse ? page.nDim : page.nSurface
                    border.width: 1
                    border.color: page.nDim

                    Text {
                        anchors.centerIn: parent
                        text: "↻"
                        color: Net.scanning ? page.nRed : page.nWhite
                        font.pixelSize: 20
                    }

                    MouseArea {
                        id: scanHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Net.rescan()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 40
                    Layout.leftMargin: 8
                    color: Net.wifiEnabled ? page.nWhite : page.nSurface
                    border.width: 1
                    border.color: page.nDim
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: Net.wifiEnabled ? "ON" : "OFF"
                        color: Net.wifiEnabled ? page.nBlack : page.nText
                        font.family: page.fSans
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 2
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Net.setWifi(!Net.wifiEnabled)
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: page.nDim }

            ColumnLayout {
                Layout.fillWidth: true
                visible: Net.wiredDevs.length > 0
                spacing: 8

                Text {
                    text: "WIRED"
                    color: page.nRed
                    font.family: page.fSans
                    font.pixelSize: 11
                    font.letterSpacing: 4
                    font.bold: true
                }

                Repeater {
                    model: Net.wiredDevs
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 64
                        color: page.nSurface
                        border.width: 1
                        border.color: page.nDim

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 16

                            Text {
                                text: modelData.usb ? "󰢹" : "󰈀"
                                color: page.nRed
                                font.pixelSize: 22
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: modelData.name.toUpperCase()
                                    color: page.nWhite
                                    font.family: page.fSans
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.letterSpacing: 2
                                }

                                Text {
                                    text: modelData.dev + (modelData.ip !== "" ? "  ·  " + modelData.ip : "")
                                    color: page.nText
                                    font.family: page.fMonoStr
                                    font.pixelSize: 10
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                color: dHover.containsMouse ? page.nRed : "transparent"
                                border.width: 1
                                border.color: page.nDim
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    color: dHover.containsMouse ? page.nWhite : page.nText
                                    font.pixelSize: 16
                                }

                                MouseArea {
                                    id: dHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Net.disconnectDev(modelData.dev)
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: Net.message !== ""
                implicitHeight: visible ? errText.implicitHeight + 24 : 0
                color: page.nSurface
                border.width: 1
                border.color: page.nRed

                Text {
                    id: errText
                    anchors.fill: parent
                    anchors.margins: 12
                    text: Net.message
                    color: page.nRed
                    font.family: page.fMonoStr
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
            }

            Text {
                text: "NETWORKS"
                color: page.nRed
                font.family: page.fSans
                font.pixelSize: 11
                font.letterSpacing: 4
                font.bold: true
            }

            Text {
                visible: !Net.wifiEnabled
                Layout.fillWidth: true
                Layout.topMargin: 20
                text: "▸ Wi-Fi is disabled"
                color: page.nText
                font.family: page.fMonoStr
                font.pixelSize: 13
                font.italic: true
            }

            Repeater {
                model: Net.wifiEnabled ? Net.networks : []
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 64
                    color: modelData.inUse ? page.nSurface : "transparent"
                    border.width: 1
                    border.color: modelData.inUse ? page.nWhite : page.nDim

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Net.connectTo(modelData)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 16

                        Row {
                            spacing: 2
                            anchors.verticalCenter: parent.verticalCenter
                            Repeater {
                                model: 4
                                Rectangle {
                                    width: 4
                                    height: 6 + index * 4
                                    anchors.bottom: parent.bottom
                                    color: (index * 25 < modelData.signal)
                                        ? (modelData.inUse ? page.nRed : page.nWhite)
                                        : page.nDim
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: modelData.ssid
                                color: page.nWhite
                                font.family: page.fSans
                                font.pixelSize: 13
                                font.bold: modelData.inUse
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.inUse ? "CONNECTED"
                                    : (modelData.saved ? "SAVED"
                                    : (modelData.security === "" || modelData.security === "--" ? "OPEN" : modelData.security.toUpperCase()))
                                color: modelData.inUse ? page.nRed : page.nText
                                font.family: page.fMonoStr
                                font.pixelSize: 9
                                font.letterSpacing: 2
                            }
                        }

                        Text {
                            text: modelData.signal + "%"
                            color: page.nText
                            font.family: page.fDot
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Rectangle {
                            visible: modelData.inUse
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            color: wHover.containsMouse ? page.nRed : "transparent"
                            border.width: 1
                            border.color: page.nDim
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: wHover.containsMouse ? page.nWhite : page.nText
                                font.pixelSize: 16
                            }

                            MouseArea {
                                id: wHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Net.disconnect()
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: Net.askFor !== ""
                implicitHeight: visible ? 64 : 0
                color: page.nSurface
                border.width: 1
                border.color: page.nRed

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Text {
                        text: "PWD"
                        color: page.nRed
                        font.family: page.fMonoStr
                        font.pixelSize: 11
                        font.letterSpacing: 2
                        font.bold: true
                    }

                    TextInput {
                        id: pwInput
                        Layout.fillWidth: true
                        echoMode: TextInput.Password
                        color: page.nWhite
                        font.family: page.fMonoStr
                        font.pixelSize: 14
                        selectionColor: page.nRed
                        focus: Net.askFor !== ""

                        Keys.onReturnPressed: {
                            Net.connect(Net.askFor, pwInput.text)
                            pwInput.text = ""
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        color: page.nWhite

                        Text {
                            anchors.centerIn: parent
                            text: "→"
                            color: page.nBlack
                            font.pixelSize: 18
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Net.connect(Net.askFor, pwInput.text)
                                pwInput.text = ""
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
