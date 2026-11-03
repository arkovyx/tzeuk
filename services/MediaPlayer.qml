pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    // Prioritize MPD, fallback to any other active player
    readonly property var player: {
        const players = Mpris.players.values;
        const mpd = players.find(p => p.dbusName === "org.mpris.MediaPlayer2.mpd");
        if (mpd && mpd.trackTitle) return mpd;
        return players.find(p => p.isPlaying && p.trackTitle) ?? players[0] ?? null;
    }

    readonly property bool hasMedia: player !== null && (player.trackTitle || "").length > 0
}
