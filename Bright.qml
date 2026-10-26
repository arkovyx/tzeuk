pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property int percent: 50

    function refresh() { getProc.running = true }
    function setPercent(v) {
        percent = Math.round(v)
        setProc.command = ["brightnessctl", "set", Math.max(1, percent) + "%"]
        setProc.running = true
    }

    Process {
        id: getProc
        command: ["brightnessctl", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var p = text.trim().split(",")
                if (p.length >= 4) root.percent = parseInt(p[3])
            }
        }
    }
    Process { id: setProc; onExited: root.refresh() }
}
