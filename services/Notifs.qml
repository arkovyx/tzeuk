pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root
    property bool dnd: false
    property var popups: []       // [{n, until}]
    readonly property int count: server.trackedNotifications.values.length

    function history() {
        var l = server.trackedNotifications.values, out = []
        for (var i = l.length - 1; i >= 0; i--) out.push(l[i])
        return out
    }

    function clearAll() {
        var l = server.trackedNotifications.values, all = []
        for (var i = 0; i < l.length; i++) all.push(l[i])
        for (var j = 0; j < all.length; j++) all[j].dismiss()
        popups = []
    }

    function dropPopup(n) {
        popups = popups.filter(function(p) { return p.n !== n })
    }

    function push(n) {
        var isCritical = (n.urgency === 2)
        var ms = (isCritical || n.expireTimeout <= 0) ? 8000 : Math.min(n.expireTimeout, 8000)
        var next = popups.concat([{ n: n, until: Date.now() + ms }])
        popups = next.slice(-4)   // max 4 stacked
        n.closed.connect(function() { root.dropPopup(n) })
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        onNotification: function(n) {
            n.tracked = true
            if (!root.dnd || n.urgency === 2) root.push(n)
        }
    }

    Timer {
        interval: 500
        running: root.popups.length > 0
        repeat: true
        onTriggered: {
            var now = Date.now()
            var keep = root.popups.filter(function(p) { return p.until > now })
            if (keep.length !== root.popups.length) root.popups = keep
        }
    }
}
