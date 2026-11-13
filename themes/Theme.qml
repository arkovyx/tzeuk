pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    // ═══ FONTS ═══
    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property string sans: "JetBrainsMono Nerd Font"

    // ═══ THEME MODE (persisted as plain text: "nothing" | "matugen") ═══
    readonly property string themeStateFile: Quickshell.env("HOME") + "/.config/quickshell/tzeuk/theme.state"

    FileView {
        id: themeStateView
        path: root.themeStateFile
        blockLoading: true
        watchChanges: true
        onLoaded: root._applyState(text())
        onFileChanged: root._applyState(text())
    }

    property bool matugenMode: false

    function _applyState(content) {
        const c = String(content || "").trim()
        if (c === "matugen") root.matugenMode = true
        else if (c === "nothing") root.matugenMode = false
    }

    function _persistState() {
        const val = root.matugenMode ? "matugen" : "nothing"
        const home = Quickshell.env("HOME")
        Quickshell.execDetached(["bash", "-c",
            "mkdir -p '" + home + "/.config/quickshell/tzeuk' && printf '%s' '" + val + "' > '" + root.themeStateFile + "'"])
    }

    function toggleTheme() {
        root.matugenMode = !root.matugenMode
        root._persistState()
    }

    function setMatugenMode(on) {
        root.matugenMode = !!on
        root._persistState()
    }

    // ═══ MATUGEN SOURCE ═══
    FileView {
        id: matugenView
        path: Quickshell.env("HOME") + "/.cache/matugen/tzeuk.json"
        watchChanges: true
        onFileChanged: reload()
        adapter: JsonAdapter {
            id: mat
            property string image: ""
            property color primary: "#d71921"
            property color primaryFg: "#ffffff"
            property color primaryContainer: "#3a0f13"
            property color primaryContainerFg: "#ffffff"
            property color secondary: "#aaaaaa"
            property color secondaryFg: "#000000"
            property color secondaryContainer: "#202020"
            property color secondaryContainerFg: "#ffffff"
            property color tertiary: "#d71921"
            property color tertiaryFg: "#ffffff"
            property color tertiaryContainer: "#2a0a0d"
            property color tertiaryContainerFg: "#ffffff"
            property color surface: "#000000"
            property color surfaceLowest: "#000000"
            property color surfaceLow: "#0a0a0a"
            property color surfaceContainer: "#141414"
            property color surfaceHigh: "#1e1e1e"
            property color surfaceHighest: "#282828"
            property color surfaceFg: "#ffffff"
            property color surfaceVariantFg: "#aaaaaa"
            property color outline: "#555555"
            property color outlineVariant: "#333333"
            property color err: "#d71921"
            property color errFg: "#ffffff"
        }
    }

    // ═══ DYNAMIC PALETTE ═══
    readonly property color bg: matugenMode ? mat.surfaceLowest : "#000000"
    readonly property color fg: matugenMode ? mat.surfaceFg : "#ffffff"
    readonly property color accent: matugenMode ? mat.primary : "#d71921"
    readonly property color err: matugenMode ? mat.err : "#d71921"
    readonly property color surfaceHi: matugenMode ? mat.surfaceHigh : Qt.rgba(1, 1, 1, 0.10)
    readonly property color line: matugenMode ? mat.outlineVariant : Qt.rgba(1, 1, 1, 0.20)
    readonly property color dim: matugenMode ? mat.surfaceVariantFg : Qt.rgba(1, 1, 1, 0.50)
    readonly property color barBg: matugenMode
        ? Qt.rgba(mat.surfaceLowest.r, mat.surfaceLowest.g, mat.surfaceLowest.b, 0.85)
        : Qt.rgba(0, 0, 0, 0.85)

    readonly property color nBlack: bg
    readonly property color nWhite: fg
    readonly property color nRed: accent
    readonly property color nDim: line
    readonly property color nSurface: surfaceHi
    readonly property color nText: dim

    // ═══ M3 RAW ROLES ═══
    readonly property color m3Primary: mat.primary
    readonly property color m3OnPrimary: mat.primaryFg
    readonly property color m3PrimaryContainer: mat.primaryContainer
    readonly property color m3OnPrimaryContainer: mat.primaryContainerFg
    readonly property color m3Secondary: mat.secondary
    readonly property color m3OnSecondary: mat.secondaryFg
    readonly property color m3SecondaryContainer: mat.secondaryContainer
    readonly property color m3OnSecondaryContainer: mat.secondaryContainerFg
    readonly property color m3Tertiary: mat.tertiary
    readonly property color m3OnTertiary: mat.tertiaryFg
    readonly property color m3TertiaryContainer: mat.tertiaryContainer
    readonly property color m3OnTertiaryContainer: mat.tertiaryContainerFg
    readonly property color m3Surface: mat.surface
    readonly property color m3SurfaceLowest: mat.surfaceLowest
    readonly property color m3SurfaceLow: mat.surfaceLow
    readonly property color m3SurfaceContainer: mat.surfaceContainer
    readonly property color m3SurfaceHigh: mat.surfaceHigh
    readonly property color m3SurfaceHighest: mat.surfaceHighest
    readonly property color m3OnSurface: mat.surfaceFg
    readonly property color m3OnSurfaceVariant: mat.surfaceVariantFg
    readonly property color m3Outline: mat.outline
    readonly property color m3OutlineVariant: mat.outlineVariant
    readonly property color m3Err: mat.err
    readonly property color m3OnErr: mat.errFg

    // ═══ PYwal COMPAT ═══
    readonly property color walBg: bg
    readonly property color walFg: fg
    readonly property color walAccent: accent

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
    readonly property color warn: matugenMode ? mat.tertiary : "#f5a97f"
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

    // ═══ GLYPH PICKER / PANEL ═══
    readonly property color s1: matugenMode ? mat.surfaceLow : "#0a0a0a"
    readonly property color s2: matugenMode ? mat.surfaceContainer : "#171717"
    readonly property color s3: matugenMode ? mat.surfaceHighest : "#252525"
    readonly property real panelAlpha: 1.0
    readonly property color scrim: matugenMode
        ? Qt.rgba(mat.surfaceLowest.r, mat.surfaceLowest.g, mat.surfaceLowest.b, 0.7)
        : "#000000b3"
    readonly property color grey: matugenMode ? mat.outline : "#b0b0b0"
    readonly property string ui: sans
    readonly property string nf: font
    readonly property int t: move
    readonly property var glide: settle
    function fade(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    // ═══ PICKER ICONS ═══
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
