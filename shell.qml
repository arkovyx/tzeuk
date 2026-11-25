import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire

import "bar"
import "panel"
import "launcher"
import "glyphs"
import "wallpicker"
import "powermenu"
import "themes"
import "desktop"
import "timerandalarms"
import "shaderpicker"
import "cal"
import "shot"

ShellRoot {
    id: root

    property bool panelOpen: false
    property var panelScreen: null
    property string activeTab: "home"
    property bool calOpen: false
    property var calScreen: null
    property bool glyphsOpen: false
    property bool powerOpen: false
    property bool mediaOpen: false
    property bool clockOpen: false
    property bool shaderOpen: false

    PwObjectTracker { objects: Pipewire.nodes.values }

    function focusedScreen() {
        var screens = Quickshell.screens
        if (screens.length === 0) return null
        var focused = Hyprland.focusedMonitor
        if (focused && focused.name) {
            for (var i = 0; i < screens.length; i++) {
                if (screens[i].name === focused.name) return screens[i]
            }
        }
        return screens[0]
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
        screen: root.panelScreen !== null ? root.panelScreen : root.focusedScreen()
    }

    Cal {
        opened: root.calOpen
        onCloseRequested: root.calOpen = false
        screen: root.calScreen !== null ? root.calScreen : root.focusedScreen()
    }

    Variants {
        model: Quickshell.screens
        NotifPopup { suppressed: root.panelOpen && screen === root.panelScreen }
    }

    Launcher { id: launcher }

    CharPicker {
        opened: root.glyphsOpen
        screen: root.focusedScreen()
        onCloseRequested: root.glyphsOpen = false
    }

    ShaderPicker {
        opened: root.shaderOpen
        onCloseRequested: root.shaderOpen = false
    }

    WallPicker { id: wallPicker }

    Shot { id: shotTool }

    PowerMenu {
        opened: root.powerOpen
        onCloseRequested: root.powerOpen = false
    }

    MediaPopup {
        opened: root.mediaOpen
        onCloseRequested: root.mediaOpen = false
    }

    Variants {
        model: Quickshell.screens
        DesktopWidget { }
    }

    Variants {
        model: Quickshell.screens
        WallpaperDots { }
    }

    ClockPopup {
        opened: root.clockOpen
        onCloseRequested: root.clockOpen = false
    }

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
        function toggle(): void { root.glyphsOpen = !root.glyphsOpen }
        function open(): void   { root.glyphsOpen = true }
        function close(): void  { root.glyphsOpen = false }
    }

    IpcHandler {
        target: "power"
        function toggle(): void { root.powerOpen = !root.powerOpen }
        function open(): void   { root.powerOpen = true }
        function close(): void  { root.powerOpen = false }
    }

    IpcHandler {
        target: "media"
        function toggle(): void { root.mediaOpen = !root.mediaOpen }
        function open(): void   { root.mediaOpen = true }
        function close(): void  { root.mediaOpen = false }
    }

    IpcHandler {
        target: "clock"
        function toggle(): void { root.clockOpen = !root.clockOpen }
        function open(): void   { root.clockOpen = true }
        function close(): void  { root.clockOpen = false }
    }

    IpcHandler {
        target: "shader"
        function toggle(): void { root.shaderOpen = !root.shaderOpen }
        function open(): void   { root.shaderOpen = true }
        function close(): void  { root.shaderOpen = false }
        function set(name: string): void {
            var stateFile = Quickshell.env("HOME") + "/.cache/tzeuk/shader"
            var value = (name === "none" || name === "") ? "" : name
            Quickshell.execDetached(["bash", "-c", "printf '%s' \"" + value + "\" > '" + stateFile + "' && sleep 0.1 && hyprctl reload"])
        }
    }

    IpcHandler {
        target: "calendar"
        function toggle(): void {
            root.calScreen = root.focusedScreen()
            root.calOpen = !root.calOpen
            root.panelOpen = false
        }
        function close(): void { root.calOpen = false }
    }

    IpcHandler {
        target: "shot"
        function open(): void  { shotTool.open() }
        function close(): void { shotTool.close() }
    }
}
