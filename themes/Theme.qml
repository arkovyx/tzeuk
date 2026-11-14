pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property string fontDoto: "Doto"
    readonly property string fontSans: "Space Grotesk"
    readonly property string fontBold: "Space Grotesk"
    readonly property string fontMono: "Space Mono"
    readonly property string font: fontMono
    readonly property string sans: fontSans
    readonly property string ui: sans
    readonly property string nf: "JetBrainsMono Nerd Font"

    // ═══ IRIS SOURCE ═══
    FileView {
        id: irisView
        path: Quickshell.env("HOME") + "/.cache/iris/colors.json"
        watchChanges: true
        onFileChanged: reload()
        adapter: JsonAdapter {
            id: iris
            property string image: ""
            property color bg: "#000000"
            property color fg: "#ffffff"
            property color accent: "#d71921"
            property color surface: "#0a0a0a"
            property color dim: "#666666"
            property color red: "#d71921"
            property color green: "#00ff88"
            property color yellow: "#ffcc00"
            property color syntax_keyword: "#d71921"
            property color syntax_string: "#ffffff"
            property color syntax_func: "#d71921"
            property color syntax_type: "#d71921"
            property color syntax_const: "#d71921"
            property color syntax_comment: "#666666"
            property color syntax_param: "#d71921"
            property color syntax_operator: "#d71921"
        }
    }

    function shiftL(color, delta) {
        var h = color.hslHue
        var s = color.hslSaturation
        var l = Math.max(0, Math.min(1, color.hslLightness + delta))
        return Qt.hsla(h, s, l, 1.0)
    }

    // ═══ CORE PALETTE ═══
    readonly property color bg: iris.bg
    readonly property color fg: iris.fg
    readonly property color accent: iris.accent
    readonly property color err: iris.red
    readonly property color surfaceHi: iris.surface
    readonly property color line: shiftL(iris.surface, 0.06)
    readonly property color dim: iris.dim
    readonly property color barBg: Qt.rgba(iris.bg.r, iris.bg.g, iris.bg.b, 0.85)
    readonly property color nText: iris.dim

    readonly property color nBlack: bg
    readonly property color nWhite: fg
    readonly property color nRed: accent
    readonly property color nDim: line
    readonly property color nSurface: surfaceHi

    // ═══ M3 (derived from iris for backwards compat) ═══
    readonly property color m3Primary: iris.accent
    readonly property color m3OnPrimary: iris.bg
    readonly property color m3PrimaryContainer: shiftL(iris.surface, 0.02)
    readonly property color m3OnPrimaryContainer: iris.fg
    readonly property color m3Secondary: iris.dim
    readonly property color m3OnSecondary: iris.bg
    readonly property color m3SecondaryContainer: shiftL(iris.surface, 0.04)
    readonly property color m3OnSecondaryContainer: iris.fg
    readonly property color m3Tertiary: iris.syntax_keyword
    readonly property color m3OnTertiary: iris.bg
    readonly property color m3TertiaryContainer: shiftL(iris.surface, 0.04)
    readonly property color m3OnTertiaryContainer: iris.fg
    readonly property color m3Surface: iris.surface
    readonly property color m3SurfaceLowest: iris.bg
    readonly property color m3SurfaceLow: shiftL(iris.surface, -0.02)
    readonly property color m3SurfaceContainer: iris.surface
    readonly property color m3SurfaceHigh: shiftL(iris.surface, 0.04)
    readonly property color m3SurfaceHighest: shiftL(iris.surface, 0.08)
    readonly property color m3OnSurface: iris.fg
    readonly property color m3OnSurfaceVariant: iris.dim
    readonly property color m3Outline: iris.dim
    readonly property color m3OutlineVariant: shiftL(iris.dim, -0.10)
    readonly property color m3Err: iris.red
    readonly property color m3OnErr: iris.bg

    // ═══ ICONS ═══
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

    // ═══ LAUNCHER COMPAT ═══
    readonly property color bright: fg
    readonly property color ink: bg
    readonly property color warn: iris.yellow
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

    function scaleFor(screen) { return screen ? Math.max(1, screen.devicePixelRatio) : 1 }

    function focusedScreen() {
        var m = Hyprland.focusedMonitor
        var l = Quickshell.screens
        if (m) for (var i = 0; i < l.length; i++) if (l[i].name === m.name) return l[i]
        return l.length ? l[0] : null
    }

    // ═══ PANEL / GLYPH PICKER ═══
    readonly property color s1: shiftL(iris.surface, -0.02)
    readonly property color s2: iris.surface
    readonly property color s3: shiftL(iris.surface, 0.06)
    readonly property real panelAlpha: 1.0
    readonly property color scrim: Qt.rgba(iris.bg.r, iris.bg.g, iris.bg.b, 0.7)
    readonly property color grey: iris.dim
    readonly property int t: move
    readonly property var glide: settle
    function fade(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    readonly property string iGrid: cp(0xF0558)
    readonly property string iHistory: cp(0xF02DA)
    readonly property string iEmoji: cp(0xF0785)
    readonly property string iFontGlyph: cp(0xF06D6)
    readonly property string iSigma: cp(0xF0AA0)
    readonly property string iKaomoji: cp(0xF0BDB)
    readonly property string iFancy: cp(0xF0280)
    readonly property string iSearch: cp(0xF0349)
    readonly property string iClose: cp(0xF0156)
    readonly property string iBuffer: cp(0xF018F)
}
