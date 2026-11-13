import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import "../themes"

PanelWindow {
    id: win
    property bool opened: false
    property bool grabActive: false
    property string activeTab: "home"

    signal tabChanged(string name)
    signal closeRequested()

    visible: opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tzeuk-panel"
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    FontLoader { id: fDoto; source: "../fonts/Doto.ttf" }
    FontLoader { id: fMono; source: "../fonts/SpaceMono-Regular.ttf" }
    FontLoader { id: fGrotesk; source: "../fonts/SpaceGrotesk-Regular.otf" }

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

    onOpenedChanged: {
        if (opened) grabDelay.start()
        else grabActive = false
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

    MouseArea {
        anchors.fill: parent
        onClicked: win.closeRequested()
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        opacity: win.opened ? 0.5 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Rectangle {
        id: panel
        width: 1100
        height: 700
        anchors.centerIn: parent
        color: win.nBlack
        border.width: 1
        border.color: win.nDim
        scale: win.opened ? 1.0 : 0.96
        opacity: win.opened ? 1.0 : 0.0
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        focus: true
        Keys.onEscapePressed: win.closeRequested()

        MouseArea { anchors.fill: parent }

        Canvas {
            anchors.fill: parent
            opacity: 0.03
            property color dotColor: Theme.fg
            onDotColorChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d")
                ctx.fillStyle = Qt.rgba(dotColor.r, dotColor.g, dotColor.b, 1)
                for (var x = 0; x < width; x += 22) {
                    for (var y = 0; y < height; y += 22) {
                        ctx.beginPath()
                        ctx.arc(x, y, 1, 0, Math.PI * 2)
                        ctx.fill()
                    }
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ===== SIDEBAR =====
            Item {
                Layout.preferredWidth: 220
                Layout.fillHeight: true

                Rectangle {
                    id: closeBtn
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 24
                    width: 44
                    height: 44
                    radius: 22
                    color: closeMouse.containsMouse ? win.nDim : "transparent"
                    border.width: 1
                    border.color: win.nDim

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: closeMouse.containsMouse ? win.nRed : win.nWhite
                        font.family: win.fMonoStr
                        font.pixelSize: 24
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.closeRequested()
                    }
                }

                Rectangle {
                    anchors.left: closeBtn.right
                    anchors.leftMargin: 14
                    anchors.verticalCenter: closeBtn.verticalCenter
                    width: 8
                    height: 8
                    radius: 4
                    color: win.nRed
                    SequentialAnimation on opacity {
                        running: win.opened
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.2; duration: 900 }
                        NumberAnimation { to: 1.0; duration: 900 }
                    }
                }

                Text {
                    id: tzeukText
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    anchors.top: closeBtn.bottom
                    anchors.topMargin: 40
                    text: "TZEUK"
                    color: win.nWhite
                    font.family: win.fDot
                    font.pixelSize: 32
                    font.bold: true
                    font.letterSpacing: 6
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    anchors.top: tzeukText.bottom
                    anchors.topMargin: 12
                    width: 32
                    height: 2
                    color: win.nRed
                }

                Column {
                    anchors.top: tzeukText.bottom
                    anchors.topMargin: 48
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 0

                    Repeater {
                        model: [
                            { id: "home", label: "HOME" },
                            { id: "audio", label: "AUDIO" },
                            { id: "net", label: "NETWORK" },
                            { id: "bt", label: "BLUETOOTH" },
                            { id: "sys", label: "SYSTEM" },
                            { id: "notif", label: "NOTIFS" }
                        ]

                        delegate: Item {
                            id: tabItem
                            required property var modelData
                            readonly property bool isActive: win.activeTab === tabItem.modelData.id

                            width: parent.width
                            height: 50

                            Rectangle {
                                anchors.fill: parent
                                color: tabMouse.containsMouse ? win.nSurface : "transparent"
                            }

                            Rectangle {
                                width: 3
                                height: tabItem.height - 16
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                color: win.nRed
                                visible: tabItem.isActive
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 28
                                anchors.verticalCenter: parent.verticalCenter
                                text: tabItem.modelData.label
                                color: tabItem.isActive ? win.nWhite : win.nText
                                font.family: win.fDot
                                font.pixelSize: 18
                                font.letterSpacing: 3
                                font.bold: tabItem.isActive
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.tabChanged(tabItem.modelData.id)
                            }
                        }
                    }
                }

                Text {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 24
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    text: "v0.2.0"
                    color: win.nText
                    font.family: win.fMonoStr
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: win.nRed
                opacity: 0.4
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Item {
                    anchors.fill: parent
                    anchors.margins: 40

                    Loader {
                        id: contentLoader
                        anchors.fill: parent
                        source: {
                            if (win.activeTab === "home")  return Qt.resolvedUrl("tabs/HomePage.qml")
                            if (win.activeTab === "audio") return Qt.resolvedUrl("tabs/AudioPage.qml")
                            if (win.activeTab === "net")   return Qt.resolvedUrl("tabs/NetPage.qml")
                            if (win.activeTab === "bt")    return Qt.resolvedUrl("tabs/BtPage.qml")
                            if (win.activeTab === "sys")   return Qt.resolvedUrl("tabs/SysPage.qml")
                            if (win.activeTab === "notif") return Qt.resolvedUrl("tabs/NotifPage.qml")
                            return ""
                        }
                        onStatusChanged: {
                            if (status === Loader.Error) {
                                console.error("=== LOADER ERROR === tab:", win.activeTab)
                            } else if (status === Loader.Ready) {
                                console.log("=== LOADER READY === tab:", win.activeTab)
                            }
                        }
                    }
                }
            }
        }
    }
}
