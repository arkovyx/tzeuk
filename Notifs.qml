pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root
    property bool dnd: false
    readonly property int count: server.trackedNotifications.values.length

    function clearAll() {
        var l = server.trackedNotifications.values
        for (var i = 0; i < l.length; i++) l[i].dismiss()
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        onNotification: n => {
            n.tracked = true
            // We will add popups later! For now, we just count them.
        }
    }
}
