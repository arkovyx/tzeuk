import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: picker
    property bool shown: false
    property string mode: "normal"      // "normal" | "insert"

    WallSettings { id: settings }

    FontLoader { id: fDotLoader;  source: Qt.resolvedUrl("../fonts/Doto.ttf") }
    FontLoader { id: fSansLoader; source: Qt.resolvedUrl("../fonts/SpaceGrotesk-Regular.otf") }
    FontLoader { id: fBoldLoader; source: Qt.resolvedUrl("../fonts/SpaceGrotesk-Bold.otf") }
    FontLoader { id: fMonoLoader; source: Qt.resolvedUrl("../fonts/SpaceMono-Regular.ttf") }

    readonly property string fDot:  fDotLoader.name  !== "" ? fDotLoader.name  : "monospace"
    readonly property string fSans: fSansLoader.name !== "" ? fSansLoader.name : "sans-serif"
    readonly property string fBold: fBoldLoader.name !== "" ? fBoldLoader.name : "sans-serif"
    readonly property string fMono: fMonoLoader.name !== "" ? fMonoLoader.name : "monospace"

    readonly property color cBlack: "#000000"
    readonly property color cWhite: "#FFFFFF"
    readonly property color cRed: "#D71921"
    function dim(a) { return Qt.rgba(1, 1, 1, a) }
    function pad2(n) { return String(n).padStart(2, "0") }

    // ── State ──
    property string viewMode: "all"       // "all" | "folders"
    property string currentPath: ""
    property string filterQuery: ""
    property var allWallpapers: []
    property var allDirs: [""]
    property var folderCounts: ({})
    property var folderPreview: ({})
    property bool scanning: false

    // ── Derived ──
    readonly property var displayedItems: {
        let items = rebuildItems()
        if (!filterQuery) return items
        const q = filterQuery.toLowerCase()
        return items.filter(it => {
            if (it.type === "folder") return it.name.toLowerCase().indexOf(q) >= 0
            return it.file.toLowerCase().indexOf(q) >= 0
        })
    }

    readonly property var breadcrumb: {
        const parts = currentPath === "" ? [] : currentPath.split("/")
        const out = [{ label: "WALLPAPERS", path: "" }]
        let acc = ""
        for (let i = 0; i < parts.length; i++) {
            acc = acc === "" ? parts[i] : acc + "/" + parts[i]
            out.push({ label: parts[i], path: acc })
        }
        return out
    }

    function rebuildItems() {
        if (viewMode === "all") return allWallpapers
        const out = []
        const prefix = currentPath === "" ? "" : currentPath + "/"
        const folderSet = Object.create(null)
        for (let i = 0; i < allDirs.length; i++) {
            const d = allDirs[i]
            if (d === "" || d === currentPath) continue
            if (!d.startsWith(prefix)) continue
            const rest = d.substring(prefix.length)
            if (rest.indexOf("/") >= 0) continue
            if (folderSet[rest]) continue
            folderSet[rest] = true
            out.push({
                type: "folder",
                name: rest,
                path: d,
                count: folderCounts[d] || 0,
                preview: folderPreview[d] || null
            })
        }
        out.sort((a, b) => a.name.localeCompare(b.name))
        for (let i = 0; i < allWallpapers.length; i++) {
            const w = allWallpapers[i]
            if (w.dir === currentPath) out.push(w)
        }
        return out
    }

    // ── Scan ──
    Process {
        id: scanProcess
        stdout: StdioCollector {
            id: scanOut
            onStreamFinished: picker.parseScan(scanOut.text)
        }
    }

    function scan() {
        scanning = true
        const extExpr = settings.imageExtensions.map(e => "-iname '*." + e + "'").join(" -o ")
        const script = `
ROOT='${settings.wallpapersRoot}'
[ -d "$ROOT" ] || exit 0
find "$ROOT" -type d -printf 'D|%P\\n' 2>/dev/null
find "$ROOT" -type f \\( ${extExpr} \\) -printf 'F|%P\\n' 2>/dev/null
`
        scanProcess.command = ["bash", "-c", script]
        scanProcess.running = true
    }

    function parseScan(text) {
        const files = []
        const dirSet = Object.create(null)
        dirSet[""] = true
        const exts = {}
        for (let i = 0; i < settings.imageExtensions.length; i++)
            exts[settings.imageExtensions[i].toLowerCase()] = true

        const lines = String(text || "").split("\n")
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            if (!line) continue
            const sep = line.indexOf("|")
            if (sep <= 0) continue
            const kind = line.substring(0, sep)
            const rel = line.substring(sep + 1)
            if (!rel) continue
            if (kind === "D") {
                dirSet[rel] = true
            } else if (kind === "F") {
                const slash = rel.lastIndexOf("/")
                const file = slash < 0 ? rel : rel.substring(slash + 1)
                const dir = slash < 0 ? "" : rel.substring(0, slash)
                const dot = file.lastIndexOf(".")
                if (dot < 0) continue
                const ext = file.substring(dot + 1).toLowerCase()
                if (!exts[ext]) continue
                files.push({
                    type: "wallpaper",
                    dir: dir,
                    file: file,
                    relative: rel,
                    path: settings.wallpapersRoot + "/" + rel,
                    thumb: settings.thumbDir + "/" + rel.split("/").join("__")
                })
            }
        }
        files.sort((a, b) => a.relative.localeCompare(b.relative))

        const counts = Object.create(null)
        const preview = Object.create(null)
        for (let i = 0; i < files.length; i++) {
            const f = files[i]
            const parts = f.relative.split("/")
            for (let j = 0; j < parts.length - 1; j++) {
                const folderPath = parts.slice(0, j + 1).join("/")
                counts[folderPath] = (counts[folderPath] || 0) + 1
                if (!preview[folderPath]) preview[folderPath] = f
            }
        }

        allWallpapers = files
        allDirs = Object.keys(dirSet)
        folderCounts = counts
        folderPreview = preview
        scanning = false
        syncThumbs()
    }

    Process { id: thumbProcess }

    function syncThumbs() {
        const extExpr = settings.imageExtensions.map(e => "-iname '*." + e + "'").join(" -o ")
        const script = `
THUMB_DIR='${settings.thumbDir}'
ROOT='${settings.wallpapersRoot}'
mkdir -p "$THUMB_DIR"
CMD=""
if command -v magick >/dev/null 2>&1; then CMD="magick"
elif command -v convert >/dev/null 2>&1; then CMD="convert"
else exit 0
fi
find "$ROOT" -type f \\( ${extExpr} \\) -print0 2>/dev/null | while IFS= read -r -d '' src; do
    rel="\${src#$ROOT/}"
    dest="$THUMB_DIR/\${rel//\\//__}"
    if [ -f "$dest" ] && [ "$dest" -nt "$src" ]; then continue; fi
    $CMD "$src" -auto-orient -thumbnail '800x500>' -quality 82 "$dest" 2>/dev/null || true
done
`
        thumbProcess.command = ["bash", "-c", script]
        thumbProcess.running = true
    }

    // ── Navigation ──
    function enterFolder(path) {
        currentPath = path
        viewMode = "folders"
        filterQuery = ""
        searchInput.text = ""
        Qt.callLater(() => { carousel.currentIndex = 0; searchInput.forceActiveFocus() })
    }

    function goUp() {
        if (currentPath === "") { viewMode = "all"; return }
        const parts = currentPath.split("/")
        parts.pop()
        currentPath = parts.join("/")
        filterQuery = ""
        searchInput.text = ""
        Qt.callLater(() => { carousel.currentIndex = 0; searchInput.forceActiveFocus() })
    }

    function gotoPath(path) {
        currentPath = path
        viewMode = "folders"
        filterQuery = ""
        searchInput.text = ""
        Qt.callLater(() => { carousel.currentIndex = 0; searchInput.forceActiveFocus() })
    }

    function toggleMode() {
        viewMode = viewMode === "all" ? "folders" : "all"
        currentPath = ""
        filterQuery = ""
        searchInput.text = ""
        Qt.callLater(() => { carousel.currentIndex = 0; searchInput.forceActiveFocus() })
    }

    function activateCurrent() {
        if (carousel.currentIndex < 0) return
        const items = displayedItems
        if (carousel.currentIndex >= items.length) return
        const item = items[carousel.currentIndex]
        if (item.type === "folder") enterFolder(item.path)
        else applyWallpaper(item)
    }

    function handleEscape() {
        if (filterQuery !== "") {
            filterQuery = ""
            searchInput.text = ""
            return
        }
        if (viewMode === "folders" && currentPath !== "") { goUp(); return }
        if (viewMode === "folders") { viewMode = "all"; return }
        shown = false
    }

    // ── Apply ──
    function applyWallpaper(item) {
    if (!item || item.type !== "wallpaper") return

    const script = `
WALL="$1"
CACHE_DIR="$2"
DUR="$3"
FPS="$4"
BACKEND_PREF="$5"
COLOR_PREF="$6"
TYPES_STR="$7"

mkdir -p "$CACHE_DIR"
printf '%s' "$WALL" > "$CACHE_DIR/last_wallpaper"

LOG="$CACHE_DIR/apply.log"
if [ -f "$LOG" ] && [ "$(stat -c%s "$LOG" 2>/dev/null || echo 0)" -gt 1000000 ]; then
    : > "$LOG"
fi
exec >> "$LOG" 2>&1
echo ""
echo "=== $(date '+%F %T') ==="
echo "WALL=$WALL"

BACKEND="$BACKEND_PREF"
if [ "$BACKEND" = "auto" ] || [ -z "$BACKEND" ]; then
    if command -v awww >/dev/null 2>&1; then BACKEND="awww"
    elif command -v swww >/dev/null 2>&1; then BACKEND="swww"
    elif command -v hyprctl >/dev/null 2>&1; then BACKEND="hyprpaper"
    else BACKEND="none"
    fi
fi
echo "BACKEND=$BACKEND"

pick_transition() {
    local arr=( $TYPES_STR )
    local n=\${#arr[@]}
    if [ "$n" -eq 0 ]; then echo "fade"; return; fi
    local idx=$((RANDOM % n))
    echo "\${arr[$idx]}"
}

case "$BACKEND" in
    awww)
        pgrep -x awww-daemon >/dev/null 2>&1 || { awww-daemon >/dev/null 2>&1 & sleep 0.6; }
        T=$(pick_transition)
        echo "TRANSITION=$T"
        if ! awww img --transition-type "$T" --transition-duration "$DUR" --transition-fps "$FPS" "$WALL"; then
            echo "awww transition failed, trying plain img"
            awww img "$WALL" || echo "awww FAILED"
        fi
        ;;
    swww)
        pgrep -x swww-daemon >/dev/null 2>&1 || { swww-daemon >/dev/null 2>&1 & sleep 0.6; }
        T=$(pick_transition)
        echo "TRANSITION=$T"
        if ! swww img --transition-type "$T" --transition-duration "$DUR" --transition-fps "$FPS" "$WALL"; then
            echo "swww transition failed, trying plain img"
            swww img "$WALL" || echo "swww FAILED"
        fi
        ;;
    hyprpaper)
        pgrep -x hyprpaper >/dev/null 2>&1 || echo "WARN: hyprpaper not running"
        if hyprctl hyprpaper wallpaper ",$WALL"; then
            echo "hyprpaper OK (direct)"
        else
            echo "hyprpaper direct failed, preloading + per-monitor"
            hyprctl hyprpaper preload "$WALL" || true
            sleep 0.15
            MONS=$(hyprctl monitors 2>/dev/null | awk '/^Monitor /{print $2}')
            if [ -n "$MONS" ]; then
                for mon in $MONS; do
                    hyprctl hyprpaper wallpaper "$mon,$WALL" || true
                done
            else
                hyprctl hyprpaper wallpaper ",$WALL" || true
            fi
        fi
        ;;
    *)
        echo "No wallpaper backend found"
        exit 1
        ;;
esac

CB="$COLOR_PREF"
if [ "$CB" = "auto" ] || [ -z "$CB" ]; then
    if command -v wal >/dev/null 2>&1; then CB="pywal"
    elif command -v matugen >/dev/null 2>&1; then CB="matugen"
    else CB="none"
    fi
fi
echo "COLOR=$CB"
if [ "$CB" = "pywal" ]; then
    wal -i "$WALL" -n -q || echo "pywal FAILED"
elif [ "$CB" = "matugen" ]; then
    matugen image "$WALL" || echo "matugen FAILED"
fi
`
    Quickshell.execDetached([
        "bash", "-c", script, "apply",
        item.path,
        settings.cacheDir,
        String(settings.transitionDuration),
        String(settings.transitionFps),
        settings.wallpaperBackend,
        settings.colorBackend,
        settings.setAnimations.join(" ")
    ])
    shown = false
}
    // ── Lifecycle ──
    onShownChanged: {
        if (shown) {
            mode = "normal"
            viewMode = "all"
            currentPath = ""
            filterQuery = ""
            scan()
            Qt.callLater(() => { carousel.currentIndex = 0; searchInput.forceActiveFocus() })
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["bash", "-c",
            "mkdir -p '" + settings.cacheDir + "' '" + settings.thumbDir + "'"])
    }

    IpcHandler {
        target: "wallpaper"
        function toggle() { picker.shown = !picker.shown }
        function open()   { picker.shown = true }
        function close()  { picker.shown = false }
    }

    // ── UI ──
    PanelWindow {
        id: win
        visible: picker.shown
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "tzeuk-wallpicker"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        readonly property var scr: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        implicitWidth: scr ? Math.round(scr.width * 0.82) : 1400
        implicitHeight: scr ? Math.round(scr.height * 0.68) : 800

        Rectangle {
            anchors.fill: parent
            radius: 28
            color: picker.cBlack
            border.color: picker.cWhite
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 26
                spacing: 12

                // ── HEADER ──
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56

                    Text {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        text: "WALLPAPER"
                        color: picker.cWhite
                        font.family: picker.fDot
                        font.weight: Font.Black
                        font.pixelSize: 46
                        font.letterSpacing: 1
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        spacing: 12

                        // view-mode toggle pill (hover effect)
                        Rectangle {
                            id: viewToggle
                            width: 86; height: 26; radius: 13
                            color: viewToggleHover.containsMouse
                                ? Qt.rgba(0.84, 0.10, 0.13, 0.15) : "transparent"
                            border.color: picker.cRed
                            border.width: viewToggleHover.containsMouse ? 2 : 1
                            Behavior on border.width { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: picker.viewMode === "all" ? "ALL" : "FOLDERS"
                                color: picker.cRed
                                font.family: picker.fMono
                                font.pixelSize: 10
                                font.letterSpacing: 1.5
                            }
                            MouseArea {
                                id: viewToggleHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: picker.toggleMode()
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: picker.pad2(picker.displayedItems.length)
                            color: picker.cWhite
                            font.family: picker.fDot
                            font.weight: Font.Black
                            font.pixelSize: 24
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 8; height: 8; radius: 4
                            color: picker.cRed
                            SequentialAnimation on opacity {
                                running: win.visible
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.2; duration: 800 }
                                NumberAnimation { to: 1.0; duration: 800 }
                            }
                        }
                    }
                }

                // ── SEARCH ──
                Rectangle {
                    id: searchBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 21
                    color: "transparent"
                    border.color: picker.mode === "insert" ? picker.cWhite
                        : (searchBoxHover.containsMouse ? picker.dim(0.55) : picker.dim(0.25))
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Text {
                        id: prompt
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        text: "/"
                        color: picker.cRed
                        font.family: picker.fDot
                        font.weight: Font.Black
                        font.pixelSize: 20
                    }

                    // mode badge — always on top
                    Rectangle {
                        id: modeBadge
                        z: 101
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 76; height: 26; radius: 13
                        color: picker.mode === "insert"
                            ? (modeBadgeHover.containsMouse
                                ? Qt.rgba(0.84, 0.10, 0.13, 0.15) : "transparent")
                            : picker.cWhite
                        border.width: picker.mode === "insert" ? 1 : 0
                        border.color: picker.cRed
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: picker.mode === "insert" ? "INSERT" : "NORMAL"
                            color: picker.mode === "insert" ? picker.cRed : picker.cBlack
                            font.family: picker.fMono
                            font.pixelSize: 10
                            font.letterSpacing: 1
                        }

                        MouseArea {
                            id: modeBadgeHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                picker.mode = picker.mode === "insert" ? "normal" : "insert"
                                if (picker.mode === "insert") searchInput.forceActiveFocus()
                            }
                        }
                    }

                    TextInput {
                        id: searchInput
                        z: 1
                        anchors.left: prompt.right
                        anchors.leftMargin: 10
                        anchors.right: modeBadge.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        color: picker.cWhite
                        selectionColor: picker.cRed
                        selectedTextColor: picker.cWhite
                        font.family: picker.fSans
                        font.pixelSize: 15
                        clip: true
                        readOnly: picker.mode === "normal"
                        inputMethodHints: Qt.ImhNoPredictiveText

                        onTextChanged: {
                            picker.filterQuery = text.toLowerCase()
                            carousel.currentIndex = 0
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchInput.text.length === 0
                            text: "FILTER BY NAME..."
                            color: picker.dim(0.4)
                            font.family: picker.fMono
                            font.pixelSize: 11
                            font.letterSpacing: 1.5
                        }

                        cursorDelegate: Rectangle {
                            width: picker.mode === "insert" ? 2 : 0
                            color: picker.cRed
                            visible: picker.mode === "insert"
                        }

                        Keys.onPressed: (event) => picker.handleKey(event)
                    }

                    // whole-box click → enter insert (NORMAL only)
                    MouseArea {
                        id: searchBoxHover
                        z: 100
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: picker.mode === "normal"
                        cursorShape: Qt.IBeamCursor
                        onClicked: {
                            picker.mode = "insert"
                            searchInput.forceActiveFocus()
                        }
                    }
                }

                // ── BREADCRUMB (with hover) ──
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: (picker.viewMode === "folders") ? 18 : 0
                    visible: picker.viewMode === "folders"

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Repeater {
                            model: picker.breadcrumb
                            delegate: Row {
                                id: crumb
                                spacing: 6
                                readonly property bool isLast: index === picker.breadcrumb.length - 1

                                Text {
                                    text: modelData.label
                                    color: crumb.isLast
                                        ? picker.cWhite
                                        : (crumbHover.containsMouse ? picker.cWhite : picker.dim(0.5))
                                    font.family: picker.fMono
                                    font.pixelSize: 11
                                    font.letterSpacing: 1
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                                Text {
                                    visible: !crumb.isLast
                                    text: "/"
                                    color: picker.dim(0.3)
                                    font.family: picker.fMono
                                    font.pixelSize: 11
                                }
                                MouseArea {
                                    id: crumbHover
                                    anchors.fill: parent
                                    hoverEnabled: !crumb.isLast
                                    enabled: !crumb.isLast
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: picker.gotoPath(modelData.path)
                                }
                            }
                        }
                    }
                }

                // ── DOT RULE ──
                Canvas {
                    id: ruleTop
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                    onPaint: picker.paintDots(ruleTop, 5, 0.45)
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                }

                // ── CAROUSEL ──
                ListView {
                    id: carousel
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: ListView.Horizontal
                    spacing: 0
                    clip: false
                    focus: false

                    highlightRangeMode: ListView.StrictlyEnforceRange
                    preferredHighlightBegin: (width - (settings.cardWidth + settings.cardSpacing)) / 2
                    preferredHighlightEnd: (width + (settings.cardWidth + settings.cardSpacing)) / 2
                    highlightMoveDuration: 280

                    model: picker.displayedItems

                    header: Item { width: Math.max(0, (carousel.width - settings.cardWidth - settings.cardSpacing) / 2) }
                    footer: Item { width: Math.max(0, (carousel.width - settings.cardWidth - settings.cardSpacing) / 2) }

                    delegate: Item {
                        id: dRoot
                        width: settings.cardWidth + settings.cardSpacing
                        height: carousel.height

                        readonly property bool isCurrent: ListView.isCurrentItem
                        readonly property var item: modelData
                        readonly property bool isFolder: item && item.type === "folder"

                        readonly property real cardScale: isCurrent
                            ? 1.0
                            : (cardMouse.containsMouse ? 0.88 : 0.82)
                        readonly property real borderAlpha: isCurrent
                            ? 1.0
                            : (cardMouse.containsMouse ? 0.60 : 0.25)

                        readonly property string thumbSource: {
                            if (!item) return ""
                            if (isFolder) {
                                const p = item.preview
                                return p && p.thumb ? "file://" + p.thumb : ""
                            }
                            return item.thumb ? "file://" + item.thumb : ""
                        }
                        readonly property string fallbackSource: {
                            if (!item) return ""
                            if (isFolder) {
                                const p = item.preview
                                return p && p.path ? "file://" + p.path : ""
                            }
                            return item.path ? "file://" + item.path : ""
                        }

                        Item {
                            anchors.centerIn: parent
                            width: settings.cardWidth * dRoot.cardScale
                            height: settings.cardHeight * dRoot.cardScale

                            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                            Item {
                                anchors.fill: parent
                                transform: Matrix4x4 {
                                    property real s: settings.cardSkew
                                    matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                    border.color: picker.dim(dRoot.borderAlpha)
                                    border.width: dRoot.isCurrent ? 2 : 1
                                    Behavior on border.color { ColorAnimation { duration: 180 } }
                                }

                                Item {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    clip: true

                                    Rectangle { anchors.fill: parent; color: picker.cBlack }

                                    Image {
                                        anchors.centerIn: parent
                                        width: parent.width + parent.height * Math.abs(settings.cardSkew) + 4
                                        height: parent.height
                                        source: dRoot.thumbSource !== "" ? dRoot.thumbSource : dRoot.fallbackSource
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: true
                                        opacity: dRoot.isCurrent ? 1.0
                                            : (cardMouse.containsMouse ? 0.78 : 0.62)
                                        Behavior on opacity { NumberAnimation { duration: 180 } }

                                        transform: Matrix4x4 {
                                            property real s: -settings.cardSkew
                                            matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                                        }

                                        onStatusChanged: {
                                            if (status === Image.Error
                                                && dRoot.fallbackSource !== ""
                                                && source.toString() !== dRoot.fallbackSource)
                                                source = dRoot.fallbackSource
                                        }
                                    }

                                    // folder overlay — lifts on hover to reveal preview
                                    Rectangle {
                                        visible: dRoot.isFolder
                                        anchors.fill: parent
                                        color: Qt.rgba(0, 0, 0,
                                            dRoot.isCurrent ? 0.55
                                            : (cardMouse.containsMouse ? 0.42 : 0.62))
                                        Behavior on color { ColorAnimation { duration: 180 } }
                                    }

                                    Column {
                                        visible: dRoot.isFolder
                                        anchors.centerIn: parent
                                        spacing: 6
                                        width: parent.width - 40

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: dRoot.item ? dRoot.item.name.toUpperCase() : ""
                                            color: picker.cWhite
                                            font.family: picker.fBold
                                            font.pixelSize: 18
                                            font.letterSpacing: 2
                                            elide: Text.ElideRight
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        Rectangle {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 24; height: 1
                                            color: picker.cRed
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: dRoot.item
                                                ? picker.pad2(dRoot.item.count) + " ITEM" + (dRoot.item.count === 1 ? "" : "S")
                                                : ""
                                            color: picker.dim(0.7)
                                            font.family: picker.fMono
                                            font.pixelSize: 11
                                            font.letterSpacing: 1
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    picker.mode = "normal"
                                    carousel.currentIndex = index
                                    if (dRoot.isFolder) picker.enterFolder(dRoot.item.path)
                                    else picker.applyWallpaper(dRoot.item)
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: carousel.count === 0
                        text: picker.scanning ? "SCANNING..."
                            : (picker.filterQuery !== "" ? "NO MATCHES" : "EMPTY")
                        color: picker.dim(0.5)
                        font.family: picker.fMono
                        font.pixelSize: 12
                        font.letterSpacing: 2
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        onWheel: (w) => {
                            const d = w.angleDelta.y
                            if (d > 0 && carousel.currentIndex > 0) carousel.currentIndex--
                            else if (d < 0 && carousel.currentIndex < carousel.count - 1) carousel.currentIndex++
                            w.accepted = true
                        }
                    }
                }

                // ── DOT RULE BOTTOM ──
                Canvas {
                    id: ruleBottom
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                    onPaint: picker.paintDots(ruleBottom, 5, 0.45)
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                }

                // ── FOOTER ──
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 18

                    Text {
                        text: picker.mode === "insert"
                            ? "◀▶ NAV   ⏎ APPLY   ESC NORMAL"
                            : "◀▶ NAV   SPACE ⏎ SELECT   I INSERT   TAB VIEW   ESC BACK"
                        color: picker.dim(0.45)
                        font.family: picker.fMono
                        font.pixelSize: 10
                        font.letterSpacing: 1
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: carousel.count === 0
                            ? "00/00"
                            : picker.pad2(carousel.currentIndex + 1) + "/" + picker.pad2(carousel.count)
                        color: picker.cRed
                        font.family: picker.fDot
                        font.weight: Font.Black
                        font.pixelSize: 16
                    }
                }
            }
        }
    }

    // ── Keyboard (vim) ──
    function handleKey(event) {
        const shift = (event.modifiers & Qt.ShiftModifier) !== 0
        event.accepted = true

        // ── Shared ──
        if (event.key === Qt.Key_Left) {
            if (carousel.currentIndex > 0) carousel.currentIndex--
            return
        }
        if (event.key === Qt.Key_Right) {
            if (carousel.currentIndex < carousel.count - 1) carousel.currentIndex++
            return
        }
        if (event.key === Qt.Key_PageUp) {
            carousel.currentIndex = Math.max(0, carousel.currentIndex - 5)
            return
        }
        if (event.key === Qt.Key_PageDown) {
            carousel.currentIndex = Math.min(carousel.count - 1, carousel.currentIndex + 5)
            return
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            activateCurrent()
            return
        }
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            toggleMode()
            return
        }

        // ── INSERT ──
        if (mode === "insert") {
            if (event.key === Qt.Key_Escape) {
                mode = "normal"
                return
            }
            event.accepted = false
            return
        }

        // ── NORMAL ──
        switch (event.key) {
        case Qt.Key_Escape:
            handleEscape()
            break
        case Qt.Key_I:
        case Qt.Key_Slash:
            mode = "insert"
            searchInput.forceActiveFocus()
            break
        case Qt.Key_H:
            if (carousel.currentIndex > 0) carousel.currentIndex--
            break
        case Qt.Key_L:
            if (carousel.currentIndex < carousel.count - 1) carousel.currentIndex++
            break
        case Qt.Key_G:
            carousel.currentIndex = shift ? carousel.count - 1 : 0
            break
        case Qt.Key_Space:
            activateCurrent()
            break
        case Qt.Key_Backspace:
            if (viewMode === "folders") goUp()
            break
        }
    }

    function paintDots(canvas, gap, alpha) {
        const ctx = canvas.getContext("2d")
        ctx.reset()
        ctx.fillStyle = "rgba(255,255,255," + alpha + ")"
        for (let y = gap / 2; y < canvas.height; y += gap)
            for (let x = gap / 2; x < canvas.width; x += gap) {
                ctx.beginPath()
                ctx.arc(x, y, 1, 0, Math.PI * 2)
                ctx.fill()
            }
    }
}
