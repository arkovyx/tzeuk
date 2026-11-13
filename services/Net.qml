pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    property bool wifiEnabled: true
    property string wifiDevice: ""
    property string connected: ""
    property int activeSignal: 0
    property var networks: []
    property var savedSSIDs: []
    property var wiredDevs: []
    property bool scanning: false
    property string message: ""
    property string askFor: ""

    function refresh() {
        radioProc.running = true
        statusProc.running = true
        if (active) {
            savedProc.running = true
            listProc.running = true
        }
    }

    function rescan() {
        if (scanning) return
        scanning = true
        message = ""
        rescanProc.running = true
    }

    function setWifi(on) {
        message = ""
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"])
        refreshDelay.restart()
        if (on) scanAfterOnTimer.start()
    }

    function connectTo(net) {
        if (!net) return
        if (net.inUse) { disconnect(); return }
        if (net.security === "" || net.security === "--" || net.saved) {
            message = ""
            askFor = ""
            connectProc.command = ["nmcli", "device", "wifi", "connect", net.ssid]
            connectProc.running = true
        } else {
            askFor = net.ssid
        }
    }

    function connect(ssid, password) {
        if (!ssid) return
        message = ""
        askFor = ""
        connectProc.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password]
        connectProc.running = true
    }

    function disconnect() {
        if (connected === "") return
        message = ""
        Quickshell.execDetached(["nmcli", "connection", "down", connected])
        refreshDelay.restart()
    }

    function disconnectDev(dev) {
        if (!dev) return
        Quickshell.execDetached(["nmcli", "device", "disconnect", dev])
        refreshDelay.restart()
    }

    function openNmtui() {
        Quickshell.execDetached(["foot", "-e", "nmtui"])
    }

    function parseTerse(line) {
        var out = [], cur = ""
        for (var i = 0; i < line.length; i++) {
            var ch = line[i]
            if (ch === "\\" && i + 1 < line.length) { cur += line[i + 1]; i++ }
            else if (ch === ":") { out.push(cur); cur = "" }
            else cur += ch
        }
        out.push(cur)
        return out
    }

    Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.refresh()
    }
    Timer { id: refreshDelay; interval: 900; onTriggered: root.refresh() }
    Timer { id: scanAfterOnTimer; interval: 1600; onTriggered: root.rescan() }

    onActiveChanged: {
        if (active) root.refresh()
        else { radioProc.running = true; statusProc.running = true }
    }

    Process {
        id: radioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    Process {
        id: statusProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                var dev = "", conn = ""
                var wired = []
                for (var i = 0; i < lines.length; i++) {
                    var f = root.parseTerse(lines[i])
                    if (f.length < 4) continue
                    if (f[1] === "wifi") {
                        if (dev === "") dev = f[0]
                        if (f[2] === "connected" && f[3] !== "" && f[3] !== "--") conn = f[3]
                    } else if (f[1] === "ethernet" && f[2] === "connected") {
                        wired.push({ dev: f[0], name: f[3], ip: "", usb: false })
                    }
                }
                root.wifiDevice = dev
                root.connected = conn
                root.wiredDevs = wired
            }
        }
    }

    Process {
        id: savedProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                var saved = []
                for (var i = 0; i < lines.length; i++) {
                    var f = root.parseTerse(lines[i])
                    if (f.length >= 2 && f[1].indexOf("wireless") >= 0 && f[0]) saved.push(f[0])
                }
                root.savedSSIDs = saved
            }
        }
    }

    Process {
        id: rescanProc
        command: ["nmcli", "device", "wifi", "rescan"]
        onExited: { root.scanning = false; listProc.running = true }
    }

    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                var best = {}
                var lines = text.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var f = root.parseTerse(lines[i])
                    if (f.length < 4 || f[1] === "") continue
                    var e = {
                        inUse: f[0] === "*",
                        ssid: f[1],
                        signal: parseInt(f[2]) || 0,
                        security: f[3],
                        saved: root.savedSSIDs.indexOf(f[1]) >= 0
                    }
                    var o = best[e.ssid]
                    if (!o || e.inUse || (!o.inUse && e.signal > o.signal)) best[e.ssid] = e
                }
                var out = []
                for (var k in best) out.push(best[k])
                out.sort(function(a, b) {
                    if (a.inUse !== b.inUse) return a.inUse ? -1 : 1
                    return b.signal - a.signal
                })
                root.networks = out
                for (var j = 0; j < out.length; j++) {
                    if (out[j].inUse || out[j].ssid === root.connected) {
                        root.activeSignal = out[j].signal
                        break
                    }
                }
                if (root.connected === "") root.activeSignal = 0
            }
        }
    }

    Process {
        id: connectProc
        stderr: StdioCollector { id: connectErr }
        stdout: StdioCollector { id: connectOut }
        onExited: (code) => {
            if (code === 0) {
                root.message = ""
                root.refresh()
                refreshDelay.restart()
            } else {
                var err = String(connectErr.text || "").trim()
                if (err === "") err = String(connectOut.text || "").trim()
                var low = err.toLowerCase()
                if (low.indexOf("secrets") >= 0 || low.indexOf("password") >= 0) {
                    root.message = "Wrong password. Try again."
                } else if (low.indexOf("no network") >= 0) {
                    root.message = "Network not found."
                } else if (err.indexOf("Error:") >= 0) {
                    root.message = err.substring(err.indexOf("Error:")).split("\n")[0]
                } else {
                    root.message = "Connection failed: " + err.split("\n")[0]
                }
            }
        }
    }
}
