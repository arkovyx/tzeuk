pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var actions: [
        { id: "lock",       label: "Lock",       confirm: false },
        { id: "logout",     label: "Log Out",    confirm: false },
        { id: "suspend",    label: "Suspend",    confirm: false },
        { id: "reboot",     label: "Reboot",     confirm: true  },
        { id: "shutdown",   label: "Shut Down",  confirm: true  },
        { id: "screen-off", label: "Screen Off", confirm: false },
        { id: "cancel",     label: "Cancel",     confirm: false }
    ]

    function run(id) {
        switch (id) {
        case "lock":
            Quickshell.execDetached(["hyprlock"])
            break
        case "logout":
            Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
            break
        case "suspend":
            Quickshell.execDetached(["systemctl", "suspend"])
            break
        case "reboot":
            Quickshell.execDetached(["systemctl", "reboot"])
            break
        case "shutdown":
            Quickshell.execDetached(["systemctl", "poweroff"])
            break
        case "screen-off":
            Quickshell.execDetached(["hyprctl", "dispatch", "dpms", "off"])
            break
        case "cancel":
        default:
            break
        }
    }
}
