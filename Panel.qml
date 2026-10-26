import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: win
    property bool opened: false
    property bool grabActive: false
    property string activeTab: "home"

    signal tabChanged(string name)
    signal closeRequested()

    visible: opened
    anchors { top: true; right: true }
    margins { top: 50; right: 12 }
    implicitWidth: 480
    implicitHeight: 600
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tzeuk-panel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    onOpenedChanged: {
        if (opened) {
            grabDelay.start()
        } else {
            grabActive = false
        }
    }

    Timer {
        id: grabDelay
        interval: 150
        onTriggered: win.grabActive = win.opened
    }

    HyprlandFocusGrab {
        windows: [win]
        active: win.grabActive
        onCleared: win.closeRequested()
    }

    // --- Caelestia Style Animation (Slide + Fade) ---
    Item {
        anchors.fill: parent

        // Animate the scale and opacity when the panel opens
        scale: win.opened ? 1.0 : 0.95
        opacity: win.opened ? 1.0 : 0.0

        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

        // Glassmorphism Background
        Rectangle {
            anchors.fill: parent
            color: Theme.bg
            opacity: 0.92 // Slightly transparent to see your wallpaper
            radius: 20
            border.width: 1
            border.color: Theme.line

            // Drop shadow effect (Caelestia style)
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                radius: 21
                color: "transparent"
                border.width: 1
                border.color: Theme.accent
                opacity: 0.3
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // --- Sidebar Tabs ---
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 80
                color: "transparent"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: 20
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "home", icon: "󰋜", label: "Home" },
                            { id: "audio", icon: Theme.iVolHigh, label: "Audio" },
                            { id: "net", icon: Theme.iWifiHigh, label: "Net" },
                            { id: "bt", icon: "󰂯", label: "BT" },
                            { id: "sys", icon: "󰍛", label: "Sys" },
                            { id: "notif", icon: Theme.iBell, label: "Notifs" }
                        ]
                        delegate: Item {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 56

                            readonly property bool isActive: win.activeTab === modelData.id

                            Rectangle {
                                anchors.centerIn: parent
                                width: 56
                                height: 56
                                radius: 16
                                color: isActive ? Theme.surfaceHi : (mouse.containsMouse ? Theme.surfaceHi : "transparent")
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.icon
                                        color: isActive ? Theme.accent : Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: 20
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.label
                                        color: isActive ? Theme.accent : Theme.dim
                                        font.family: Theme.font
                                        font.pixelSize: 10
                                        font.bold: isActive
                                    }
                                }
                            }

                            MouseArea {
                                id: mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.tabChanged(modelData.id)
                            }
                        }
                    }
                }
            }

            // --- Content Area ---
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"

                // We will replace these with the actual tab files later
                Loader {
                    anchors.fill: parent
                    sourceComponent: {
                        if (win.activeTab === "sys") return sysPage
                        return null
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: win.activeTab !== "sys"
                    text: win.activeTab === "home" ? "Home Tab (Coming Soon)"
                        : win.activeTab === "audio" ? "Audio Tab (Coming Soon)"
                        : win.activeTab === "net" ? "WiFi Tab (Coming Soon)"
                        : win.activeTab === "bt" ? "Bluetooth Tab (Coming Soon)"
                        : win.activeTab === "notif" ? "Notifications Tab (Coming Soon)"
                        : ""
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 16
                }
            }
        }
    }
}
