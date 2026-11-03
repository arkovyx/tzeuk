import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

Item {
    id: page

    FontLoader { id: fDoto; source: "../../fonts/Doto[ROND,wght].ttf" }
    FontLoader { id: fMono; source: "../../fonts/SpaceMono-Regular.ttf" }
    FontLoader { id: fGrotesk; source: "../../fonts/SpaceGrotesk-Regular.otf" }

    readonly property string fDot: fDoto.name !== "" ? fDoto.name : "monospace"
    readonly property string fMonoStr: fMono.name !== "" ? fMono.name : "monospace"
    readonly property string fSans: fGrotesk.name !== "" ? fGrotesk.name : "sans-serif"

    readonly property color nBlack: "#000000"
    readonly property color nWhite: "#ffffff"
    readonly property color nRed: "#d71921"
    readonly property color nDim: "#2a2a2a"
    readonly property color nSurface: "#0d0d0d"
    readonly property color nText: "#666666"

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
        contentWidth: width
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 20

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "BLUETOOTH"
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

                // Scan
                Rectangle {
                    visible: adapter !== null && adapter.enabled
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    color: scanHover.containsMouse ? page.nDim : page.nSurface
                    border.width: 1
                    border.color: page.nDim

                    Text {
                        anchors.centerIn: parent
                        text: "↻"
                        color: adapter && adapter.discovering ? page.nRed : page.nWhite
                        font.pixelSize: 20
                    }

                    MouseArea {
                        id: scanHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (adapter) adapter.discovering = !adapter.discovering
                    }
                }

                // Toggle
                Rectangle {
                    visible: adapter !== null
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 40
                    Layout.leftMargin: 8
                    color: (adapter && adapter.enabled) ? page.nWhite : page.nSurface
                    border.width: 1
                    border.color: page.nDim
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: (adapter && adapter.enabled) ? "ON" : "OFF"
                        color: (adapter && adapter.enabled) ? page.nBlack : page.nText
                        font.family: page.fSans
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 2
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (adapter) adapter.enabled = !adapter.enabled
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: page.nDim }

            // Status
            Text {
                Layout.fillWidth: true
                text: !adapter ? "▸ No bluetooth adapter"
                    : (!adapter.enabled ? "▸ Bluetooth is off"
                    : (adapter.discovering ? "▸ Scanning for devices..." : "▸ Ready"))
                color: (adapter && adapter.enabled) ? page.nRed : page.nText
                font.family: page.fMonoStr
                font.pixelSize: 12
                font.letterSpacing: 2
            }

            // Devices
            Text {
                text: "DEVICES"
                color: page.nRed
                font.family: page.fSans
                font.pixelSize: 11
                font.letterSpacing: 4
                font.bold: true
                Layout.topMargin: 4
            }

            Text {
                visible: !adapter || !adapter.enabled
                Layout.fillWidth: true
                Layout.topMargin: 20
                text: "▸ Enable bluetooth to see devices"
                color: page.nText
                font.family: page.fMonoStr
                font.pixelSize: 13
                font.italic: true
            }

            Repeater {
                model: adapter && adapter.enabled ? page.devices : []
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 68
                    color: modelData.connected ? page.nSurface : "transparent"
                    border.width: 1
                    border.color: modelData.connected ? page.nWhite : page.nDim

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.connected) modelData.disconnect()
                            else if (page.paired(modelData)) modelData.connect()
                            else { modelData.trusted = true; modelData.pair() }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 16

                        Text {
                            text: page.deviceIcon(modelData)
                            color: modelData.connected ? page.nRed : page.nWhite
                            font.family: page.fMonoStr
                            font.pixelSize: 22
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: (modelData.name || modelData.address).toUpperCase()
                                color: page.nWhite
                                font.family: page.fSans
                                font.pixelSize: 13
                                font.bold: modelData.connected
                                elide: Text.ElideRight
                            }

                            Text {
                                text: {
                                    if (modelData.state === 2) return "CONNECTING..."
                                    if (modelData.pairing) return "PAIRING..."
                                    if (modelData.connected) {
                                        var b = modelData.batteryAvailable ? "  ·  " + Math.round(modelData.battery * 100) + "%" : ""
                                        return "CONNECTED" + b
                                    }
                                    return page.paired(modelData) ? "PAIRED" : "AVAILABLE"
                                }
                                color: modelData.connected ? page.nRed : page.nText
                                font.family: page.fMonoStr
                                font.pixelSize: 9
                                font.letterSpacing: 2
                            }
                        }

                        // Forget
                        Rectangle {
                            visible: page.paired(modelData)
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            color: fHover.containsMouse ? page.nRed : "transparent"
                            border.width: 1
                            border.color: page.nDim
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: fHover.containsMouse ? page.nWhite : page.nText
                                font.pixelSize: 16
                            }

                            MouseArea {
                                id: fHover
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
                Layout.topMargin: 20
                text: "▸ No devices found"
                color: page.nText
                font.family: page.fMonoStr
                font.pixelSize: 13
                font.italic: true
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
