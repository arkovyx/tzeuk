import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: win
    property bool opened: false
    property bool grabActive: false
    property string query: ""
    property int selectedIndex: 0
    property string activeCategory: "all"

    // Safety caps
    readonly property int maxResults: 2000

    signal closeRequested()

    visible: opened
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tzeuk-glyphs"
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    FontLoader { id: fDoto; source: "../fonts/Doto.ttf" }
    FontLoader { id: fMono; source: "../fonts/SpaceMono-Regular.ttf" }
    FontLoader { id: fGrotesk; source: "../fonts/SpaceGrotesk-Regular.otf" }

    readonly property string fDot: fDoto.name !== "" ? fDoto.name : "monospace"
    readonly property string fMonoStr: fMono.name !== "" ? fMono.name : "monospace"
    readonly property string fSans: fGrotesk.name !== "" ? fGrotesk.name : "sans-serif"

    readonly property color nBlack: "#000000"
    readonly property color nWhite: "#ffffff"
    readonly property color nRed: "#d71921"
    readonly property color nDim: "#2a2a2a"
    readonly property color nSurface: "#0d0d0d"
    readonly property color nText: "#666666"

    property var allGlyphs: []
    property var filteredGlyphs: []

    readonly property var categories: {
        var counts = {}
        for (var i = 0; i < allGlyphs.length; i++) {
            var c = allGlyphs[i].category || "other"
            counts[c] = (counts[c] || 0) + 1
        }
        var out = [{ id: "all", label: "ALL", count: allGlyphs.length }]
        var order = ["emoji", "nerd-fonts", "font-awesome", "math"]
        for (var k = 0; k < order.length; k++)
            if (counts[order[k]])
                out.push({ id: order[k], label: order[k].toUpperCase(), count: counts[order[k]] })
        for (var key in counts)
            if (order.indexOf(key) < 0)
                out.push({ id: key, label: key.toUpperCase(), count: counts[key] })
        return out
    }

    Process {
        id: loadProc
        command: ["sh", "-c",
            "for f in \"$HOME\"/.local/share/chars/*; do " +
            "  [ -f \"$f\" ] || continue; " +
            "  cat=$(basename \"$f\"); " +
            "  while IFS= read -r line; do " +
            "    [ -z \"$line\" ] && continue; " +
            "    glyph=$(printf '%s' \"$line\" | cut -d ';' -f1 | sed 's/ .*//'); " +
            "    name=$(printf '%s' \"$line\" | cut -d ';' -f2- | head -c 80); " +
            "    [ -z \"$glyph\" ] && continue; " +
            "    printf '%s\\t%s\\t%s\\n' \"$glyph\" \"$name\" \"$cat\"; " +
            "  done < \"$f\"; " +
            "done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n")
                var out = []
                var skipped = 0
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i] === "") continue
                    var parts = lines[i].split("\t")
                    if (parts.length < 1 || parts[0] === "") { skipped++; continue }
                    var g = parts[0]
                    // Reject garbage: empty, too long, or looks like a codepoint list
                    if (g.length > 2) { skipped++; continue }
                    if (g.indexOf("U+") === 0) { skipped++; continue }
                    out.push({
                        glyph: g,
                        name: parts.length > 1 ? parts[1] : "",
                        category: parts.length > 2 ? parts[2] : "other"
                    })
                }
                win.allGlyphs = out
                win.filterGlyphs()
                console.log("Glyphs loaded:", out.length, "valid,", skipped, "skipped")
            }
        }
    }

    function filterGlyphs() {
        var q = query.trim().toLowerCase()
        var cat = activeCategory
        var result = []
        for (var i = 0; i < allGlyphs.length; i++) {
            if (result.length >= maxResults) break
            var g = allGlyphs[i]
            if (cat !== "all" && g.category !== cat) continue
            if (q !== "" && g.name.toLowerCase().indexOf(q) < 0) continue
            result.push(g)
        }
        filteredGlyphs = result
        selectedIndex = 0
    }

    onQueryChanged: filterGlyphs()
    onActiveCategoryChanged: filterGlyphs()

    function copyGlyph(glyph) {
        if (!glyph) return
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | wl-copy', "sh", glyph])
        Quickshell.execDetached(["notify-send", "-a", "tzeuk", "-t", "1500", "Copied", glyph])
        closeRequested()
    }

    function navTo(idx) {
        if (win.filteredGlyphs.length === 0) return
        win.selectedIndex = Math.max(0, Math.min(idx, win.filteredGlyphs.length - 1))
    }

    function fontFor(category) {
        if (category === "emoji") return "Noto Color Emoji"
        if (category === "math") return "sans-serif"
        return "JetBrainsMono Nerd Font"
    }

    onOpenedChanged: {
        if (opened) {
            grabDelay.start()
            query = ""
            selectedIndex = 0
            searchInput.forceActiveFocus()
            if (allGlyphs.length === 0) loadProc.running = true
        } else {
            grabActive = false
        }
    }

    Timer {
        id: grabDelay
        interval: 150
        onTriggered: win.grabActive = win.opened
    }

    HyprlandFocusGrab {
        windows: [win]
        active: win.grabActive
        onCleared: win.closeRequested()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: win.closeRequested()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 760
        height: 620
        color: win.nBlack
        border.width: 1
        border.color: win.nDim
        radius: 24

        opacity: win.opened ? 1.0 : 0.0
        scale: win.opened ? 1.0 : 0.94
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }

        focus: true
        Keys.onEscapePressed: win.closeRequested()

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            // ===== Header (no red line, no title) =====
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Item { Layout.fillWidth: true }

                Text {
                    text: win.filteredGlyphs.length
                        + (win.filteredGlyphs.length >= win.maxResults ? "+" : "")
                        + " RESULTS"
                    color: win.nText
                    font.family: win.fSans
                    font.pixelSize: 10
                    font.letterSpacing: 3
                    font.bold: true
                }

                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: closeHover.containsMouse ? win.nRed : win.nSurface
                    border.width: 1
                    border.color: win.nDim

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: win.nWhite
                        font.pixelSize: 20
                        font.bold: true
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.closeRequested()
                    }
                }
            }

            // ===== Category pills =====
            Row {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: win.categories
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isActive: win.activeCategory === modelData.id

                        height: 32
                        width: catLabel.implicitWidth + 28
                        radius: 16
                        color: isActive ? win.nWhite
                             : (catHover.containsMouse ? win.nDim : win.nSurface)
                        border.width: 1
                        border.color: isActive ? win.nWhite : win.nDim

                        Row {
                            id: catLabel
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: modelData.label
                                color: isActive ? win.nBlack : win.nWhite
                                font.family: win.fSans
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 2
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.count
                                color: isActive ? win.nRed : win.nText
                                font.family: win.fMonoStr
                                font.pixelSize: 10
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: catHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.activeCategory = modelData.id
                        }
                    }
                }
            }

            // ===== Search =====
            Rectangle {
                Layout.fillWidth: true
                height: 48
                color: win.nSurface
                border.width: 1
                border.color: searchInput.activeFocus ? win.nRed : win.nDim
                radius: 24

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: win.nRed
                        Layout.alignment: Qt.AlignVCenter
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: win.nWhite
                        font.family: win.fMonoStr
                        font.pixelSize: 15
                        selectionColor: win.nRed
                        selectedTextColor: win.nWhite
                        clip: true

                        onTextChanged: win.query = text

                        Text {
                            anchors.fill: parent
                            visible: searchInput.text === ""
                            text: win.activeCategory === "all"
                                ? "SEARCH ALL GLYPHS..."
                                : "SEARCH " + win.activeCategory.toUpperCase() + "..."
                            color: win.nText
                            font.family: win.fMonoStr
                            font.pixelSize: 15
                            font.letterSpacing: 2
                        }

                        Keys.onEscapePressed: win.closeRequested()
                        Keys.onReturnPressed: {
                            if (win.filteredGlyphs.length > 0)
                                win.copyGlyph(win.filteredGlyphs[win.selectedIndex].glyph)
                        }
                        Keys.onDownPressed: win.navTo(win.selectedIndex + 12)
                        Keys.onUpPressed: win.navTo(win.selectedIndex - 12)
                        Keys.onLeftPressed: win.navTo(win.selectedIndex - 1)
                        Keys.onRightPressed: win.navTo(win.selectedIndex + 1)

                        Keys.onPressed: (event) => {
                            if (win.filteredGlyphs.length === 0) return
                            var ctrl = (event.modifiers & Qt.ControlModifier) !== 0
                            var shift = (event.modifiers & Qt.ShiftModifier) !== 0

                            if (ctrl) {
                                if (event.key === Qt.Key_N || event.key === Qt.Key_J) {
                                    win.navTo(win.selectedIndex + 1); event.accepted = true
                                } else if (event.key === Qt.Key_P || event.key === Qt.Key_K) {
                                    win.navTo(win.selectedIndex - 1); event.accepted = true
                                } else if (event.key === Qt.Key_H) {
                                    win.navTo(win.selectedIndex - 1); event.accepted = true
                                } else if (event.key === Qt.Key_L) {
                                    win.navTo(win.selectedIndex + 1); event.accepted = true
                                } else if (event.key === Qt.Key_D) {
                                    win.navTo(win.selectedIndex + 12); event.accepted = true
                                } else if (event.key === Qt.Key_U) {
                                    win.navTo(win.selectedIndex - 12); event.accepted = true
                                } else if (event.key === Qt.Key_G) {
                                    win.navTo(shift ? win.filteredGlyphs.length - 1 : 0); event.accepted = true
                                }
                            }
                        }
                    }
                }
            }

            // ===== Grid =====
            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: 56
                cellHeight: 56
                clip: true
                model: win.filteredGlyphs
                currentIndex: win.selectedIndex
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 800

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool isSelected: win.selectedIndex === index
                    width: grid.cellWidth - 4
                    height: grid.cellHeight - 4
                    radius: 12
                    color: isSelected ? win.nRed
                         : (glyphHover.containsMouse ? win.nSurface : "transparent")

                    Text {
                        anchors.centerIn: parent
                        text: modelData.glyph
                        color: win.nWhite
                        font.family: win.fontFor(modelData.category)
                        font.pixelSize: 26
                        // Prevent size jitter when glyph is missing
                        fontSizeMode: Text.FixedSize
                    }

                    MouseArea {
                        id: glyphHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: win.selectedIndex = index
                        onClicked: win.copyGlyph(modelData.glyph)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: win.filteredGlyphs.length === 0
                    text: win.allGlyphs.length === 0 ? "LOADING GLYPHS..." : "NO MATCHES"
                    color: win.nText
                    font.family: win.fSans
                    font.pixelSize: 12
                    font.letterSpacing: 4
                    font.bold: true
                }
            }

            // ===== Footer =====
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "↵ COPY   ·   CTRL+J/K NAVIGATE   ·   CTRL+D/U PAGE   ·   CTRL+G FIRST   ·   ESC CLOSE"
                    color: win.nText
                    font.family: win.fMonoStr
                    font.pixelSize: 9
                    font.letterSpacing: 1
                }

                Item { Layout.fillWidth: true }

                Text {
                    visible: win.filteredGlyphs.length > 0
                    text: {
                        var g = win.filteredGlyphs[Math.min(win.selectedIndex, win.filteredGlyphs.length - 1)]
                        return g ? g.name.substring(0, 40).toUpperCase() : ""
                    }
                    color: win.nRed
                    font.family: win.fMonoStr
                    font.pixelSize: 9
                    elide: Text.ElideRight
                    Layout.maximumWidth: 350
                }
            }
        }
    }
}
