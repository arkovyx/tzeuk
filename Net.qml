pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool wifiEnabled: true
    property string connected: ""
    property int signal: 0

    function refresh() {
        radioProc.running = true
        listProc.running = true
    }

    function setWifi(on) {
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"])
        refresh()
    }

    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    Process {
        id: radioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: root.wifiEnabled = text.trim() === "enabled" }
    }

    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var f = lines[i].split(":")
                    if (f.length >= 3 && f[0] === "*") {
                        root.connected = f[1]
                        root.signal = parseInt(f[2]) || 0
                        return
                    }
                }
                root.connected = ""
                root.signal = 0
            }
        }
    }
}
