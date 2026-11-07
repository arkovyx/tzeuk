import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: win
    property bool opened: false
    signal closeRequested()

    // ═══════════════════ Palette (inline, no Theme) ═══════════════════
    readonly property color cFg:     "#ffffff"
    readonly property color cGrey:   "#b0b0b0"
    readonly property color cMute:   "#707070"
    readonly property color cDim:    "#4a4a4a"
    readonly property color cLive:   "#d71921"
    readonly property color cFill:   "#ffffff"
    readonly property color cFillFg: "#000000"
    readonly property color cS1:     "#0a0a0a"
    readonly property color cS2:     "#171717"
    readonly property color cS3:     "#252525"
    readonly property color cScrim:  "#000000b3"
    readonly property string cUi:    "Space Grotesk"
    readonly property string cNf:    "JetBrainsMono Nerd Font"
    readonly property int cT: 260
    readonly property var cGlide: [0.22, 1.0, 0.36, 1.0]
    function fade(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function cp(c) { c -= 0x10000; return String.fromCharCode(0xD800 + (c >> 10), 0xDC00 + (c & 0x3FF)) }
    readonly property string iSearch: cp(0xF0349)
    readonly property string iClose:  cp(0xF0156)
    readonly property string iBuffer: cp(0xF018F)

    // ═══════════════════ Data state ═══════════════════
    property var sets: []
    property var items: []
    property var byChar: ({})
    property var counts: ({})
    property bool loaded: false
    property string loadError: ""
    property bool hasWtype: false
    property int tone: 0

    // ═══════════════════ Load chars.json ═══════════════════
    FileView {
        id: dataFile
        path: Quickshell.env("HOME") + "/.config/quickshell/tzeuk/chars.json"
        printErrors: true
        onLoaded: {
            try {
                var d = JSON.parse(text())
                var out = [], by = {}
                for (var i = 0; i < d.items.length; i++) {
                    var r = d.items[i]
                    var grp = (d.sets[r[3]] && d.sets[r[3]].groups[r[4]]) || ""
                    var it = {
                        i: i, c: r[0], n: r[1], k: r[2] || "",
                        s: r[3], g: r[4], t: r[5],
                        nl: r[1].toLowerCase(),
                        kl: " " + (r[2] || "").toLowerCase() + " " + grp.toLowerCase() + " "
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

    // Persist counts + tone
    FileView {
        id: stateFile
        path: Quickshell.env("HOME") + "/.cache/tzeuk/state.json"
        printErrors: false
        onLoaded: {
            try {
                var s = JSON.parse(text())
                win.tone   = (typeof s.charTone === "number") ? s.charTone : 0
                win.counts = s.counts || ({})
            } catch (e) {
                win.tone = 0
                win.counts = ({})
            }
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

    // ═══════════════════ Sections ═══════════════════
    readonly property var sections: [
        { id: "all",    label: "all",     sets: ["emoji", "nerd", "sym"] },
        { id: "recent", label: "recent",  sets: ["emoji", "nerd", "sym"] },
        { id: "emoji",  label: "emoji",   sets: ["emoji"] },
        { id: "nerd",   label: "nerd",    sets: ["nerd"] },
        { id: "sym",    label: "symbols", sets: ["sym"] },
        { id: "kao",    label: "kaomoji", sets: ["kao"] },
        { id: "fancy",  label: "fancy",   sets: [] }
    ]
    property int sec: 0
    property int grp: -1
    property string buffer: ""
    property var results: []
    property var hovered: null
    readonly property var section: sections[sec]
    readonly property bool listMode: section.id === "kao" || section.id === "fancy"
    readonly property var groups: {
        if (!loaded || section.sets.length !== 1) return []
        var i = setIndex(section.sets[0])
        return i >= 0 ? sets[i].groups : []
    }
    readonly property var view: listMode ? list : grid
    readonly property var current: hovered ? hovered
        : (results.length && view.currentIndex >= 0 ? results[view.currentIndex] : null)

    // ═══════════════════ Lookup helpers ═══════════════════
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

    function scoreLow(haystack, needle) {
        if (!needle || !haystack) return 0
        var h = String(haystack), n = String(needle)
        var hi = 0, ni = 0, score = 0, lastMatch = -2
        while (hi < h.length && ni < n.length) {
            if (h[hi] === n[ni]) {
                if (hi === lastMatch + 1) score += 30
                else if (hi === 0 || h[hi - 1] === " ") score += 20
                else score += 10
                lastMatch = hi
                ni++
            }
            hi++
        }
        if (ni < n.length) return 0
        return 100 + score
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
                    if (s < 300 && s < 99) s = 0
                    if (s < 450 && it.kl.indexOf(" " + w) >= 0) s = 450
                    else if (s < 150 && w.length > 1 && it.kl.indexOf(w) >= 0) s = 150
                    if (s === 0) { sc = 0; break }
                    sc += s
                }
                if (sc === 0) continue
                if (it.nl === q) sc += 800
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
            if (it && sets[it.s] && sets[it.s].id !== "kao")
                l.push({ it: it, t: counts[c].t })
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

    // ═══════════════════ Fancy text ═══════════════════
    readonly property var mathStyles: [
        ["bold", 0x1D400, 0x1D41A, 0x1D7CE],
        ["italic", 0x1D434, 0x1D44E, 0],
        ["bold italic", 0x1D468, 0x1D482, 0],
        ["script", 0x1D49C, 0x1D4B6, 0],
        ["bold script", 0x1D4D0, 0x1D4EA, 0],
        ["fraktur", 0x1D504, 0x1D51E, 0],
        ["bold fraktur", 0x1D56C, 0x1D586, 0],
        ["double-struck", 0x1D538, 0x1D552, 0x1D7D8],
        ["sans", 0x1D5A0, 0x1D5BA, 0x1D7E2],
        ["sans bold", 0x1D5D4, 0x1D5EE, 0x1D7EC],
        ["sans italic", 0x1D608, 0x1D622, 0],
        ["monospace", 0x1D670, 0x1D68A, 0x1D7F6]
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
        out.push({ n: "strikethrough", c: mapLetters(t, (ch, code) =>
            code === 32 ? null : ch + "̶") })
        out.push({ n: "underline", c: mapLetters(t, (ch, code) => ch + "̲") })
        out.push({ n: "upside down", c: Array.from(mapLetters(t, (ch, code) => {
            var c = ch.toLowerCase().charCodeAt(0)
            if (c >= 97 && c <= 122) return flipLower[c - 97]
            return flipOther[ch] !== undefined ? flipOther[ch] : null
        })).reverse().join("") })
        out.push({ n: "spaced", c: Array.from(t).join(" ") })
        return out
    }

    // ═══════════════════ Actions ═══════════════════
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
        if (!filter) return
        var q = filter.text
        if (section.id === "fancy") results = fancy(q.trim() === "" ? "tzeuk" : q)
        else if (!loaded) results = []
        else if (section.id === "recent") {
            if (q.trim() === "") results = recent(300)
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
    function move(key) {
        var v = view
        if (listMode) {
            if (key === Qt.Key_Up) v.decrementCurrentIndex()
            else if (key === Qt.Key_Down) v.incrementCurrentIndex()
            return
        }
        if (key === Qt.Key_Up) v.moveCurrentIndexUp()
        else if (key === Qt.Key_Down) v.moveCurrentIndexDown()
        else if (key === Qt.Key_Left) v.moveCurrentIndexLeft()
        else if (key === Qt.Key_Right) v.moveCurrentIndexRight()
    }
    function page(d) {
        var step = listMode ? 10 : grid.cols * Math.max(1, Math.floor(grid.height / grid.cellHeight))
        view.currentIndex = Math.max(0, Math.min(results.length - 1, view.currentIndex + d * step))
    }
    function fontOf(it) {
        return it && it.s !== undefined && sets[it.s] && sets[it.s].id === "emoji"
            ? "Noto Color Emoji" : cNf
    }

    // ═══════════════════ Open / close ═══════════════════
    property real t: opened ? 1 : 0
    Behavior on t { NumberAnimation { duration: cT; easing.type: Easing.BezierSpline; easing.bezierCurve: cGlide } }

    visible: t > 0
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tzeuk-chars"
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenedChanged: {
        if (!opened) return
        hovered = null
        buffer = ""
        filter.text = ""
        grp = -1
        sec = loaded && recent(1).length ? 1 : 0
        recompute()
        focusTimer.restart()
    }
    onSecChanged: { grp = -1; recompute() }
    onGrpChanged: recompute()
    Timer { id: debounce; interval: 40; onTriggered: win.recompute() }
    Timer { id: focusTimer; interval: 80; onTriggered: filter.forceActiveFocus() }

    // ═══════════════════ UI ═══════════════════
    Rectangle {
        anchors.fill: parent
        color: cScrim
        opacity: win.t
        MouseArea { anchors.fill: parent; onClicked: win.closeRequested() }
    }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round((parent.height - height) / 2) - 30 + 24 * (1 - win.t)
        width: Math.min(parent.width - 80, 960)
        height: Math.min(parent.height - 160, 740)
        opacity: win.t
        radius: 0
        color: cS1
        border.width: 1
        border.color: cS2
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 30
            spacing: 14

            // ── Search + tone + close ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 60
                    radius: 0
                    color: cS2

                    Icon {
                        id: lens
                        x: 22
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.iSearch
                        color: cGrey
                        font.pixelSize: 20
                    }
                    Text {
                        anchors.left: filter.left
                        anchors.right: count.left
                        anchors.verticalCenter: parent.verticalCenter
                        visible: filter.text === ""
                        elide: Text.ElideRight
                        text: win.loadError
                            ? win.loadError
                            : (win.section.id === "fancy"
                               ? "Type some text"
                               : "Search " + win.section.label + " (name, keyword, u+f0001, or paste a glyph)")
                        color: win.loadError ? cLive : cMute
                        font.family: cUi
                        font.pixelSize: 18
                    }
                    TextInput {
                        id: filter
                        anchors.left: lens.right
                        anchors.leftMargin: 14
                        anchors.right: count.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: cFg
                        selectionColor: cFill
                        selectedTextColor: cFillFg
                        font.family: cUi
                        font.pixelSize: 18
                        clip: true
                        cursorDelegate: Rectangle {
                            width: 2
                            color: cLive
                            visible: filter.activeFocus
                            Timer {
                                running: filter.activeFocus
                                interval: 500; repeat: true
                                onTriggered: parent.opacity = 1 - parent.opacity
                            }
                        }
                        onTextChanged: {
                            if (text !== "" && win.section.id === "recent") win.sec = 0
                            if (text === "") win.recompute(); else debounce.restart()
                        }
                        Keys.onEscapePressed: win.closeRequested()
                        Keys.onPressed: event => {
                            var k = event.key, m = event.modifiers
                            var vim = {
                                [Qt.Key_H]: Qt.Key_Left, [Qt.Key_J]: Qt.Key_Down,
                                [Qt.Key_K]: Qt.Key_Up,   [Qt.Key_L]: Qt.Key_Right
                            }
                            if ((m & Qt.ControlModifier) && vim[k] !== undefined) {
                                win.hovered = null
                                win.move(vim[k])
                                event.accepted = true
                                return
                            }
                            if (k === Qt.Key_Return || k === Qt.Key_Enter) {
                                if (debounce.running) { debounce.stop(); win.recompute() }
                                var it = win.results[win.view.currentIndex]
                                if (m & Qt.ControlModifier) win.pick(it, "buffer")
                                else if (m & Qt.ShiftModifier) win.pick(it, "type")
                                else if (m & Qt.AltModifier) win.pick(it, "code")
                                else win.pick(it, "copy")
                            } else if (k === Qt.Key_Tab) win.cycleSection(1)
                            else if (k === Qt.Key_Backtab) win.cycleSection(-1)
                            else if ((m & Qt.ControlModifier) && (k === Qt.Key_Left || k === Qt.Key_Right))
                                win.cycleGroup(k === Qt.Key_Left ? -1 : 1)
                            else if ((m & Qt.AltModifier) && k >= Qt.Key_1 && k < Qt.Key_1 + win.sections.length)
                                win.sec = k - Qt.Key_1
                            else if (k === Qt.Key_Up || k === Qt.Key_Down
                                     || (!win.listMode && (k === Qt.Key_Left || k === Qt.Key_Right))) {
                                win.hovered = null
                                win.move(k)
                            } else if (k === Qt.Key_PageDown) win.page(1)
                            else if (k === Qt.Key_PageUp) win.page(-1)
                            else if (k === Qt.Key_Backspace && filter.text === "" && win.buffer !== "")
                                win.buffer = Array.from(win.buffer).slice(0, -1).join("")
                            else return
                            event.accepted = true
                        }
                    }
                    Lb {
                        id: count
                        anchors.right: parent.right
                        anchors.rightMargin: 22
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.results.length
                    }
                }
                Row {
                    visible: win.loaded && (win.section.id === "emoji"
                             || win.section.id === "all" || win.section.id === "recent")
                    spacing: 2
                    Repeater {
                        model: 6
                        delegate: Rectangle {
                            required property int index
                            readonly property var hand: win.byChar["✋"]
                            width: 40; height: 40; radius: 20
                            color: win.tone === index ? cFill
                                 : (tm.containsMouse ? cS3 : "transparent")
                            Text {
                                anchors.centerIn: parent
                                text: parent.hand ? win.glyph(parent.hand, parent.index) : ""
                                font.family: "Noto Color Emoji"
                                font.pixelSize: 17
                            }
                            MouseArea {
                                id: tm
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { win.tone = parent.index; filter.forceActiveFocus() }
                            }
                        }
                    }
                }
                IconBtn { implicitHeight: 48; icon: win.iClose; onClicked: win.closeRequested() }
            }

            // ── Sections ──
            Row {
                Layout.fillWidth: true
                spacing: 2
                Repeater {
                    model: win.sections
                    delegate: Chip {
                        required property var modelData
                        required property int index
                        text: modelData.label
                        selected: win.sec === index
                        onClicked: { win.sec = index; filter.forceActiveFocus() }
                    }
                }
            }

            // ── Groups ──
            ListView {
                id: chips
                Layout.fillWidth: true
                implicitHeight: 32
                visible: win.groups.length > 0
                orientation: ListView.Horizontal
                spacing: 4
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: win.groups.length ? ["all"].concat(win.groups) : []
                currentIndex: win.grp + 1
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                delegate: Chip {
                    required property var modelData
                    required property int index
                    height: 32
                    px: 10
                    filled: true
                    text: modelData
                    selected: win.grp === index - 1
                    onClicked: { win.grp = index - 1; filter.forceActiveFocus() }
                }
            }

            // ── Results ──
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

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
                        readonly property bool selected: grid.currentIndex === index
                        width: grid.cellWidth - 4
                        height: grid.cellHeight - 4
                        radius: 18
                        color: selected ? cFill : (gm.containsMouse ? cS2 : "transparent")
                        Text {
                            anchors.centerIn: parent
                            text: cell.it ? win.glyph(cell.it, win.tone) : ""
                            color: cell.selected ? cFillFg : cFg
                            font.family: win.fontOf(cell.it)
                            font.pixelSize: 26
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
                        readonly property bool selected: list.currentIndex === index
                        width: list.width
                        height: 52
                        radius: 0
                        color: selected ? cFill : (lm.containsMouse ? cS2 : "transparent")
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 22
                            anchors.right: tag.left
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.it ? row.it.c : ""
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            color: row.selected ? cFillFg : cFg
                            font.family: cUi
                            font.pixelSize: 18
                        }
                        Lb {
                            id: tag
                            anchors.right: parent.right
                            anchors.rightMargin: 22
                            anchors.verticalCenter: parent.verticalCenter
                            px: 10
                            text: row.it ? (win.section.id === "fancy" ? row.it.n : row.it.k) : ""
                            color: row.selected ? cFillFg : cGrey
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
                }

                Lb {
                    anchors.centerIn: parent
                    visible: win.results.length === 0
                    color: win.loadError ? cLive : cMute
                    text: win.loadError ? win.loadError
                        : (!win.loaded && win.section.id !== "fancy" ? "loading glyphs…"
                        : (win.section.id === "recent" && filter.text === "" ? "nothing used yet"
                        : "no matches"))
                }
            }

            // ── Footer preview ──
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 92
                radius: 0
                color: cS2

                Rectangle {
                    id: big
                    visible: !win.listMode
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: visible ? 68 : 0
                    height: 68
                    radius: 34
                    color: cS3
                    Text {
                        anchors.centerIn: parent
                        text: win.current ? win.glyph(win.current, win.tone) : ""
                        color: cFill
                        font.family: win.fontOf(win.current)
                        font.pixelSize: 36
                    }
                }
                Column {
                    anchors.left: big.right
                    anchors.leftMargin: 16
                    anchors.right: buf.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Text {
                        width: parent.width
                        text: win.current ? win.current.n : ""
                        elide: Text.ElideRight
                        color: cFg
                        font.family: cUi
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }
                    Lb {
                        width: parent.width
                        visible: win.current !== null && win.section.id !== "fancy"
                        px: 10
                        color: cFill
                        text: {
                            var c = win.current
                            if (!c || c.s === undefined || !win.sets[c.s]) return ""
                            var st = win.sets[c.s]
                            return (st.id === "kao" ? "" : win.hex(win.glyph(c, win.tone)) + " · ")
                                + st.label + " · " + st.groups[c.g]
                        }
                        elide: Text.ElideRight
                    }
                    Lb {
                        width: parent.width
                        visible: text !== ""
                        px: 10
                        text: win.current && win.current.k && win.section.id !== "kao" ? win.current.k : ""
                        elide: Text.ElideRight
                    }
                }
                Row {
                    id: buf
                    anchors.right: parent.right
                    anchors.rightMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    visible: win.buffer !== ""
                    width: visible ? implicitWidth : 0
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.iBuffer
                        color: cLive
                        font.pixelSize: 18
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, 220)
                        text: win.buffer
                        elide: Text.ElideLeft
                        color: cFg
                        font.family: cNf
                        font.pixelSize: 20
                    }
                }
            }
        }
    }

    // ── Footer hints ──
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: card.bottom
        anchors.topMargin: 26
        opacity: win.t
        spacing: 30
        Repeater {
            model: ["↵ copy"]
                .concat(win.hasWtype ? ["shift ↵ type"] : [])
                .concat(["ctrl ↵ collect", "alt ↵ code", "ctrl hjkl move",
                         "tab section", "ctrl ←→ group", "esc close"])
            Lb { required property string modelData; text: modelData }
        }
    }
}
