import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import "bar"
import "panel"
import "launcher"
import "glyphs"

ShellRoot {
    id: root

    property bool panelOpen: false
    property var panelScreen: null
    property string activeTab: "home"
    property bool calOpen: false
    property var calScreen: null
    property bool glyphsOpen: false
    property var glyphScreen: null

    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    function focusedScreen() {
        var m = Hyprland.focusedMonitor
        if (m) {
            for (var i = 0; i < Quickshell.screens.length; i++)
                if (Quickshell.screens[i].name === m.name)
                    return Quickshell.screens[i]
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    Variants {
        model: Quickshell.screens
        Bar {
            onTogglePanel: function(name, scr) {
                if (name === "cal") {
                    root.calScreen = scr
                    root.calOpen = !root.calOpen
                    root.panelOpen = false
                } else {
                    if (root.panelOpen && root.activeTab === name) {
                        root.panelOpen = false
                    } else {
                        root.activeTab = name
                        root.panelScreen = scr
                        root.panelOpen = true
                    }
                    root.calOpen = false
                }
            }
        }
    }

    Panel {
        opened: root.panelOpen
        activeTab: root.activeTab
        onTabChanged: function(name) { root.activeTab = name }
        onCloseRequested: root.panelOpen = false
        screen: root.panelScreen !== null ? root.panelScreen : (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
    }

    CalendarPopup {
        opened: root.calOpen
        onCloseRequested: root.calOpen = false
        screen: root.calScreen !== null ? root.calScreen : (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
    }

    Variants {
        model: Quickshell.screens
        NotifPopup {
            suppressed: root.panelOpen && screen === root.panelScreen
        }
    }

    Launcher {
        id: launcher
    }

    // ===== Glyphs picker — opens on focused monitor =====
    Glyphs {
        opened: root.glyphsOpen
        screen: root.glyphScreen !== null ? root.glyphScreen : (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
        onCloseRequested: root.glyphsOpen = false
    }

    // ===== IPC handlers =====
    IpcHandler {
        target: "panel"
        function toggle(): void {
            root.panelOpen = !root.panelOpen
            if (root.panelOpen) {
                root.panelScreen = root.focusedScreen()
                root.activeTab = "home"
            }
        }
        function show(name: string): void {
            root.activeTab = name
            root.panelScreen = root.focusedScreen()
            root.panelOpen = true
        }
        function close(): void { root.panelOpen = false }
    }

    IpcHandler {
        target: "glyphs"
        function toggle(): void {
            if (!root.glyphsOpen) root.glyphScreen = root.focusedScreen()
            root.glyphsOpen = !root.glyphsOpen
        }
        function open(): void {
            root.glyphScreen = root.focusedScreen()
            root.glyphsOpen = true
        }
        function close(): void { root.glyphsOpen = false }
    }
}
