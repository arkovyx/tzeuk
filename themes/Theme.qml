pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    // ============================================
    // FONTS
    // ============================================
    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property string sans: "JetBrainsMono Nerd Font"

    // ============================================
    // NOTHING OS PALETTE (hardcoded, always dark)
    // ============================================
    readonly property color bg: "#000000"
    readonly property color fg: "#ffffff"
    readonly property color accent: "#d71921"
    readonly property color barBg: Qt.rgba(0, 0, 0, 0.85)
    readonly property color surfaceHi: Qt.rgba(1, 1, 1, 0.10)
    readonly property color line: Qt.rgba(1, 1, 1, 0.20)
    readonly property color dim: Qt.rgba(1, 1, 1, 0.50)
    readonly property color err: "#d71921"

    // ============================================
    // PY WAL (still available for anything that wants it)
    // ============================================
    readonly property string walFile: Quickshell.env("HOME") + "/.cache/wal/colors.json"

    FileView {
        id: walFileView
        path: root.walFile
        watchChanges: true
        onFileChanged: reload()
        adapter: JsonAdapter {
            id: wal
            property JsonObject special: JsonObject {
                property string background: "#000000"
                property string foreground: "#ffffff"
            }
            property JsonObject colors: JsonObject {
                property string color14: "#d71921"
            }
        }
    }

    readonly property color walBg: wal.special.background
    readonly property color walFg: wal.special.foreground
    readonly property color walAccent: Qt.color(wal.colors.color14)

    // ============================================
    // ICONS
    // ============================================
    function cp(c) { c -= 0x10000; return String.fromCharCode(0xD800 + (c >> 10), 0xDC00 + (c & 0x3FF)) }
    readonly property string iClock: cp(0xF0954)
    readonly property string iCal: cp(0xF00ED)
    readonly property string iVolHigh: cp(0xF057E)
    readonly property string iVolMed: cp(0xF0580)
    readonly property string iVolLow: cp(0xF057F)
    readonly property string iVolOff: cp(0xF0581)
    readonly property string iWifiHigh: cp(0xF0928)
    readonly property string iWifiMed: cp(0xF0925)
    readonly property string iWifiLow: cp(0xF0922)
    readonly property string iWifiOff: cp(0xF05AA)
    readonly property string iBell: cp(0xF009A)
    readonly property string iBellOff: cp(0xF009B)
    readonly property string iBatFull: cp(0xF0079)
    readonly property string iBatCharging: cp(0xF0084)
    readonly property string iCpu: cp(0xF061A)
    readonly property string iMem: cp(0xF035B)

    function wifiIcon(sig) {
        return sig >= 75 ? iWifiHigh : sig >= 50 ? iWifiMed : sig >= 25 ? iWifiLow : iWifiOff
    }

    // ============================================
    // LAUNCHER COMPATIBILITY
    // ============================================
    readonly property color bright: "#ffffff"
    readonly property color ink: "#000000"
    readonly property color warn: "#f5a97f"
    readonly property color live: accent
    readonly property color mute: dim
    readonly property color fill: surfaceHi
    readonly property color fillFg: fg

    readonly property int fast: 150
    readonly property int move: 250
    readonly property var settle: [0.25, 1, 0.5, 1]
    readonly property var leave: [0.5, 0, 0.75, 0]

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function soft(c) { return Qt.rgba(c.r, c.g, c.b, 0.15) }
    function ms(v) { return v }
    function r(v) { return v }

    function along(colors, t) {
        var n = colors.length - 1
        var i = Math.floor(t * n)
        var f = t * n - i
        if (i >= n) return colors[n]
        var c1 = Qt.color(colors[i])
        var c2 = Qt.color(colors[i + 1])
        return Qt.rgba(c1.r + (c2.r - c1.r) * f, c1.g + (c2.g - c1.g) * f, c1.b + (c2.b - c1.b) * f, 1)
    }

    function scaleFor(screen) {
        return screen ? Math.max(1, screen.devicePixelRatio) : 1
    }

    function focusedScreen() {
        var m = Hyprland.focusedMonitor
        var l = Quickshell.screens
        if (m) for (var i = 0; i < l.length; i++) if (l[i].name === m.name) return l[i]
        return l.length ? l[0] : null
    }

    // ============================================
    // GLYPH PICKER ADDITIONS
    // ============================================
    // Surfaces (solid, card is opaque for Nothing)
    readonly property color s1: "#0a0a0a"
    readonly property color s2: "#171717"
    readonly property color s3: "#252525"
    readonly property real  panelAlpha: 1.0

    // Scrim (dimmed backdrop)
    readonly property color scrim: "#000000b3"

    // Secondary text
    readonly property color grey: "#b0b0b0"

    // Typography aliases (CharPicker calls Theme.ui / Theme.nf)
    readonly property string ui: sans
    readonly property string nf: font

    // Motion aliases
    readonly property int t: move
    readonly property var glide: settle

    // Alpha helper (aurora name)
    function fade(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    // Picker icons — swap any that don't match your taste
    readonly property string iGrid:      cp(0xF0558)   // view-grid
    readonly property string iHistory:   cp(0xF02DA)   // history
    readonly property string iEmoji:     cp(0xF0785)   // emoticon-outline
    readonly property string iFontGlyph: cp(0xF06D6)   // format-font
    readonly property string iSigma:     cp(0xF0AA0)   // math-related
    readonly property string iKaomoji:   cp(0xF0BDB)   // emoticon
    readonly property string iFancy:     cp(0xF0280)   // format-text
    readonly property string iSearch:    cp(0xF0349)   // magnify
    readonly property string iClose:     cp(0xF0156)   // close
    readonly property string iBuffer:    cp(0xF018F)   // content-copy
}
