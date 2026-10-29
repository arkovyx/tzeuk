pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: true
    property string wifiDevice: ""
    property string connected: ""
    property int activeSignal: 0
    property var networks: []           // [{ssid, signal, security, inUse}]
    property bool scanning: false
    property string message: ""

    function refresh() {
        radioProc.running = true
        statusProc.running = true
        listProc.running = true
    }

    function rescan() {
        scanning = true
        rescanProc.running = true
    }

    function setWifi(on) {
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"])
        refreshTimer.restart()
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

    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { id: refreshTimer; interval: 800; onTriggered: root.refresh() }

    Process {
        id: radioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: root.wifiEnabled = text.trim() === "enabled" }
    }

    Process {
        id: statusProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n"), dev = "", conn = ""
                for (var i = 0; i < lines.length; i++) {
                    var f = root.parseTerse(lines[i])
                    if (f.length >= 4 && f[1] === "wifi") {
                        if (dev === "") dev = f[0]
                        if (f[2] === "connected" && f[3] !== "" && f[3] !== "--") conn = f[3]
                    }
                }
                root.wifiDevice = dev
                root.connected = conn
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
                var best = {}, lines = text.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var f = root.parseTerse(lines[i])
                    if (f.length < 4 || f[1] === "") continue
                    var e = { inUse: f[0] === "*", ssid: f[1], signal: parseInt(f[2]) || 0, security: f[3] }
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
                // Sync signal for the bar
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
}
