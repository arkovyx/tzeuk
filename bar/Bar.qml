import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../services"
import "../workspaces"

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    signal togglePanel(string name, var scr)

    anchors { top: true; left: true; right: true }
    margins { top: 8; left: 20; right: 20 }
    implicitHeight: 44
    color: "transparent"
    WlrLayershell.namespace: "tzeuk-bar-nothing"

    FontLoader { id: fDoto; source: "../fonts/Doto.ttf" }
    FontLoader { id: fMono; source: "../fonts/SpaceMono-Regular.ttf" }
    FontLoader { id: fGrotesk; source: "../fonts/SpaceGrotesk-Regular.otf" }

    readonly property string fDotStr: fDoto.name !== "" ? fDoto.name : "monospace"
    readonly property string fMonoStr: fMono.name !== "" ? fMono.name : "monospace"
    readonly property string fGroteskStr: fGrotesk.name !== "" ? fGrotesk.name : "sans-serif"

    readonly property color nBlack: "#000000"
    readonly property color nWhite: "#ffffff"
    readonly property color nRed: "#d71921"
    readonly property color nDim: "#333333"
    readonly property color nSurface: "#1A1A1A"

    readonly property var hmon: Hyprland.monitorFor(modelData)
    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

    // ── BATTERY ─────────────────────────────────────────────
    property real batPct: 0
    property bool charging: false
    property bool plugged: false
    property bool hasBat: false

    Process {
        id: batPctProc
        command: ["sh", "-c", "for d in /sys/class/power_supply/BAT*; do [ -f \"$d/capacity\" ] && cat \"$d/capacity\" && exit; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var p = parseInt(text.trim())
                if (!isNaN(p) && p >= 0) {
                    bar.batPct = p / 100
                    bar.hasBat = true
                }
            }
        }
    }
    Process {
        id: batStateProc
        command: ["sh", "-c", "for d in /sys/class/power_supply/BAT*; do [ -f \"$d/status\" ] && cat \"$d/status\" && exit; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var s = text.trim()
                bar.charging = (s === "Charging")
                bar.plugged = (s === "Full")
            }
        }
    }
    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: {
            batPctProc.running = false; batStateProc.running = false
            batPctProc.running = true; batStateProc.running = true
        }
    }

    function getBatteryIcon() {
        if (charging || plugged) return "\uf1e6"
        if (batPct >= 0.75) return "\uf240"
        if (batPct >= 0.50) return "\uf241"
        if (batPct >= 0.25) return "\uf242"
        if (batPct >= 0.10) return "\uf243"
        return "\uf244"
    }

    // ── WI-FI STATE ─────────────────────────────────────────
    property bool wifiPopupOpen: false
    property bool wifiEnabled: false
    property bool wifiScanning: false
    property var wifiNetworks: []
    property string wifiActiveSSID: ""
    property string wifiError: ""
    property string pendingSSID: ""

    Process {
        id: wifiRadioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: bar.wifiEnabled = text.trim() === "enabled"
        }
    }
    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: wifiRadioProc.running = true
    }

    Process {
        id: wifiListProc
        command: ["nmcli", "--mode", "multiline", "--fields", "SSID,SIGNAL,SECURITY,ACTIVE", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var blocks = text.trim().split(/\n\n+/)
                var result = []
                for (var i = 0; i < blocks.length; i++) {
                    var obj = {}
                    var lines = blocks[i].split("\n")
                    for (var j = 0; j < lines.length; j++) {
                        var idx = lines[j].indexOf(":")
                        if (idx < 0) continue
                        obj[lines[j].substring(0, idx)] = lines[j].substring(idx + 1)
                    }
                    if (!obj.SSID || obj.SSID === "") continue
                    var sig = parseInt(obj.SIGNAL) || 0
                    var sec = obj.SECURITY || ""
                    result.push({
                        ssid: obj.SSID,
                        signal: sig,
                        security: sec,
                        active: obj.ACTIVE === "yes",
                        secured: sec !== "" && sec !== "--"
                    })
                }
                result.sort((a, b) => {
                    if (a.active && !b.active) return -1
                    if (!a.active && b.active) return 1
                    return b.signal - a.signal
                })
                bar.wifiNetworks = result
                var act = result.find(n => n.active)
                bar.wifiActiveSSID = act ? act.ssid : ""
                bar.wifiScanning = false
            }
        }
    }

    function startWifiScan() {
        if (bar.wifiScanning) return
        bar.wifiScanning = true
        bar.wifiError = ""
        Quickshell.execDetached(["nmcli", "device", "wifi", "rescan"])
        wifiScanTimer.start()
    }
    Timer {
        id: wifiScanTimer
        interval: 1200; repeat: false
        onTriggered: wifiListProc.running = true
    }

    function toggleWifiRadio() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", bar.wifiEnabled ? "off" : "on"])
        wifiRadioTimer.start()
        if (!bar.wifiEnabled) bar.wifiScanTimer2.start()
    }
    Timer {
        id: wifiRadioTimer
        interval: 500
        onTriggered: wifiRadioProc.running = true
    }
    Timer {
        id: wifiScanTimer2
        interval: 1500
        onTriggered: if (bar.wifiEnabled) bar.startWifiScan()
    }

    function connectWifi(ssid, secured, password) {
        bar.wifiError = ""
        var cmd = ["nmcli", "device", "wifi", "connect", ssid]
        if (secured && password) cmd = cmd.concat(["password", password])
        Quickshell.execDetached(cmd)
        wifiConnectTimer.start()
    }
    Timer {
        id: wifiConnectTimer
        interval: 2500
        onTriggered: {
            wifiListProc.running = true
            wifiActiveProc.running = true
        }
    }
    Process {
        id: wifiActiveProc
        command: ["bash", "-c", "nmcli -t -f NAME,TYPE connection show --active | grep ':802-11-wireless' | cut -d: -f1"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "" && bar.pendingSSID !== "") {
                    bar.wifiError = "Failed to connect. Password may be required."
                } else {
                    bar.wifiError = ""
                }
                bar.pendingSSID = ""
            }
        }
    }

    function disconnectWifi() {
        var ssid = bar.wifiActiveSSID
        if (!ssid) return
        Quickshell.execDetached(["bash", "-c", "nmcli connection down id \"" + ssid + "\" 2>/dev/null || nmcli device disconnect $(nmcli -t -f DEVICE,TYPE device | grep ':wifi' | cut -d: -f1) 2>/dev/null"])
        wifiConnectTimer.start()
    }

    function wifiSignalIcon(sig) {
        if (sig > 80) return "󰤨"
        if (sig > 60) return "󰤥"
        if (sig > 40) return "󰤢"
        if (sig > 20) return "󰤟"
        return "󰤯"
    }

    function wifiBarIcon() {
        if (!bar.wifiEnabled) return "󰤮"
        if (bar.wifiScanning) return "󰤩"
        if (bar.wifiActiveSSID !== "") return "󰤨"
        return "󰤯"
    }

    // ── BLUETOOTH STATE ─────────────────────────────────────
    property bool btPopupOpen: false
    property bool btEnabled: false
    property bool btScanning: false
    property bool btAvailable: true
    property var btDevices: []
    readonly property int btConnectedCount: {
        var n = 0
        for (var i = 0; i < bar.btDevices.length; i++)
            if (bar.btDevices[i].connected) n++
        return n
    }

    Process {
        id: btShowProc
        command: ["bash", "-c", "command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl show 2>/dev/null | grep -m1 'Powered:'"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "") {
                    bar.btAvailable = false
                    bar.btEnabled = false
                    return
                }
                bar.btAvailable = true
                bar.btEnabled = text.indexOf("yes") >= 0
            }
        }
    }
    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: btShowProc.running = true
    }

    Process {
        id: btListProc
        command: ["bash", "-c",
            "command -v bluetoothctl >/dev/null 2>&1 || exit 0\n" +
            "for mac in $(bluetoothctl devices 2>/dev/null | awk '{print $2}'); do\n" +
            "  info=$(bluetoothctl info \"$mac\" 2>/dev/null)\n" +
            "  conn=$(echo \"$info\" | grep -m1 'Connected:' | awk '{print $NF}')\n" +
            "  paired=$(echo \"$info\" | grep -m1 'Paired:' | awk '{print $NF}')\n" +
            "  name=$(echo \"$info\" | grep -m1 'Name:' | sed 's/^.*Name: //')\n" +
            "  [ -z \"$name\" ] && name=$(bluetoothctl devices 2>/dev/null | grep \"$mac\" | cut -d' ' -f3-)\n" +
            "  echo \"$mac|$name|$conn|$paired\"\n" +
            "done"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                var result = []
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].split("|")
                    if (p.length < 3 || !p[0]) continue
                    result.push({
                        mac: p[0],
                        name: p[1] || p[0],
                        connected: p[2] === "yes",
                        paired: p[3] === "yes"
                    })
                }
                result.sort((a, b) => {
                    if (a.connected && !b.connected) return -1
                    if (!a.connected && b.connected) return 1
                    return a.name.localeCompare(b.name)
                })
                bar.btDevices = result
            }
        }
    }

    function toggleBtRadio() {
        if (!bar.btAvailable) return
        Quickshell.execDetached(["bluetoothctl", "power", bar.btEnabled ? "off" : "on"])
        btPowerTimer.start()
    }
    Timer {
        id: btPowerTimer
        interval: 500
        onTriggered: btShowProc.running = true
    }

    function startBtScan() {
        if (bar.btScanning || !bar.btAvailable || !bar.btEnabled) return
        bar.btScanning = true
        Quickshell.execDetached(["bash", "-c", "bluetoothctl scan on >/dev/null 2>&1 &"])
        btScanPoll.start()
        btScanStop.start()
    }
    Timer {
        id: btScanPoll
        interval: 1500; repeat: true
        onTriggered: btListProc.running = true
    }
    Timer {
        id: btScanStop
        interval: 15000
        onTriggered: {
            Quickshell.execDetached(["bluetoothctl", "scan", "off"])
            bar.btScanning = false
            btScanPoll.stop()
            btListProc.running = true
        }
    }

    function connectBt(mac) {
        Quickshell.execDetached(["bluetoothctl", "connect", mac])
        btActionTimer.start()
    }
    function disconnectBt(mac) {
        Quickshell.execDetached(["bluetoothctl", "disconnect", mac])
        btActionTimer.start()
    }
    function forgetBt(mac) {
        Quickshell.execDetached(["bash", "-c",
            "bluetoothctl disconnect " + mac + " 2>/dev/null; " +
            "bluetoothctl remove " + mac + " 2>/dev/null"])
        btActionTimer.start()
    }
    Timer {
        id: btActionTimer
        interval: 1500
        onTriggered: btListProc.running = true
    }

    function btBarIcon() {
        if (!bar.btAvailable) return "󰂲"
        if (!bar.btEnabled) return "󰂲"
        if (bar.btScanning) return "󰂰"
        if (bar.btConnectedCount > 0) return "󰂱"
        return "󰂯"
    }

    // ── POPUP MANAGEMENT ─────────────────────────────────────
    function openWifiPopup() {
        bar.btPopupOpen = false
        bar.wifiPopupOpen = !bar.wifiPopupOpen
        if (bar.wifiPopupOpen) {
            bar.wifiError = ""
            if (bar.wifiEnabled) bar.startWifiScan()
        }
    }
    function openBtPopup() {
        bar.wifiPopupOpen = false
        bar.btPopupOpen = !bar.btPopupOpen
        if (bar.btPopupOpen) btListProc.running = true
    }

    // ── BAR UI ──────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 22
        color: bar.nBlack
        border.width: 1
        border.color: bar.nDim
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15

        Workspaces {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            hmon: bar.hmon
            colWhite: bar.nWhite
            colDim: bar.nDim
            colRed: bar.nRed
            colBlack: bar.nBlack
            fontDot: bar.fDotStr
            rowHeight: 28
        }

        Rectangle {
            id: timePill
            anchors.centerIn: parent
            width: centerContent.implicitWidth + 30
            height: 28
            radius: 14
            color: bar.nSurface
            border.width: 1
            border.color: timeHover.containsMouse ? bar.nRed : bar.nDim
            Behavior on border.color { ColorAnimation { duration: 150 } }

            SystemClock { id: clock; precision: SystemClock.Minutes }

            Row {
                id: centerContent
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: bar.nWhite
                    font.family: bar.fGroteskStr
                    font.pixelSize: 13
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "·"
                    color: bar.nRed
                    font.family: bar.fGroteskStr
                    font.pixelSize: 16
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: Qt.formatDateTime(clock.date, "dd, MMM")
                    color: bar.nWhite
                    font.family: bar.fGroteskStr
                    font.pixelSize: 13
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: timeHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: bar.togglePanel("cal", bar.modelData)
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            NothingBlock {
                icon: Notifs.dnd ? "󰂛" : "󰂚"
                text: Notifs.count > 0 ? String(Notifs.count) : ""
                active: Notifs.dnd || Notifs.count > 0
                nRed: bar.nRed
                nWhite: bar.nWhite
                nDim: bar.nDim
                fMonoStr: bar.fMonoStr
                fGroteskStr: bar.fGroteskStr
                barHeight: bar.height - 8
                onClicked: bar.togglePanel("notif", bar.modelData)
            }

            NothingBlock {
                id: btBlock
                icon: bar.btBarIcon()
                active: bar.btEnabled && bar.btConnectedCount > 0
                nRed: bar.nRed
                nWhite: bar.nWhite
                nDim: bar.nDim
                fMonoStr: bar.fMonoStr
                fGroteskStr: bar.fGroteskStr
                barHeight: bar.height - 8
                onClicked: bar.openBtPopup()
            }

            NothingBlock {
                id: wifiBlock
                icon: bar.wifiBarIcon()
                active: bar.wifiEnabled && bar.wifiActiveSSID !== ""
                nRed: bar.nRed
                nWhite: bar.nWhite
                nDim: bar.nDim
                fMonoStr: bar.fMonoStr
                fGroteskStr: bar.fGroteskStr
                barHeight: bar.height - 8
                onClicked: bar.openWifiPopup()
            }

            NothingBlock {
                icon: {
                    if (!audio) return "󰝟"
                    if (audio.muted) return "󰝟"
                    if (audio.volume <= 0.001) return "󰝟"
                    if (audio.volume < 0.33) return "󰕿"
                    if (audio.volume < 0.66) return "󰖀"
                    return "󰕾"
                }
                text: audio
                    ? (audio.muted ? "MUTE" : Math.round(audio.volume * 100) + "%")
                    : "—"
                active: audio ? audio.muted : false
                nRed: bar.nRed
                nWhite: bar.nWhite
                nDim: bar.nDim
                fMonoStr: bar.fMonoStr
                fGroteskStr: bar.fGroteskStr
                barHeight: bar.height - 8
                onClicked: bar.togglePanel("audio", bar.modelData)
                onWheelScrolled: (delta) => {
                    if (!bar.audio) return
                    const step = 0.05
                    const dir = delta > 0 ? 1 : -1
                    const nv = Math.max(0, Math.min(1, bar.audio.volume + dir * step))
                    bar.audio.volume = nv
                    if (dir > 0 && bar.audio.muted) bar.audio.muted = false
                }
            }

            NothingBlock {
                visible: bar.hasBat
                icon: bar.getBatteryIcon()
                text: bar.hasBat ? Math.round(bar.batPct * 100) + "%" : ""
                nRed: bar.nRed
                nWhite: bar.nWhite
                nDim: bar.nDim
                fMonoStr: bar.fMonoStr
                fGroteskStr: bar.fGroteskStr
                barHeight: bar.height - 8
                onClicked: bar.togglePanel("sys", bar.modelData)
            }
        }
    }

    // ── WI-FI POPUP ─────────────────────────────────────────
    PopupWindow {
        id: wifiPopup
        anchor.window: bar
        anchor.rect.x: bar.width - 460
        anchor.rect.y: bar.height + 6
        implicitWidth: 440
        implicitHeight: 580
        visible: bar.wifiPopupOpen
        color: "transparent"

        Shortcut {
            sequence: "Escape"
            enabled: bar.wifiPopupOpen
            onActivated: bar.wifiPopupOpen = false
        }

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: bar.nBlack
            border.width: 1
            border.color: bar.nDim

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "WI-FI"
                        color: bar.nWhite
                        font.family: bar.fDotStr
                        font.pixelSize: 22
                        font.bold: true
                        font.letterSpacing: 3
                    }

                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 2
                        Layout.alignment: Qt.AlignVCenter
                        color: bar.nRed
                    }

                    Item { Layout.fillWidth: true }

                    // Power toggle
                    Rectangle {
                        width: 56; height: 26; radius: 13
                        color: bar.wifiEnabled ? bar.nRed : bar.nSurface
                        border.color: bar.nDim
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 180 } }

                        Rectangle {
                            x: bar.wifiEnabled ? parent.width - width - 3 : 3
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20; height: 20; radius: 10
                            color: bar.nWhite
                            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bar.toggleWifiRadio()
                        }
                    }

                    // Refresh
                    Rectangle {
                        width: 26; height: 26; radius: 13
                        color: refreshHover.containsMouse ? bar.nSurface : "transparent"
                        border.color: bar.nDim; border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "󰑐"
                            color: bar.wifiScanning ? bar.nRed : bar.nWhite
                            font.family: bar.fMonoStr
                            font.pixelSize: 13
                        }
                        MouseArea {
                            id: refreshHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: bar.wifiEnabled && !bar.wifiScanning
                            onClicked: bar.startWifiScan()
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: bar.nDim }

                // Error
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: bar.wifiError !== "" ? 34 : 0
                    visible: bar.wifiError !== ""
                    color: "#2a0a0d"
                    border.color: bar.nRed
                    border.width: 1
                    radius: 6
                    Text {
                        anchors.centerIn: parent
                        anchors.margins: 8
                        text: bar.wifiError
                        color: bar.nRed
                        font.family: bar.fMonoStr
                        font.pixelSize: 11
                        wrapMode: Text.Wrap
                        width: parent.width - 16
                    }
                }

                // Empty/off state
                Text {
                    visible: !bar.wifiEnabled
                    Layout.fillWidth: true
                    Layout.topMargin: 40
                    text: "▸ Wi-Fi is OFF"
                    color: bar.nText
                    font.family: bar.fMonoStr
                    font.pixelSize: 13
                    font.italic: true
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    visible: bar.wifiEnabled && bar.wifiNetworks.length === 0 && !bar.wifiScanning
                    Layout.fillWidth: true
                    Layout.topMargin: 40
                    text: "▸ No networks found"
                    color: bar.nText
                    font.family: bar.fMonoStr
                    font.pixelSize: 13
                    font.italic: true
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    visible: bar.wifiScanning
                    Layout.fillWidth: true
                    Layout.topMargin: 40
                    text: "▸ Scanning…"
                    color: bar.nText
                    font.family: bar.fMonoStr
                    font.pixelSize: 13
                    font.italic: true
                    horizontalAlignment: Text.AlignHCenter
                }

                // Networks
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: bar.wifiEnabled
                    contentWidth: width
                    contentHeight: netCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: netCol
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: bar.wifiNetworks
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: netCol.width
                                height: 54
                                radius: 8
                                color: modelData.active ? "#1a0003"
                                    : (netHover.containsMouse ? bar.nSurface : "transparent")
                                border.width: 1
                                border.color: modelData.active ? bar.nRed
                                    : (netHover.containsMouse ? bar.nDim : "transparent")
                                Behavior on color { ColorAnimation { duration: 120 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    Text {
                                        text: bar.wifiSignalIcon(modelData.signal)
                                        color: modelData.active ? bar.nRed : bar.nWhite
                                        font.family: bar.fMonoStr
                                        font.pixelSize: 18
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.ssid
                                            color: bar.nWhite
                                            font.family: bar.fSans
                                            font.pixelSize: 13
                                            font.bold: modelData.active
                                            elide: Text.ElideRight
                                        }
                                        RowLayout {
                                            spacing: 6
                                            Text {
                                                text: modelData.signal + "%"
                                                color: bar.nText
                                                font.family: bar.fMonoStr
                                                font.pixelSize: 10
                                            }
                                            Text {
                                                text: modelData.active ? "CONNECTED" : (modelData.secured ? "SECURED" : "OPEN")
                                                color: modelData.active ? bar.nRed : bar.nText
                                                font.family: bar.fMonoStr
                                                font.pixelSize: 10
                                                font.letterSpacing: 1
                                            }
                                        }
                                    }

                                    Text {
                                        visible: modelData.active
                                        text: "DISCONNECT"
                                        color: bar.nRed
                                        font.family: bar.fMonoStr
                                        font.pixelSize: 10
                                        font.letterSpacing: 1
                                    }
                                    Text {
                                        visible: !modelData.active
                                        text: "CONNECT"
                                        color: bar.nWhite
                                        font.family: bar.fMonoStr
                                        font.pixelSize: 10
                                        font.letterSpacing: 1
                                    }
                                }

                                MouseArea {
                                    id: netHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.active) {
                                            bar.disconnectWifi()
                                        } else {
                                            if (modelData.secured) {
                                                bar.wifiError = "Saved network or pre-configure via terminal:\n  nmcli device wifi connect \"" + modelData.ssid + "\" password <pass>"
                                                bar.wifiError = ""
                                                // attempt anyway (saved profiles connect instantly)
                                                bar.pendingSSID = modelData.ssid
                                                bar.connectWifi(modelData.ssid, true, "")
                                            } else {
                                                bar.pendingSSID = modelData.ssid
                                                bar.connectWifi(modelData.ssid, false, "")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Footer
                Text {
                    Layout.fillWidth: true
                    text: bar.wifiNetworks.length + " networks · nmcli"
                    color: bar.nText
                    font.family: bar.fMonoStr
                    font.pixelSize: 10
                    font.letterSpacing: 1
                }
            }
        }
    }

    // ── BLUETOOTH POPUP ─────────────────────────────────────
    PopupWindow {
        id: btPopup
        anchor.window: bar
        anchor.rect.x: bar.width - 460
        anchor.rect.y: bar.height + 6
        implicitWidth: 440
        implicitHeight: 520
        visible: bar.btPopupOpen
        color: "transparent"

        Shortcut {
            sequence: "Escape"
            enabled: bar.btPopupOpen
            onActivated: bar.btPopupOpen = false
        }

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: bar.nBlack
            border.width: 1
            border.color: bar.nDim

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "BLUETOOTH"
                        color: bar.nWhite
                        font.family: bar.fDotStr
                        font.pixelSize: 22
                        font.bold: true
                        font.letterSpacing: 3
                    }

                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 2
                        Layout.alignment: Qt.AlignVCenter
                        color: bar.nRed
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 56; height: 26; radius: 13
                        color: bar.btEnabled ? bar.nRed : bar.nSurface
                        border.color: bar.nDim
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 180 } }

                        Rectangle {
                            x: bar.btEnabled ? parent.width - width - 3 : 3
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20; height: 20; radius: 10
                            color: bar.nWhite
                            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: bar.btAvailable
                            onClicked: bar.toggleBtRadio()
                        }
                    }

                    Rectangle {
                        width: 26; height: 26; radius: 13
                        color: btScanHover.containsMouse ? bar.nSurface : "transparent"
                        border.color: bar.nDim; border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: bar.btScanning ? "󰅖" : "󰑐"
                            color: bar.btScanning ? bar.nRed : bar.nWhite
                            font.family: bar.fMonoStr
                            font.pixelSize: 13
                        }
                        MouseArea {
                            id: btScanHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: bar.btEnabled && bar.btAvailable
                            onClicked: {
                                if (bar.btScanning) {
                                    Quickshell.execDetached(["bluetoothctl", "scan", "off"])
                                    bar.btScanning = false
                                    btScanPoll.stop()
                                    btScanStop.stop()
                                } else {
                                    bar.startBtScan()
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: bar.nDim }

                Text {
                    visible: !bar.btAvailable
                    Layout.fillWidth: true
                    Layout.topMargin: 40
                    text: "▸ No Bluetooth adapter detected"
                    color: bar.nText
                    font.family: bar.fMonoStr
                    font.pixelSize: 13
                    font.italic: true
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    visible: bar.btAvailable && !bar.btEnabled
                    Layout.fillWidth: true
                    Layout.topMargin: 40
                    text: "▸ Bluetooth is OFF"
                    color: bar.nText
                    font.family: bar.fMonoStr
                    font.pixelSize: 13
                    font.italic: true
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    visible: bar.btAvailable && bar.btEnabled && bar.btDevices.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 40
                    text: "▸ No devices — tap refresh to scan"
                    color: bar.nText
                    font.family: bar.fMonoStr
                    font.pixelSize: 13
                    font.italic: true
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    visible: bar.btScanning
                    Layout.fillWidth: true
                    Layout.preferredHeight: bar.btScanning ? 20 : 0
                    text: "▸ Scanning for devices…"
                    color: bar.nRed
                    font.family: bar.fMonoStr
                    font.pixelSize: 11
                    font.italic: true
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: bar.btAvailable && bar.btEnabled
                    contentWidth: width
                    contentHeight: btCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: btCol
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: bar.btDevices
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: btCol.width
                                height: 60
                                radius: 8
                                color: modelData.connected ? "#1a0003"
                                    : (devHover.containsMouse ? bar.nSurface : "transparent")
                                border.width: 1
                                border.color: modelData.connected ? bar.nRed
                                    : (devHover.containsMouse ? bar.nDim : "transparent")
                                Behavior on color { ColorAnimation { duration: 120 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    Text {
                                        text: modelData.connected ? "󰂱" : "󰂯"
                                        color: modelData.connected ? bar.nRed : bar.nWhite
                                        font.family: bar.fMonoStr
                                        font.pixelSize: 20
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.name
                                            color: bar.nWhite
                                            font.family: bar.fSans
                                            font.pixelSize: 13
                                            font.bold: modelData.connected
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: modelData.mac + (modelData.connected ? " · CONNECTED"
                                                : (modelData.paired ? " · PAIRED" : ""))
                                            color: bar.nText
                                            font.family: bar.fMonoStr
                                            font.pixelSize: 10
                                            font.letterSpacing: 0.5
                                        }
                                    }

                                    Text {
                                        text: modelData.connected ? "DISCONNECT" : "CONNECT"
                                        color: modelData.connected ? bar.nRed : bar.nWhite
                                        font.family: bar.fMonoStr
                                        font.pixelSize: 10
                                        font.letterSpacing: 1
                                    }
                                }

                                MouseArea {
                                    id: devHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.connected) bar.disconnectBt(modelData.mac)
                                        else bar.connectBt(modelData.mac)
                                    }
                                    onPressAndHold: bar.forgetBt(modelData.mac)
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: bar.btDevices.length + " devices · bluetoothctl"
                    color: bar.nText
                    font.family: bar.fMonoStr
                    font.pixelSize: 10
                    font.letterSpacing: 1
                }
            }
        }
    }
}
