pragma Singleton
import QtQuick
import Quickshell

Singleton {
    function run(action) {
        switch (action) {
            case "lock":      Quickshell.execDetached(["loginctl", "lock-session"]); break;
            case "sleep":     Quickshell.execDetached(["systemctl", "suspend"]); break;
            case "leave":     Quickshell.execDetached(["hyprctl", "dispatch", "exit"]); break;
            case "reboot":    Quickshell.execDetached(["systemctl", "reboot"]); break;
            case "shutdown":  Quickshell.execDetached(["systemctl", "poweroff"]); break;
        }
    }
}
