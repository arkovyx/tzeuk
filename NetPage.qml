import QtQuick
import QtQuick.Layouts

Item {
    id: page

    // Tell the backend we are active (faster polling)
    Component.onCompleted: Net.active = true
    Component.onDestruction: Net.active = false

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
            spacing: 16

            // --- Header ---
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "NETWORK"
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: 16
                    font.bold: true
                    font.letterSpacing: 3
                }

                Item { Layout.fillWidth: true }

                // Refresh Button
                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: m1.containsMouse ? Theme.surfaceHi : "transparent"
                    Text { anchors.centerIn: parent; text: "󰑐"; color: Net.scanning ? Theme.accent : Theme.fg; font.family: Theme.font }
                    MouseArea { id: m1; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Net.rescan() }
                }

                // WiFi Toggle
                Rectangle {
                    width: 44; height: 24; radius: 12
                    color: Net.wifiEnabled ? Theme.accent : Theme.surfaceHi
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Rectangle {
                        width: 18; height: 18; radius: 9
                        y: 3
                        x: Net.wifiEnabled ? parent.width - width - 3 : 3
                        color: Net.wifiEnabled ? Theme.bg : Theme.fg
                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuint } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Net.setWifi(!Net.wifiEnabled)
                    }
                }
            }

            // --- Wired / Tethering ---
            ColumnLayout {
                visible: Net.wiredDevs.length > 0
                Layout.fillWidth: true
                spacing: 6

                Text { text: "WIRED"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 10; font.bold: true; font.letterSpacing: 2 }

                Repeater {
                    model: Net.wiredDevs
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 48
                        radius: 10
                        color: Theme.surfaceHi
                        border.width: 1
                        border.color: Theme.line

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Text {
                                text: modelData.usb ? "󰢹" : "󰈀"
                                color: Theme.accent
                                font.family: Theme.font
                                font.pixelSize: 18
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text { text: modelData.name; color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.bold: true }
                                Text { text: modelData.dev + (modelData.ip !== "" ? " · " + modelData.ip : ""); color: Theme.dim; font.family: Theme.font; font.pixelSize: 10 }
                            }

                            Rectangle {
                                visible: Net.portal && Net.portalNet === modelData.name
                                width: 28; height: 28; radius: 8
                                color: Theme.accent
                                Text { anchors.centerIn: parent; text: "󰍃"; color: Theme.bg; font.family: Theme.font }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Net.openPortal() }
                            }

                            Rectangle {
                                width: 28; height: 28; radius: 8
                                color: m2.containsMouse ? Theme.err : "transparent"
                                Text { anchors.centerIn: parent; text: "󰅖"; color: m2.containsMouse ? Theme.bg : Theme.fg; font.family: Theme.font }
                                MouseArea { id: m2; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Net.disconnectDev(modelData.dev) }
                            }
                        }
                    }
                }
            }

            // Error / Message
            Text {
                Layout.fillWidth: true
                visible: Net.message !== ""
                text: Net.message
                color: Theme.err
                font.family: Theme.font
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            // --- Wireless List ---
            Text { text: "NETWORKS"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 10; font.bold: true; font.letterSpacing: 2 }

            Text {
                visible: !Net.wifiEnabled
                Layout.fillWidth: true
                Layout.topMargin: 10
                horizontalAlignment: Text.AlignHCenter
                text: "Wi-Fi is turned off"
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 13
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: Net.wifiEnabled

                Repeater {
                    model: Net.wifiEnabled ? Net.networks : []
                    delegate: ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 6

                        // Network Row
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            radius: 10
                            color: modelData.inUse ? Theme.surfaceHi : (rowHover.containsMouse ? Theme.surfaceHi : "transparent")
                            border.width: modelData.inUse ? 1 : 0
                            border.color: Theme.accent

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Text {
                                    text: modelData.signal > 75 ? Theme.iWifiHigh : modelData.signal > 50 ? Theme.iWifiMed : modelData.signal > 25 ? Theme.iWifiLow : Theme.iWifiOff
                                    color: modelData.inUse ? Theme.accent : Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: 18
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text { text: modelData.ssid; color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.bold: modelData.inUse }
                                    Text {
                                        text: modelData.inUse ? "Connected" : (modelData.saved ? "Saved" : (modelData.security === "" ? "Open" : modelData.security))
                                        color: modelData.inUse ? Theme.accent : Theme.dim
                                        font.family: Theme.font
                                        font.pixelSize: 10
                                    }
                                }

                                Text { text: modelData.signal + "%"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11 }

                                // Lock icon
                                Text { visible: modelData.security !== "" && !modelData.inUse; text: "󰌾"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 12 }

                                // Disconnect Button
                                Rectangle {
                                    visible: modelData.inUse
                                    width: 28; height: 28; radius: 8
                                    color: m3.containsMouse ? Theme.err : "transparent"
                                    Text { anchors.centerIn: parent; text: "󰅖"; color: m3.containsMouse ? Theme.bg : Theme.fg; font.family: Theme.font }
                                    MouseArea { id: m3; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Net.disconnect() }
                                }
                            }

                            MouseArea {
                                id: rowHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Net.connectTo(modelData)
                            }
                        }

                        // Password Prompt Dropdown
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: visible ? 44 : 0
                            visible: Net.askFor === modelData.ssid
                            radius: 10
                            color: Theme.surface
                            border.width: 1
                            border.color: Theme.accent
                            onVisibleChanged: if (visible) passInput.forceActiveFocus()

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                TextInput {
                                    id: passInput
                                    Layout.fillWidth: true
                                    echoMode: TextInput.Password
                                    color: Theme.fg
                                    selectionColor: Theme.accent
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                    clip: true

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: passInput.text === ""
                                        text: "Password..."
                                        color: Theme.dim
                                        font.family: Theme.font
                                        font.pixelSize: 12
                                    }

                                    Keys.onReturnPressed: {
                                        Net.connect(modelData.ssid, text)
                                        Net.askFor = ""
                                    }
                                }

                                Rectangle {
                                    width: 28; height: 28; radius: 8
                                    color: Theme.accent
                                    Text { anchors.centerIn: parent; text: "󰁕"; color: Theme.bg; font.family: Theme.font }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Net.connect(modelData.ssid, passInput.text)
                                            Net.askFor = ""
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
