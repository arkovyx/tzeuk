pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property real value: 0

    Process {
        id: p
        command: ["cat", "/proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(" ")
                if (parts.length > 0) root.value = parseFloat(parts[0]) || 0
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: p.running = true
    }
}
