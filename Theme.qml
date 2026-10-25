pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property string walFile: Quickshell.env("HOME") + "/.cache/wal/colors.json"

    FileView {
        path: root.walFile
        watchChanges: true
        onFileChanged: reload()
        adapter: JsonAdapter {
            id: wal
            property JsonObject special: JsonObject {
                property string background: "#0b1514"
                property string foreground: "#cfe3df"
            }
            property JsonObject colors: JsonObject {
                property string color14: "#6fd6c5"
            }
        }
    }

    readonly property color bg: wal.special.background
    readonly property color fg: wal.special.foreground
    readonly property color accent: Qt.color(wal.colors.color14)
    readonly property color barBg: Qt.rgba(bg.r, bg.g, bg.b, 0.85)
    readonly property color surfaceHi: Qt.rgba(fg.r, fg.g, fg.b, 0.1)
    readonly property color line: Qt.rgba(fg.r, fg.g, fg.b, 0.2)
}
