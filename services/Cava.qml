pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool available: false
    property var values: []
    readonly property int bars: 64
    readonly property bool active: values.length > 0

    readonly property string conf:
        "[general]\n" +
        "bars = " + bars + "\n" +
        "framerate = 60\n" +
        "sleep_timer = 2\n" +
        "[input]\n" +
        "method = pipewire\n" +
        "source = auto\n" +
        "[output]\n" +
        "method = raw\n" +
        "raw_target = /dev/stdout\n" +
        "channels = mono\n" +
        "data_format = ascii\n" +
        "ascii_max_range = 1000\n" +
        "bar_delimiter = 59\n" +
        "frame_delimiter = 10\n" +
        "[smoothing]\n" +
        "noise_reduction = 60\n" +
        "monstercat = 1\n" +
        "waves = 1\n"

    Process {
        command: ["sh", "-c", "command -v cava"]
        running: true
        onExited: code => root.available = code === 0
    }

    Process {
        id: proc
        running: root.available
        command: ["sh", "-c",
            'mkdir -p "${2%/*}" && printf "%s" "$1" > "$2" && exec cava -p "$2"',
            "sh", root.conf, Quickshell.env("HOME") + "/.cache/tzeuk/cava.conf"]
        stdout: SplitParser {
            onRead: line => {
                var p = line.split(";"), out = []
                for (var i = 0; i < p.length; i++)
                    if (p[i] !== "") out.push(parseInt(p[i]) / 1000)
                root.values = out
            }
        }
    }

    onAvailableChanged: if (!available) values = []
}
