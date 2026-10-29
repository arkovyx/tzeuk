import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

Item {
    id: page

    readonly property var adapter: Bluetooth.defaultAdapter

    Component.onCompleted: if (adapter && adapter.enabled) adapter.discovering = true
    Component.onDestruction: if (adapter) adapter.discovering = false

    function paired(d) { return d.bonded === true || d.paired === true }

    function deviceIcon(d) {
        var i = String(d.icon || "")
        if (i.indexOf("head") >= 0) return "󰋋"
        if (i.indexOf("mouse") >= 0) return "󰍽"
        if (i.indexOf("keyboard") >= 0) return "󰌌"
        if (i.indexOf("phone") >= 0) return "󰏲"
        if (i.indexOf("speaker") >= 0 || i.indexOf("audio") >= 0) return "󰓃"
        return "󰂯"
    }

    readonly property var devices: {
        var src = Bluetooth.devices.values, out = []
        var scanning = adapter ? adapter.discovering : false
        for (var i = 0; i < src.length; i++) {
            var d = src[i]
            if (d.connected || paired(d)) out.push(d)
            else if (scanning) out.push(d)
        }
        out.sort(function(a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            var pa = paired(a), pb = paired(b)
            if (pa !== pb) return pa ? -1 : 1
            return String(a.name || a.address).localeCompare(String(b.name || b.address))
        })
        return out
    }

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
                    text: "BLUETOOTH"
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: 16
                    font.bold: true
                    font.letterSpacing: 3
                }

                Item { Layout.fillWidth: true }

                // Scan button
                Rectangle {
                    visible: adapter !== null && adapter.enabled
                    width: 28; height: 28; radius: 14
                    color: scanHover.containsMouse ? Theme.surfaceHi : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        color: adapter && adapter.discovering ? Theme.accent : Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: scanHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (adapter) adapter.discovering = !adapter.discovering
                    }
                }

                // BT toggle
                Rectangle {
                    visible: adapter !== null
                    width: 44; height: 24; radius: 12
                    color: (adapter && adapter.enabled) ? Theme.accent : Theme.surfaceHi
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Rectangle {
                        width: 18; height: 18; radius: 9
                        y: 3
                        x: (adapter && adapter.enabled) ? parent.width - width - 3 : 3
                        color: (adapter && adapter.enabled) ? Theme.bg : Theme.fg
                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuint } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (adapter) adapter.enabled = !adapter.enabled
                    }
                }
            }

            // Status
            Text {
                Layout.fillWidth: true
                text: !adapter ? "No bluetooth adapter found"
                    : (!adapter.enabled ? "Bluetooth is off"
                    : (adapter.discovering ? "Scanning…" : "Ready"))
                color: (adapter && adapter.enabled) ? Theme.accent : Theme.dim
                font.family: Theme.font
                font.pixelSize: 10
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.line
            }

            Text {
                text: "DEVICES"
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 2
            }

            // Off state
            Text {
                visible: !adapter || !adapter.enabled
                Layout.fillWidth: true
                Layout.topMargin: 30
                horizontalAlignment: Text.AlignHCenter
                text: "Bluetooth is off"
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 12
            }

            // Device list
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: adapter !== null && adapter.enabled

                Repeater {
                    model: page.devices
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 50
                        radius: 10
                        color: modelData.connected ? Theme.surfaceHi : (devHover.containsMouse ? Theme.surfaceHi : "transparent")
                        border.width: modelData.connected ? 1 : 0
                        border.color: Theme.accent

                        // Row click (behind buttons)
                        MouseArea {
                            id: devHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.connected) modelData.disconnect()
                                else if (page.paired(modelData)) modelData.connect()
                                else { modelData.trusted = true; modelData.pair() }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Text {
                                text: page.deviceIcon(modelData)
                                color: modelData.connected ? Theme.accent : Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 18
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name || modelData.address
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    font.bold: modelData.connected
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: {
                                        if (modelData.state === 2) return "Connecting…"
                                        if (modelData.pairing) return "Pairing…"
                                        if (modelData.connected) {
                                            var b = modelData.batteryAvailable ? "  ·  " + Math.round(modelData.battery * 100) + "%" : ""
                                            return "Connected" + b
                                        }
                                        return page.paired(modelData) ? "Paired" : "Available"
                                    }
                                    color: modelData.connected ? Theme.accent : Theme.dim
                                    font.family: Theme.font
                                    font.pixelSize: 10
                                }
                            }

                            // Forget button — declared AFTER the row layout content so it can receive clicks
                            Rectangle {
                                visible: page.paired(modelData)
                                width: 28; height: 28; radius: 8
                                color: forgetHover.containsMouse ? Theme.err : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰆴"
                                    color: forgetHover.containsMouse ? Theme.bg : Theme.dim
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                }
                                MouseArea {
                                    id: forgetHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: modelData.forget()
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: adapter && adapter.enabled && page.devices.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 30
                    horizontalAlignment: Text.AlignHCenter
                    text: "No devices found"
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
