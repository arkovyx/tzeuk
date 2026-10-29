pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool wifiEnabled: true
    property var networks: []       // [{ssid, signal, security, inUse, saved}]
    property bool scanning: false
    property bool connecting: false
    property string errorMsg: ""

    function refresh() {
        radioProc.running = true
        savedProc.running = true
        listProc.running = true
    }

    function setWifi(on) {
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"])
        wifiEnabled = on
        if (on) rescan()
    }

    function rescan() {
        scanning = true
        rescanProc.running = true
    }

    function connect(ssid, password) {
        errorMsg = ""
        connecting = true
        var isSaved = false
        for (var i = 0; i < networks.length; i++) {
            if (networks[i].ssid === ssid && networks[i].saved) isSaved = true
        }

        if (isSaved) {
            connectProc.command = ["nmcli", "connection", "up", "id", ssid]
        } else {
            var cmd = ["nmcli", "device", "wifi", "connect", ssid]
            if (password && password !== "") cmd = cmd.concat(["password", password])
            connectProc.command = cmd
        }
        connectProc.running = true
    }

    function disconnect() {
        for (var i = 0; i < networks.length; i++) {
            if (networks[i].inUse) {
                Quickshell.execDetached(["nmcli", "device", "disconnect", "wlan0"]) // Adjust wlan0 if needed
                break
            }
        }
        refresh()
    }

    Timer { interval: 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: refresh() }

    Process {
        id: radioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: root.wifiEnabled = text.trim() === "enabled" }
    }

    Process {
        id: savedProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                var saved = []
                var lines = text.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var f = lines[i].split(":")
                    if (f.length >= 2 && f[1].includes("wireless")) saved.push(f[0])
                }
                // Store saved list temporarily to use in listProc
                root.savedNetworks = saved
            }
        }
    }
    property var savedNetworks: []

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
                var out = [], lines = text.split("\n"), best = {}
                for (var i = 0; i < lines.length; i++) {
                    var f = lines[i].split(":")
                    if (f.length < 4 || f[1] === "") continue
                    var e = {
                        inUse: f[0] === "*",
                        ssid: f[1],
                        signal: parseInt(f[2]) || 0,
                        security: f[3] === "" ? "Open" : f[3],
                        saved: root.savedNetworks.includes(f[1])
                    }
                    // Keep the strongest signal for duplicate SSIDs
                    if (!best[e.ssid] || e.inUse || (!best[e.ssid].inUse && e.signal > best[e.ssid].signal)) {
                        best[e.ssid] = e
                    }
                }
                for (var k in best) out.push(best[k])
                out.sort(function(a, b) {
                    if (a.inUse !== b.inUse) return a.inUse ? -1 : 1
                    return b.signal - a.signal
                })
                root.networks = out
            }
        }
    }

    Process {
        id: connectProc
        stderr: StdioCollector { id: connErr }
        onExited: (code) => {
            root.connecting = false
            if (code !== 0) {
                root.errorMsg = "Failed to connect. Check password."
            } else {
                root.refresh()
            }
        }
    }
}
