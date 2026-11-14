import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../themes"

PanelWindow {
    id: win
    property bool opened: false
    signal closeRequested()

    // ═══════════════ Palette ═══════════════
    readonly property color cBlack: "#000000"
    readonly property color cWhite: "#FFFFFF"
    readonly property color cRed:   "#D71921"
    readonly property color cS1:    "#0a0a0a"
    readonly property color cS2:    "#171717"
    readonly property color cS3:    "#252525"
    function dim(a) { return Qt.rgba(1, 1, 1, a) }
    function cp(c) { c -= 0x10000; return String.fromCharCode(0xD800 + (c >> 10), 0xDC00 + (c & 0x3FF)) }
    function pad2(n) { return String(n).padStart(2, "0") }

    readonly property string iClose:  cp(0xF0156)
    readonly property string iBuffer: cp(0xF018F)

    // ═══════════════ Fonts ═══════════════
    readonly property string fDot:  Theme.fontDoto  !== "" ? Theme.fontDoto  : "monospace"
    readonly property string fSans: Theme.fontSans !== "" ? Theme.fontSans : "sans-serif"
    readonly property string fMono: Theme.fontMono !== "" ? Theme.fontMono : "monospace"
    readonly property string fNf:   "JetBrainsMono Nerd Font"
    readonly property string fEmoji:"Noto Color Emoji"

    // ═══════════════ Data ═══════════════
    property var sets: []
    property var items: []
    property var byChar: ({})
    property var counts: ({})
    property bool loaded: false
    property string loadError: ""
    property bool hasWtype: false
    property int tone: 0

    // ═══════════════ UI state ═══════════════
    property int sec: 0
    property int grp: -1
    property string buffer: ""
    property var results: []
    property var hovered: null
    property string mode: "insert"
    property string pending: ""

    FileView {
        id: dataFile
        path: Quickshell.env("HOME") + "/.config/quickshell/tzeuk/data/chars.json"
        printErrors: true
        onLoaded: {
            try {
                var d = JSON.parse(text())
                var out = [], by = {}
                for (var i = 0; i < d.items.length; i++) {
                    var r = d.items[i]
                    var grpName = (d.sets[r[3]] && d.sets[r[3]].groups[r[4]]) || ""
                    var it = {
                        i: i, c: r[0], n: r[1], k: r[2] || "",
                        s: r[3], g: r[4], t: r[5],
                        nl: r[1].toLowerCase(),
                        kl: " " + (r[2] || "").toLowerCase() + " " + grpName.toLowerCase() + " "
                    }
                    out.push(it)
                    if (by[it.c] === undefined) by[it.c] = it
                }
                win.sets = d.sets
                win.byChar = by
                win.items = out
                win.loaded = true
                win.recompute()
            } catch (e) {
                console.warn("chars.json parse:", e)
                win.loadError = "PARSE: " + e
            }
        }
        onLoadFailed: (error) => {
            console.warn("chars.json load:", error)
            win.loadError = "LOAD FAILED"
        }
    }

    FileView {
        id: stateFile
        path: Quickshell.env("HOME") + "/.cache/tzeuk/state.json"
        printErrors: false
        onLoaded: {
            try {
                var s = JSON.parse(text())
                if (typeof s.charTone === "number") win.tone = s.charTone
                if (s.counts && typeof s.counts === "object") win.counts = s.counts
            } catch (e) {}
        }
    }
    function saveState() {
        stateFile.setText(JSON.stringify({ charTone: tone, counts: counts }))
    }
    onToneChanged: saveState()

    Process {
        command: ["sh", "-c", "command -v wtype"]
        running: true
        onExited: code => win.hasWtype = code === 0
    }

    // ═══════════════ Sections ═══════════════
    readonly property var sections: [
        { id: "all",    label: "all",     sets: ["emoji", "nerd", "sym", "kao"] },
        { id: "recent", label: "recent",  sets: ["emoji", "nerd", "sym", "kao"] },
        { id: "emoji",  label: "emoji",   sets: ["emoji"] },
        { id: "nerd",   label: "nerd",    sets: ["nerd"] },
        { id: "sym",    label: "symbols", sets: ["sym"] },
        { id: "kao",    label: "kaomoji", sets: ["kao"] },
        { id: "fancy",  label: "fancy",   sets: [] }
    ]
    readonly property var section: sections[sec]
    readonly property bool listMode: section.id === "kao" || section.id === "fancy"
    readonly property var groups: {
        if (!loaded || section.sets.length !== 1) return []
        var i = setIndex(section.sets[0])
        return i >= 0 ? sets[i].groups : []
    }
    readonly property var current: hovered ? hovered
        : (results.length && (listMode ? list.currentIndex : grid.currentIndex) >= 0
           ? results[listMode ? list.currentIndex : grid.currentIndex]
           : null)

    // ═══════════════ Helpers ═══════════════
    function setIndex(id) {
        for (var i = 0; i < sets.length; i++) if (sets[i].id === id) return i
        return -1
    }
    function glyph(it, t) { return it.t && t > 0 ? it.t[t - 1] : it.c }
    function hex(c) {
        var out = [], i = 0
        while (i < c.length) {
            var cp = c.codePointAt(i)
            if (cp !== 0xFE0F && cp !== 0x200D)
                out.push("U+" + cp.toString(16).toUpperCase().padStart(4, "0"))
            i += cp > 0xFFFF ? 2 : 1
        }
        return out.join(" ")
    }
    function fontOf(it) {
        if (!it || it.s === undefined || !sets[it.s]) return fSans
        var sid = sets[it.s].id
        if (sid === "emoji") return fEmoji
        if (sid === "kao")   return fSans
        return fNf
    }

    function scoreLow(haystack, needle) {
        if (!needle || !haystack) return 0
        var h = String(haystack), n = String(needle)
        var hi = 0, ni = 0, score = 0, lastMatch = -2
        while (hi < h.length && ni < n.length) {
            if (h[hi] === n[ni]) {
                if (hi === lastMatch + 1) score += 30
                else if (hi === 0 || h[hi - 1] === " ") score += 20
                else score += 10
                lastMatch = hi; ni++
            }
            hi++
        }
        return ni < n.length ? 0 : 100 + score
    }

    function search(q, sl, group) {
        var out = [], l = items
        q = q.trim().toLowerCase()
        var inSet = {}
        for (var j = 0; j < sl.length; j++) inSet[sl[j]] = true
        if (q === "") {
            for (var i = 0; i < l.length; i++)
                if (inSet[l[i].s] && (group < 0 || l[i].g === group)) out.push(l[i])
            return out
        }
        var cpm = q.match(/^(?:u\+|0x|\\u)([0-9a-f]{2,6})$/), cpq = -1
        if (cpm) cpq = parseInt(cpm[1], 16)
        else if (/^[0-9a-f]{4,6}$/.test(q) && /[0-9]/.test(q)) cpq = parseInt(q, 16)
        var glyphq = /[^\x00-\x7f]/.test(q) ? q : ""
        var words = q.split(/\s+/), scored = []
        for (i = 0; i < l.length; i++) {
            var it = l[i]
            if (!inSet[it.s] || (group >= 0 && it.g !== group)) continue
            var sc = 0
            if (glyphq !== "") {
                if (it.c === glyphq || it.c.replace("\uFE0F", "") === glyphq.replace("\uFE0F", ""))
                    sc = 5000
            } else if (cpq >= 0 && it.c.codePointAt(0) === cpq && it.c.length <= 2) {
                sc = 5000
            } else {
                for (j = 0; j < words.length; j++) {
                    var w = words[j]
                    var s = scoreLow(it.nl, w)
                    if (s === 0 && it.nl.indexOf(w) >= 0) s = 80
                    if (s === 0) { sc = 0; break }
                    if (it.kl.indexOf(" " + w) >= 0) s = 450
                    else if (w.length > 1 && it.kl.indexOf(w) >= 0) s = 150
                    sc += s
                }
                if (sc === 0) continue
                if (it.nl === q) sc += 800
                else if (it.nl.startsWith(q)) sc += 400
                sc -= it.nl.length * 0.5
                if (sets[it.s].id === "emoji") sc += 40
            }
            if (sc <= 0) continue
            var u = counts[it.c]
            if (u) sc += Math.min(u.n, 20) * 15
            scored.push({ it: it, sc: sc })
        }
        scored.sort((a, b) => b.sc - a.sc || a.it.i - b.it.i)
        for (i = 0; i < scored.length; i++) out.push(scored[i].it)
        return out
    }
    function recent(limit) {
        var l = []
        for (var c in counts) {
            var it = byChar[c]
            if (it && sets[it.s]) l.push({ it: it, t: counts[c].t })
        }
        l.sort((a, b) => b.t - a.t)
        var out = []
        for (var i = 0; i < l.length && i < limit; i++) out.push(l[i].it)
        return out
    }
    function byUse(list) {
        var u = [], rest = []
        for (var i = 0; i < list.length; i++) (counts[list[i].c] ? u : rest).push(list[i])
        u.sort((a, b) => counts[b.c].n - counts[a.c].n)
        return u.concat(rest)
    }
    function bump(c) {
        var n = {}
        for (var k in counts) n[k] = counts[k]
        n[c] = { n: (n[c] ? n[c].n : 0) + 1, t: Date.now() }
        counts = n
        saveState()
    }

    // ═══════════════ Fancy text ═══════════════
    readonly property var mathStyles: [
        ["bold", 0x1D400, 0x1D41A, 0x1D7CE], ["italic", 0x1D434, 0x1D44E, 0],
        ["bold italic", 0x1D468, 0x1D482, 0], ["script", 0x1D49C, 0x1D4B6, 0],
        ["bold script", 0x1D4D0, 0x1D4EA, 0], ["fraktur", 0x1D504, 0x1D51E, 0],
        ["bold fraktur", 0x1D56C, 0x1D586, 0], ["double-struck", 0x1D538, 0x1D552, 0x1D7D8],
        ["sans", 0x1D5A0, 0x1D5BA, 0x1D7E2], ["sans bold", 0x1D5D4, 0x1D5EE, 0x1D7EC],
        ["sans italic", 0x1D608, 0x1D622, 0], ["monospace", 0x1D670, 0x1D68A, 0x1D7F6]
    ]
    readonly property var holes: ({
        "italic": { h: 0x210E },
        "script": { B: 0x212C, E: 0x2130, F: 0x2131, H: 0x210B, I: 0x2110, L: 0x2112,
                    M: 0x2133, R: 0x211B, e: 0x212F, g: 0x210A, o: 0x2134 },
        "fraktur": { C: 0x212D, H: 0x210C, I: 0x2111, R: 0x211C, Z: 0x2128 },
        "double-struck": { C: 0x2102, H: 0x210D, N: 0x2115, P: 0x2119, Q: 0x211A,
                           R: 0x211D, Z: 0x2124 }
    })
    readonly property string smallCaps: "ᴀʙᴄᴅᴇꜰɢʜɪᴊᴋʟᴍɴᴏᴘǫʀꜱᴛᴜᴠᴡxʏᴢ"
    readonly property string flipLower: "ɐqɔpǝɟƃɥᴉɾʞlɯuodbɹsʇnʌʍxʎz"
    readonly property var flipOther: ({
        "0": "0", "1": "Ɩ", "2": "ᄅ", "3": "Ɛ", "4": "ㄣ", "5": "ϛ", "6": "9",
        "7": "ㄥ", "8": "8", "9": "6", ".": "˙", ",": "'", "'": ",", "\"": "„",
        "?": "¿", "!": "¡", "(": ")", ")": "(", "[": "]", "]": "[", "{": "}",
        "}": "{", "<": ">", ">": "<", "_": "‾", "&": "⅋"
    })
    function mapLetters(t, f) {
        var out = "", l = Array.from(t)
        for (var i = 0; i < l.length; i++) {
            var r = f(l[i], l[i].codePointAt(0))
            out += r === null ? l[i] : r
        }
        return out
    }
    function fancy(t) {
        var out = [], st = mathStyles
        for (var i = 0; i < st.length; i++) {
            var s = st[i], h = holes[s[0]] || {}
            out.push({ c: mapLetters(t, (ch, code) => {
                if (h[ch]) return String.fromCodePoint(h[ch])
                if (code >= 65 && code <= 90) return String.fromCodePoint(s[1] + code - 65)
                if (code >= 97 && code <= 122) return String.fromCodePoint(s[2] + code - 97)
                if (code >= 48 && code <= 57 && s[3]) return String.fromCodePoint(s[3] + code - 48)
                return null
            }), n: s[0] })
        }
        out.push({ n: "small caps", c: mapLetters(t, (ch, code) => {
            var c = ch.toLowerCase().charCodeAt(0)
            return c >= 97 && c <= 122 ? smallCaps[c - 97] : null
        }) })
        out.push({ n: "full width", c: mapLetters(t, (ch, code) =>
            code === 32 ? "　" : (code > 32 && code < 127 ? String.fromCharCode(code + 0xFEE0) : null)) })
        out.push({ n: "circled", c: mapLetters(t, (ch, code) => {
            if (code >= 65 && code <= 90) return String.fromCodePoint(0x24B6 + code - 65)
            if (code >= 97 && code <= 122) return String.fromCodePoint(0x24D0 + code - 97)
            if (code === 48) return "⓪"
            if (code >= 49 && code <= 57) return String.fromCodePoint(0x2460 + code - 49)
            return null
        }) })
        out.push({ n: "negative circled", c: mapLetters(t, (ch, code) => {
            var c = ch.toUpperCase().charCodeAt(0)
            return c >= 65 && c <= 90 ? String.fromCodePoint(0x1F150 + c - 65) : null
        }) })
        out.push({ n: "squared", c: mapLetters(t, (ch, code) => {
            var c = ch.toUpperCase().charCodeAt(0)
            return c >= 65 && c <= 90 ? String.fromCodePoint(0x1F130 + c - 65) : null
        }) })
        out.push({ n: "negative squared", c: mapLetters(t, (ch, code) => {
            var c = ch.toUpperCase().charCodeAt(0)
            return c >= 65 && c <= 90 ? String.fromCodePoint(0x1F170 + c - 65) : null
        }) })
        out.push({ n: "strikethrough", c: mapLetters(t, (ch, code) => code === 32 ? null : ch + "̶") })
        out.push({ n: "underline", c: mapLetters(t, (ch, code) => ch + "̲") })
        out.push({ n: "upside down", c: Array.from(mapLetters(t, (ch, code) => {
            var c = ch.toLowerCase().charCodeAt(0)
            if (c >= 97 && c <= 122) return flipLower[c - 97]
            return flipOther[ch] !== undefined ? flipOther[ch] : null
        })).reverse().join("") })
        out.push({ n: "spaced", c: Array.from(t).join(" ") })
        return out
    }

    // ═══════════════ Actions ═══════════════
    function copy(s) {
        Quickshell.execDetached(["sh", "-c",
            'wl-copy -- "$1" && notify-send -a tzeuk -t 1500 "copied" "$1"', "sh", s])
    }
    function type(s) {
        Quickshell.execDetached(["sh", "-c", 'sleep 0.15; wtype -- "$1"', "sh", s])
    }
    function setList(id) {
        var out = []
        for (var i = 0; i < section.sets.length; i++) out.push(setIndex(section.sets[i]))
        return out
    }
    function recompute() {
        hovered = null
        var q = input ? (input.text || "") : ""
        if (section.id === "fancy") results = fancy(q.trim() === "" ? "tzeuk" : q)
        else if (!loaded) results = []
        else if (section.id === "recent") {
            if (q.trim() === "") results = recent(500)
            else {
                var l = search(q, setList(), -1), out = []
                for (var i = 0; i < l.length; i++) if (counts[l[i].c]) out.push(l[i])
                results = out
            }
        } else if (section.id === "kao") {
            var k = search(q, setList(), grp)
            results = q.trim() === "" ? byUse(k) : k
        } else results = search(q, setList(), grp)
        grid.currentIndex = 0
        list.currentIndex = 0
        grid.positionViewAtBeginning()
        list.positionViewAtBeginning()
    }

    function cycleSection(d) { sec = (sec + d + sections.length) % sections.length }
    function cycleGroup(d) {
        if (!groups.length) return
        var n = groups.length + 1
        grp = ((grp + 1 + d + n) % n) - 1
    }
    function outOf(it) { return section.id === "fancy" ? it.c : glyph(it, tone) }
    function codeOf(s) {
        var cps = Array.from(s)
        if (cps.length === 1) return "0x" + cps[0].codePointAt(0).toString(16).toUpperCase()
        return hex(s)
    }
    function pick(it, how) {
        if (!it && buffer === "") return
        var s = it ? outOf(it) : ""
        if (it && section.id !== "fancy" && (how === "buffer" || buffer === "")) bump(it.c)
        if (how === "buffer") { buffer += s; return }
        if (how === "code") { copy(codeOf(s)); closeRequested(); return }
        if (buffer !== "") s = buffer
        closeRequested()
        if (how === "type" && hasWtype) type(s)
        else copy(s)
    }

    function moveLinear(d) {
        var n = results.length
        if (n === 0) return
        var v = listMode ? list : grid
        v.currentIndex = Math.max(0, Math.min(n - 1, v.currentIndex + d))
    }
    function moveRow(d) {
        var n = results.length
        if (n === 0) return
        if (listMode) { moveLinear(d); return }
        var cols = Math.max(1, Math.floor(grid.width / grid.cellWidth))
        var cur = grid.currentIndex
        var row = Math.floor(cur / cols)
        var col = cur % cols
        var newRow = Math.max(0, row + d)
        grid.currentIndex = Math.min(n - 1, newRow * cols + col)
    }
    function moveDir(dir) {
        if (dir === "up") moveRow(-1)
        else if (dir === "down") moveRow(1)
        else if (dir === "left") moveLinear(-1)
        else if (dir === "right") moveLinear(1)
    }

    function handleKey(event) {
        var ctrl  = (event.modifiers & Qt.ControlModifier) !== 0
        var shift = (event.modifiers & Qt.ShiftModifier) !== 0
        var alt   = (event.modifiers & Qt.AltModifier) !== 0
        event.accepted = true

        if (pending === "g") {
            pending = ""
            if (event.key === Qt.Key_G && !shift) {
                if (listMode) list.currentIndex = 0
                else grid.currentIndex = 0
            }
            return
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (ctrl) pick(current, "buffer")
            else if (shift) pick(current, "type")
            else if (alt) pick(current, "code")
            else pick(current, "copy")
            return
        }
        if (event.key === Qt.Key_Tab) { cycleSection(1); return }
        if (event.key === Qt.Key_Backtab) { cycleSection(-1); return }
        if (ctrl && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) {
            cycleGroup(event.key === Qt.Key_Left ? -1 : 1); return
        }
        if (alt && event.key >= Qt.Key_1 && event.key < Qt.Key_1 + sections.length) {
            sec = event.key - Qt.Key_1; return
        }

        if (mode === "insert") {
            if (event.key === Qt.Key_Escape) { mode = "normal"; return }
            if (ctrl && event.key === Qt.Key_BracketLeft) { mode = "normal"; return }
            event.accepted = false
            return
        }

        if (ctrl) {
            if (event.key === Qt.Key_D) { moveRow(3); return }
            if (event.key === Qt.Key_U) { moveRow(-3); return }
            if (event.key === Qt.Key_C || event.key === Qt.Key_Q) { closeRequested(); return }
            return
        }
        switch (event.key) {
        case Qt.Key_Escape: closeRequested(); break
        case Qt.Key_I:
        case Qt.Key_Slash: mode = "insert"; if (input) input.forceActiveFocus(); break
        case Qt.Key_J: moveDir("down"); break
        case Qt.Key_K: moveDir("up"); break
        case Qt.Key_H: moveDir("left"); break
        case Qt.Key_L: moveDir("right"); break
        case Qt.Key_G:
            if (shift) {
                if (listMode) list.currentIndex = results.length - 1
                else grid.currentIndex = results.length - 1
            } else pending = "g"
            break
        }
    }

    function paintDots(canvas, gap, alpha) {
        var ctx = canvas.getContext("2d")
        ctx.reset()
        ctx.fillStyle = "rgba(255,255,255," + alpha + ")"
        for (var y = gap / 2; y < canvas.height; y += gap)
            for (var x = gap / 2; x < canvas.width; x += gap) {
                ctx.beginPath()
                ctx.arc(x, y, 1, 0, Math.PI * 2)
                ctx.fill()
            }
    }

    // ═══════════════ Lifecycle ═══════════════
    onOpenedChanged: {
        if (!opened) return
        hovered = null
        buffer = ""
        if (input) input.text = ""
        grp = -1
        mode = "insert"
        pending = ""
        sec = 0
        recompute()
        focusTimer.restart()
    }
    onSecChanged: { grp = -1; recompute() }
    onGrpChanged: recompute()
    onLoadedChanged: if (loaded) recompute()

    Timer { id: debounce;    interval: 40; onTriggered: win.recompute() }
    Timer { id: focusTimer;  interval: 80; onTriggered: if (input) input.forceActiveFocus() }

    // ═══════════════ Window ═══════════════
    visible: opened
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tzeuk-chars"
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: "#000000b3"
        MouseArea { anchors.fill: parent; onClicked: win.closeRequested() }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width:  Math.min(parent.width  - 80, 820)
        height: Math.min(parent.height - 80, 680)
        radius: 28
        color: cBlack
        border.color: cWhite
        border.width: 1
        clip: true
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 10

            // ═══ Header: section label + count + LED ═══
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 46

                Text {
                    id: sectionLabel
                    anchors.left: parent.left
                    anchors.right: headerRight.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.section.label.toUpperCase()
                    color: cWhite
                    font.family: fDot
                    font.weight: Font.Black
                    font.pixelSize: 36
                    elide: Text.ElideRight
                }

                Row {
                    id: headerRight
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.loaded
                            ? win.items.length.toLocaleString() + " GLYPHS"
                            : (win.loadError || "LOADING")
                        color: win.loadError ? cRed : dim(0.6)
                        font.family: fMono
                        font.pixelSize: 11
                        font.letterSpacing: 1
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8; height: 8; radius: 4
                        color: cRed
                        SequentialAnimation on opacity {
                            running: win.visible
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.2; duration: 800 }
                            NumberAnimation { to: 1.0; duration: 800 }
                        }
                    }
                }
            }

            Canvas {
                id: ruleTop
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                onPaint: win.paintDots(ruleTop, 5, 0.45)
                onWidthChanged: requestPaint()
            }

            // ═══ Search row ═══
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                spacing: 10

                Rectangle {
                    id: bar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 22
                    color: cBlack
                    border.width: 1
                    border.color: win.mode === "insert" ? cWhite : dim(0.3)
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Text {
                        id: prompt
                        x: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: ">"
                        color: cRed
                        font.family: fDot
                        font.weight: Font.Black
                        font.pixelSize: 20
                    }

                    Rectangle {
                        id: modeTag
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        width: 72; height: 28; radius: 14
                        color: win.mode === "insert" ? "transparent" : cWhite
                        border.width: 1
                        border.color: win.mode === "insert" ? cRed : cWhite
                        Text {
                            anchors.centerIn: parent
                            text: win.mode === "insert" ? "INSERT" : "NORMAL"
                            color: win.mode === "insert" ? cRed : cBlack
                            font.family: fMono
                            font.pixelSize: 10
                            font.letterSpacing: 1
                        }
                    }

                    Item {
                        anchors.left: prompt.right
                        anchors.leftMargin: 10
                        anchors.right: modeTag.left
                        anchors.rightMargin: 8
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        clip: true

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text.length === 0
                            text: win.section.id === "fancy" ? "TYPE ANYTHING" : "SEARCH GLYPHS"
                            color: dim(0.4)
                            font.family: fMono
                            font.pixelSize: 12
                            font.letterSpacing: 1.2
                        }

                        TextInput {
                            id: input
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            readOnly: win.mode === "normal"
                            color: cWhite
                            selectionColor: cRed
                            selectedTextColor: cWhite
                            font.family: fSans
                            font.pixelSize: 17
                            inputMethodHints: Qt.ImhNoPredictiveText
                            clip: true

                            cursorDelegate: Rectangle {
                                width: 8
                                color: win.mode === "insert" ? cRed : "transparent"
                                border.width: 1
                                border.color: cRed
                            }

                            onTextChanged: {
                                if (text !== "" && win.section.id === "recent") win.sec = 0
                                if (text === "") win.recompute(); else debounce.restart()
                            }
                            Keys.onPressed: event => win.handleKey(event)
                        }
                    }
                }

                Row {
                    spacing: 2
                    visible: win.loaded && (win.section.id === "emoji"
                             || win.section.id === "all" || win.section.id === "recent")
                    Layout.preferredWidth: visible ? implicitWidth : 0
                    Layout.fillHeight: true
                    Repeater {
                        model: 6
                        delegate: Rectangle {
                            required property int index
                            readonly property var hand: win.byChar["✋"]
                            width: 34; height: 34; radius: 17
                            anchors.verticalCenter: parent.verticalCenter
                            color: win.tone === index ? cWhite : (tm.containsMouse ? cS3 : "transparent")
                            Text {
                                anchors.centerIn: parent
                                text: parent.hand ? win.glyph(parent.hand, parent.index) : ""
                                font.family: fEmoji
                                font.pixelSize: 15
                            }
                            MouseArea {
                                id: tm
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { win.tone = parent.index; if (input) input.forceActiveFocus() }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 17
                    color: cm.containsMouse ? cS3 : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: win.iClose
                        color: cWhite
                        font.family: fNf
                        font.pixelSize: 13
                    }
                    MouseArea {
                        id: cm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.closeRequested()
                    }
                }
            }

            // ═══ Section chips ═══
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                ListView {
                    anchors.fill: parent
                    orientation: ListView.Horizontal
                    spacing: 2
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: win.sections
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool sel: win.sec === index
                        width: sLabel.implicitWidth + 22
                        height: 28; radius: 14
                        color: sel ? cWhite : (sh.containsMouse ? cS3 : "transparent")
                        border.width: 1
                        border.color: sel ? cWhite : dim(0.2)
                        Text {
                            id: sLabel
                            anchors.centerIn: parent
                            text: modelData.label
                            color: sel ? cBlack : cWhite
                            font.family: fMono
                            font.pixelSize: 11
                            font.letterSpacing: 0.5
                        }
                        MouseArea {
                            id: sh
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { win.sec = index; if (input) input.forceActiveFocus() }
                        }
                    }
                }
            }

            // ═══ Group chips ═══
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: win.groups.length > 0 ? 24 : 0
                visible: win.groups.length > 0
                ListView {
                    anchors.fill: parent
                    orientation: ListView.Horizontal
                    spacing: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: win.groups.length
                        ? ["ALL"].concat(win.groups.map(g => g.toUpperCase()))
                        : []
                    currentIndex: win.grp + 1
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool sel: win.grp === index - 1
                        width: gLabel.implicitWidth + 16
                        height: 24; radius: 12
                        color: sel ? cRed : (gh.containsMouse ? cS3 : "transparent")
                        border.width: 1
                        border.color: sel ? cRed : dim(0.15)
                        Text {
                            id: gLabel
                            anchors.centerIn: parent
                            text: modelData
                            color: sel ? cWhite : dim(0.7)
                            font.family: fMono
                            font.pixelSize: 10
                            font.letterSpacing: 0.5
                        }
                        MouseArea {
                            id: gh
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { win.grp = index - 1; if (input) input.forceActiveFocus() }
                        }
                    }
                }
            }

            // ═══ Results ═══
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 120

                GridView {
                    id: grid
                    anchors.fill: parent
                    visible: !win.listMode
                    readonly property int cols: Math.max(1, Math.floor(width / 58))
                    cellWidth: Math.floor(width / cols)
                    cellHeight: 58
                    clip: true
                    model: win.listMode ? 0 : win.results.length
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 0
                    keyNavigationWraps: false
                    cacheBuffer: 400

                    delegate: Rectangle {
                        id: cell
                        required property int index
                        readonly property var it: win.results[index]
                        readonly property bool sel: grid.currentIndex === index
                        readonly property bool long: cell.it && cell.it.c.length > 2
                        width: grid.cellWidth - 4
                        height: grid.cellHeight - 4
                        radius: 18
                        color: sel ? cWhite : (gm.containsMouse ? cS2 : "transparent")
                        border.width: 1
                        border.color: sel ? cWhite : dim(0.08)

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 6
                            height: parent.height - 6
                            text: cell.it ? win.glyph(cell.it, win.tone) : ""
                            color: cell.sel ? cBlack : cWhite
                            font.family: win.fontOf(cell.it)
                            font.pixelSize: cell.long ? 14 : 26
                            minimumPixelSize: 7
                            fontSizeMode: cell.long ? Text.Fit : Text.FixedSize
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            id: gm
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onContainsMouseChanged: win.hovered = containsMouse ? cell.it : null
                            onClicked: mouse => {
                                grid.currentIndex = cell.index
                                win.pick(cell.it, mouse.button === Qt.RightButton ? "buffer" : "copy")
                            }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        visible: grid.visibleArea.heightRatio < 1
                        y: grid.visibleArea.yPosition * parent.height
                        width: 2
                        height: Math.max(16, grid.visibleArea.heightRatio * parent.height)
                        color: dim(0.5)
                    }
                }

                ListView {
                    id: list
                    anchors.fill: parent
                    visible: win.listMode
                    clip: true
                    model: win.listMode ? win.results.length : 0
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 0

                    delegate: Rectangle {
                        id: row
                        required property int index
                        readonly property var it: win.results[index]
                        readonly property bool sel: list.currentIndex === index
                        width: list.width
                        height: 40
                        radius: 20
                        color: sel ? cWhite : (lm.containsMouse ? cS2 : "transparent")
                        border.width: 1
                        border.color: sel ? cWhite : dim(0.08)
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.right: tag.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.it ? row.it.c : ""
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            color: row.sel ? cBlack : cWhite
                            font.family: fSans
                            font.pixelSize: 15
                        }
                        Text {
                            id: tag
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.it
                                ? (win.section.id === "fancy"
                                   ? row.it.n.toUpperCase()
                                   : row.it.k.toUpperCase())
                                : ""
                            color: row.sel ? dim(0.55) : dim(0.4)
                            font.family: fMono
                            font.pixelSize: 10
                            font.letterSpacing: 0.5
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, 200)
                        }
                        MouseArea {
                            id: lm
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onContainsMouseChanged: win.hovered = containsMouse ? row.it : null
                            onClicked: mouse => {
                                list.currentIndex = row.index
                                win.pick(row.it, mouse.button === Qt.RightButton ? "buffer" : "copy")
                            }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        visible: list.visibleArea.heightRatio < 1
                        y: list.visibleArea.yPosition * parent.height
                        width: 2
                        height: Math.max(16, list.visibleArea.heightRatio * parent.height)
                        color: dim(0.5)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: win.results.length === 0
                    text: win.loadError ? win.loadError
                        : (!win.loaded && win.section.id !== "fancy" ? "LOADING…"
                        : (win.section.id === "recent" && input && input.text === "" ? "NOTHING USED YET"
                        : "NO MATCHES"))
                    color: win.loadError ? cRed : dim(0.4)
                    font.family: fDot
                    font.weight: Font.Black
                    font.pixelSize: 28
                    font.letterSpacing: 2
                }
            }

            Canvas {
                id: ruleBot
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                onPaint: win.paintDots(ruleBot, 5, 0.45)
                onWidthChanged: requestPaint()
            }

            // ═══ Preview ═══
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                spacing: 14

                Rectangle {
                    Layout.preferredWidth: win.listMode ? 0 : 48
                    Layout.preferredHeight: win.listMode ? 0 : 48
                    visible: !win.listMode
                    radius: 24
                    color: cS2
                    border.width: 1
                    border.color: dim(0.15)
                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 6
                        height: parent.height - 6
                        text: win.current ? win.glyph(win.current, win.tone) : "—"
                        color: win.current ? cWhite : dim(0.3)
                        font.family: win.fontOf(win.current)
                        font.pixelSize: 26
                        minimumPixelSize: 8
                        fontSizeMode: Text.Fit
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: win.current ? win.current.n : "—"
                        color: cWhite
                        font.family: fSans
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        color: cRed
                        font.family: fMono
                        font.pixelSize: 10
                        font.letterSpacing: 0.8
                        elide: Text.ElideRight
                        text: {
                            var c = win.current
                            if (!c) return "—"
                            if (win.section.id === "fancy") return "FANCY · " + c.n.toUpperCase()
                            if (c.s === undefined || !win.sets[c.s]) return ""
                            var st = win.sets[c.s]
                            return (st.id === "kao" ? "" : win.hex(win.glyph(c, win.tone)) + " · ")
                                + st.label.toUpperCase() + " · " + st.groups[c.g].toUpperCase()
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        color: dim(0.4)
                        font.family: fMono
                        font.pixelSize: 10
                        font.letterSpacing: 0.5
                        elide: Text.ElideRight
                        text: win.current && win.current.k && win.section.id !== "kao"
                            ? win.current.k.toUpperCase() : ""
                    }
                }

                Row {
                    spacing: 8
                    visible: win.buffer !== ""
                    Layout.preferredWidth: visible ? implicitWidth : 0
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.iBuffer
                        color: cRed
                        font.family: fNf
                        font.pixelSize: 16
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, 180)
                        text: win.buffer
                        elide: Text.ElideLeft
                        color: cWhite
                        font.family: fNf
                        font.pixelSize: 17
                    }
                }
            }

            // ═══ Footer ═══
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 14

                Text {
                    text: win.mode === "insert"
                        ? "ESC NORMAL   ENTER COPY   S-ENTER TYPE"
                        : "HJKL MOVE   ENTER COPY   I INSERT   ESC QUIT"
                    color: dim(0.45)
                    font.family: fMono
                    font.pixelSize: 10
                    font.letterSpacing: 1
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: win.results.length === 0
                        ? "00/00"
                        : win.pad2((win.listMode ? list.currentIndex : grid.currentIndex) + 1)
                          + "/" + win.pad2(win.results.length)
                    color: cRed
                    font.family: fDot
                    font.weight: Font.Black
                    font.pixelSize: 15
                }
            }
        }
    }
}
