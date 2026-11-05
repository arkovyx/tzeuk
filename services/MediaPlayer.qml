pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var player: {
        const players = Mpris.players.values;
        const mpd = players.find(p => p.dbusName === "org.mpris.MediaPlayer2.mpd");
        if (mpd && mpd.trackTitle) return mpd;
        return players.find(p => p.isPlaying && p.trackTitle) ?? players[0] ?? null;
    }

    readonly property bool hasMedia: player !== null && player !== undefined && (player.trackTitle || "").length > 0
    readonly property bool isPlaying: player !== null && player !== undefined && player.isPlaying === true

    // --- Persistent disc rotation (survives tab switches & panel toggles) ---
    property real discAngle: 0

    Timer {
        interval: 16
        running: root.isPlaying
        repeat: true
        onTriggered: root.discAngle = (root.discAngle + 0.6) % 360
    }

    // --- Persistent position/length tracking (progress bar works always) ---
    property real position: 0
    property real length: 0

    Timer {
        interval: 500
        running: root.isPlaying
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.player) {
                root.player.positionChanged()
                var p = root.player.position
                if (p !== undefined && p !== null && p >= 0) root.position = p
                var l = root.player.length
                if (l !== undefined && l !== null && l >= 0) root.length = l
            }
        }
    }

    Connections {
        target: root.player
        function onPositionChanged() {
            if (root.player && root.player.position !== undefined)
                root.position = root.player.position
        }
        function onLengthChanged() {
            if (root.player && root.player.length !== undefined)
                root.length = root.player.length
        }
        function onTrackTitleChanged() {
            root.position = 0
        }
        function onPlaybackStateChanged() {
            if (root.player && root.player.position !== undefined)
                root.position = root.player.position
        }
    }
}
