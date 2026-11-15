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

    // ═══ PYWAL SOURCE ═══
    FileView {
        id: walView
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        watchChanges: true
        onFileChanged: reload()
        adapter: JsonAdapter {
            id: wal
            property JsonObject special: JsonObject {
                property color background: "#000000"
                property color foreground: "#ffffff"
                property color cursor: "#d71921"
            }
            property JsonObject colors: JsonObject {
                property color color0: "#000000"
                property color color1: "#d71921"
                property color color2: "#00ff88"
                property color color3: "#ffcc00"
                property color color4: "#89b4fa"
                property color color5: "#cba6f7"
                property color color6: "#74c7ec"
                property color color7: "#ffffff"
                property color color8: "#333333"
                property color color9: "#d71921"
                property color color10: "#00ff88"
                property color color11: "#ffcc00"
                property color color12: "#89b4fa"
                property color color13: "#cba6f7"
                property color color14: "#74c7ec"
                property color color15: "#ffffff"
            }
        }
    }

    // ═══ CORE PALETTE ═══
    readonly property color bg: wal.special.background
    readonly property color fg: wal.special.foreground
    readonly property color accent: wal.colors.color1
    readonly property color err: wal.colors.color1
    readonly property color surfaceHi: Qt.rgba(fg.r, fg.g, fg.b, 0.10)
    readonly property color line: Qt.rgba(fg.r, fg.g, fg.b, 0.20)
    readonly property color dim: Qt.rgba(fg.r, fg.g, fg.b, 0.50)
    readonly property color barBg: Qt.rgba(bg.r, bg.g, bg.b, 0.85)
    readonly property color nText: Qt.rgba(fg.r, fg.g, fg.b, 0.40)

    readonly property color nBlack: bg
    readonly property color nWhite: fg
    readonly property color nRed: accent
    readonly property color nDim: line
    readonly property color nSurface: surfaceHi

    // ═══ M3 aliases ═══
    readonly property color m3Primary: wal.colors.color1
    readonly property color m3OnPrimary: wal.special.background
    readonly property color m3PrimaryContainer: wal.colors.color8
    readonly property color m3OnPrimaryContainer: wal.special.foreground
    readonly property color m3Secondary: wal.colors.color4
    readonly property color m3OnSecondary: wal.special.background
    readonly property color m3SecondaryContainer: wal.colors.color8
    readonly property color m3OnSecondaryContainer: wal.special.foreground
    readonly property color m3Tertiary: wal.colors.color5
    readonly property color m3OnTertiary: wal.special.background
    readonly property color m3TertiaryContainer: wal.colors.color8
    readonly property color m3OnTertiaryContainer: wal.special.foreground
    readonly property color m3Surface: wal.special.background
    readonly property color m3SurfaceLowest: wal.special.background
    readonly property color m3SurfaceLow: wal.colors.color8
    readonly property color m3SurfaceContainer: wal.colors.color8
    readonly property color m3SurfaceHigh: wal.colors.color8
    readonly property color m3SurfaceHighest: wal.colors.color8
    readonly property color m3OnSurface: wal.special.foreground
    readonly property color m3OnSurfaceVariant: wal.colors.color7
    readonly property color m3Outline: wal.colors.color8
    readonly property color m3OutlineVariant: wal.colors.color8
    readonly property color m3Err: wal.colors.color1
    readonly property color m3OnErr: wal.special.background

    // ═══ ANSI palette direct access ═══
    readonly property color ansi0: wal.colors.color0
    readonly property color ansi1: wal.colors.color1
    readonly property color ansi2: wal.colors.color2
    readonly property color ansi3: wal.colors.color3
    readonly property color ansi4: wal.colors.color4
    readonly property color ansi5: wal.colors.color5
    readonly property color ansi6: wal.colors.color6
    readonly property color ansi7: wal.colors.color7
    readonly property color ansi8: wal.colors.color8
    readonly property color ansi9: wal.colors.color9
    readonly property color ansi10: wal.colors.color10
    readonly property color ansi11: wal.colors.color11
    readonly property color ansi12: wal.colors.color12
    readonly property color ansi13: wal.colors.color13
    readonly property color ansi14: wal.colors.color14
    readonly property color ansi15: wal.colors.color15

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

    readonly property color bright: fg
    readonly property color ink: bg
    readonly property color warn: wal.colors.color3
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

    readonly property color s1: Qt.rgba(wal.colors.color8.r, wal.colors.color8.g, wal.colors.color8.b, 0.40)
    readonly property color s2: Qt.rgba(wal.colors.color8.r, wal.colors.color8.g, wal.colors.color8.b, 0.65)
    readonly property color s3: wal.colors.color8
    readonly property real panelAlpha: 1.0
    readonly property color scrim: Qt.rgba(bg.r, bg.g, bg.b, 0.7)
    readonly property color grey: Qt.rgba(fg.r, fg.g, fg.b, 0.60)
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
