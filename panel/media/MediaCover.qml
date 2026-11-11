import QtQuick
import QtQuick.Effects
import "../../themes"
import "../../services"

Item {
    id: root

    Item {
        anchors.fill: parent
        rotation: MediaPlayer.discAngle

        // Disc border ring
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Theme.fade(Theme.fg, 0.06)
            border.color: MediaPlayer.isPlaying ? Theme.accent : Theme.fade(Theme.fg, 0.20)
            border.width: 2
            Behavior on border.color { ColorAnimation { duration: 400 } }
        }

        // Circular-clipped art — the whole content below gets masked to a circle
        Item {
            anchors.fill: parent
            anchors.margins: 5
            layer.enabled: true

            // Fallback bg (also masked to circle)
            Rectangle {
                anchors.fill: parent
                color: Theme.fade(Theme.fg, 0.08)
            }

            // Album art (square; the layer mask clips it to a circle)
            Image {
                anchors.fill: parent
                source: (MediaPlayer.player && MediaPlayer.player.trackArtUrl)
                    ? MediaPlayer.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: MediaPlayer.hasMedia
            }

            // Circular mask
            Rectangle {
                id: artMask
                anchors.fill: parent
                radius: width / 2
                color: "black"
                visible: false
                layer.enabled: true
            }

            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: artMask
            }
        }

        // Center spindle hole
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.16
            height: width
            radius: width / 2
            color: Theme.bg
            border.color: Theme.fade(Theme.fg, 0.30)
            border.width: 1
            z: 2
        }
    }
}
