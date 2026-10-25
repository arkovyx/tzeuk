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
    readonly property color dim: Qt.rgba(fg.r, fg.g, fg.b, 0.5)

    function cp(c) { c -= 0x10000; return String.fromCharCode(0xD800 + (c >> 10), 0xDC00 + (c & 0x3FF)) }
    readonly property string iClock: cp(0xF0954)
    readonly property string iCal: cp(0xF00ED)
    readonly property string iWifiOff: cp(0xF05AA)
    readonly property string iBell: cp(0xF009A)
    readonly property string iBellOff: cp(0xF009B)
    readonly property string iVolHigh: cp(0xF057E)
    readonly property string iVolOff: cp(0xF0581)

        // ICONS
    // Network
    readonly property string iWifiHigh: cp(0xF0928)   // 󰤨
    readonly property string iWifiMed: cp(0xF0925)    // 󰤥
    readonly property string iWifiLow: cp(0xF0922)    // 󰤢
    readonly property string iWifiOff: cp(0xF05AA)    // 󰖪

    // Audio
    readonly property string iVolHigh: cp(0xF057E)    // 󰕾
    readonly property string iVolMed: cp(0xF0580)     // 󰖀
    readonly property string iVolLow: cp(0xF057F)     // 󰕿
    readonly property string iVolMuted: cp(0xF0581)   // 󰖁

    // Battery
    readonly property string iBatFull: cp(0xF0079)    // 󰁹
    readonly property string iBatCharging: cp(0xF0084) // 󰂄

    // System
    readonly property string iCpu: cp(0xF061A)        // 󰘚
    readonly property string iMem: cp(0xF035B)        // 󰍛
    readonly property string iCalendar: cp(0xF00ED)   // 󰃭
    readonly property string iClock: cp(0xF0954)      // 󰥔
}
