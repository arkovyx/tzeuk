import QtQuick
import QtQuick.Layouts
import "../../../themes"
import "../../../services"

RowLayout {
    spacing: 16

    Repeater {
        model: [
            { action: "prev",   icon: "󰒮",
              canDo: MediaPlayer.player ? MediaPlayer.player.canGoPrevious : false,
              size: 40, primary: false },
            { action: "toggle",
              icon: MediaPlayer.isPlaying ? "󰏤" : "󰐊",
              canDo: MediaPlayer.player ? MediaPlayer.player.canTogglePlaying : false,
              size: 56, primary: true },
            { action: "next",   icon: "󰒭",
              canDo: MediaPlayer.player ? MediaPlayer.player.canGoNext : false,
              size: 40, primary: false }
        ]

        delegate: Rectangle {
            required property var modelData
            required property int index

            Layout.preferredWidth: modelData.size
            Layout.preferredHeight: modelData.size
            radius: width / 2

            color: hover.containsMouse
                ? (modelData.primary ? Qt.lighter(Theme.accent, 1.15)
                                     : Theme.fade(Theme.fg, 0.10))
                : (modelData.primary ? Theme.accent
                                     : Theme.fade(Theme.fg, 0.05))

            border.color: modelData.primary ? Theme.accent : Theme.fade(Theme.fg, 0.15)
            border.width: 1
            opacity: modelData.canDo ? 1.0 : 0.40

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: modelData.icon
                color: modelData.primary ? Theme.bg : Theme.fg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: modelData.primary ? 22 : 16
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: modelData.canDo
                onClicked: {
                    if (!MediaPlayer.player) return
                    if (modelData.action === "prev")   MediaPlayer.player.previous()
                    if (modelData.action === "next")   MediaPlayer.player.next()
                    if (modelData.action === "toggle") MediaPlayer.player.togglePlaying()
                }
            }
        }
    }
}
