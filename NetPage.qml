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

                // Refresh
                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: m1.containsMouse ? Theme.surfaceHi : "transparent"
                    Text { anchors.centerIn: parent; text: "󰑐"; color: Net.scanning ? Theme.accent : Theme.fg; font.family: Theme.font; font.pixelSize: 14 }
                    MouseArea { id: m1; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Net.rescan() }
                }

                // WiFi toggle
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
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Net.setWifi(!Net.wifiEnabled) }
                }
            }

            // --- Status ---
            Text {
                Layout.fillWidth: true
                text: !Net.wifiEnabled
                    ? "Wi-Fi is off"
                    : (Net.connected !== "" ? "Connected to " + Net.connected : "Not connected")
                color: Net.connected !== "" && Net.wifiEnabled ? Theme.accent : Theme.dim
                font.family: Theme.font
                font.pixelSize: 11
            }

            // --- Manage button ---
            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 10
                color: manageHover.containsMouse ? Theme.accent : Theme.surfaceHi
                Behavior on color { ColorAnimation { duration: 150 } }
                border.width: 1
                border.color: Theme.line

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 10
                    Text {
                        text: "󰆍"
                        color: manageHover.containsMouse ? Theme.bg : Theme.accent
                        font.family: Theme.font
                        font.pixelSize: 16
                    }
                    Text {
                        text: "Manage connections (nmtui)"
                        color: manageHover.containsMouse ? Theme.bg : Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.bold: true
                    }
                }
                MouseArea {
                    id: manageHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Net.openNmtui()
                }
            }

            // --- Divider ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.line
            }

            // --- Network list (read-only) ---
            Text {
                text: "AVAILABLE NETWORKS"
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 2
            }

            Text {
                visible: !Net.wifiEnabled
                Layout.fillWidth: true
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
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 44
                        radius: 10
                        color: modelData.inUse ? Theme.surfaceHi : "transparent"
                        border.width: modelData.inUse ? 1 : 0
                        border.color: Theme.accent

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Text {
                                text: modelData.signal > 75 ? Theme.iWifiHigh
                                    : modelData.signal > 50 ? Theme.iWifiMed
                                    : modelData.signal > 25 ? Theme.iWifiLow
                                    : Theme.iWifiOff
                                color: modelData.inUse ? Theme.accent : Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 16
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    text: modelData.ssid
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                    font.bold: modelData.inUse
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.inUse ? "Connected"
                                        : (modelData.security === "" || modelData.security === "--" ? "Open" : modelData.security)
                                    color: modelData.inUse ? Theme.accent : Theme.dim
                                    font.family: Theme.font
                                    font.pixelSize: 9
                                }
                            }

                            Text {
                                text: modelData.signal + "%"
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: 10
                            }
                        }
                    }
                }

                Text {
                    visible: Net.wifiEnabled && Net.networks.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    horizontalAlignment: Text.AlignHCenter
                    text: "No networks found"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.italic: true
                }
            }

            Item { Layout.preferredHeight: 10 }
        }
    }
}
