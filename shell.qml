import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "bar"
import "panel"
import "launcher"

ShellRoot {
    id: root

    property bool panelOpen: false
    property var panelScreen: null
    property string activeTab: "home"
    property bool calOpen: false
    property var calScreen: null

    PwObjectTracker {
        objects: Pipewire.nodes.values
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
}
