pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    property real cpu: 0
    property real memUsed: 0
    property real memTotal: 0
    property var disks: []
    property real uptime: 0
    property real prevIdle: -1
    property real prevTotal: 0

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBat: battery !== null && battery.isPresent
    readonly property real batPct: hasBat ? (battery.percentage > 1 ? battery.percentage / 100 : battery.percentage) : 0
    readonly property bool charging: hasBat && battery.state === UPowerDeviceState.Charging

    FileView { id: statFile; path: "/proc/stat"; blockLoading: true }
    FileView { id: memFile; path: "/proc/meminfo"; blockLoading: true }
    FileView { id: upFile; path: "/proc/uptime"; blockLoading: true }

    function sample() {
        statFile.reload()
        var m = statFile.text().match(/^cpu\s+(.*)$/m)
        if (m) {
            var f = m[1].trim().split(/\s+/).map(Number)
            var idle = f[3] + (f[4] || 0)
            var total = 0
            for (var i = 0; i < Math.min(8, f.length); i++) total += f[i]
            if (prevIdle >= 0 && total > prevTotal)
                cpu = Math.max(0, Math.min(1, 1 - (idle - prevIdle) / (total - prevTotal)))
            prevIdle = idle
            prevTotal = total
        }

        memFile.reload()
        var mt = memFile.text()
        var t = mt.match(/MemTotal:\s+(\d+)/), a = mt.match(/MemAvailable:\s+(\d+)/)
        if (t && a) {
            memTotal = parseInt(t[1]) / 1048576
            memUsed = (parseInt(t[1]) - parseInt(a[1])) / 1048576
        }

        upFile.reload()
        uptime = parseFloat(upFile.text().split(" ")[0]) || 0
    }

    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: sample() }

    function refreshDisks() { dfProc.running = true }

    function parseDf(text) {
        var lines = text.split("\n"), seen = {}, out = []
        for (var i = 1; i < lines.length; i++) {
            var m = lines[i].match(/^(\S+)\s+(\d+)\s+(\d+)\s+(.*)$/)
            if (!m) continue
            var src = m[1], target = m[4].trim()
            if (src.indexOf("/dev/") !== 0 || src.indexOf("/dev/loop") === 0) continue
            if (seen[src]) continue
            seen[src] = true
            var size = parseFloat(m[3])
            if (size <= 0) continue
            var parts = target.split("/").filter(function(x) { return x !== "" })
            out.push({
                label: parts.length ? parts[parts.length - 1] : "/",
                used: parseFloat(m[2]) / 1073741824,
                size: size / 1073741824
            })
        }
        return out
    }

    Process {
        id: dfProc
        command: ["df", "-l", "-B1", "--output=source,used,size,target"]
        stdout: StdioCollector { onStreamFinished: root.disks = root.parseDf(text) }
    }

    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: refreshDisks() }

    function fmtSize(v) { return v >= 1000 ? (v/1024).toFixed(1) + "T" : (v >= 100 ? Math.round(v) : v.toFixed(1)) + "G" }
    function fmtTime(s) {
        if (!s || s <= 0) return "-"
        var d = Math.floor(s / 86400)
        var h = Math.floor((s % 86400) / 3600)
        var m = Math.floor((s % 3600) / 60)
        if (d > 0) return d + "d " + h + "h"
        if (h > 0) return h + "h " + m + "m"
        return m + "m"
    }
}
