import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

ShellRoot {
    id: root

    // Panel State
    property bool panelOpen: false
    property var panelScreen: null
    property string activeTab: "home"

    // Calendar State
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
                    // Open/Close Calendar
                    root.calScreen = scr
                    root.calOpen = !root.calOpen
                    root.panelOpen = false // Close main panel if calendar opens
                } else {
                    // Open/Close Main Panel
                    if (root.panelOpen && root.activeTab === name) {
                        root.panelOpen = false
                    } else {
                        root.activeTab = name
                        root.panelScreen = scr
                        root.panelOpen = true
                    }
                    root.calOpen = false // Close calendar if panel opens
                }
            }
        }
    }

    // Main Panel
    Panel {
        opened: root.panelOpen
        activeTab: root.activeTab
        onTabChanged: function(name) { root.activeTab = name }
        onCloseRequested: root.panelOpen = false
        screen: root.panelScreen !== null ? root.panelScreen : (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
    }

    // Calendar Popup
    CalendarPopup {
        opened: root.calOpen
        onCloseRequested: root.calOpen = false
        screen: root.calScreen !== null ? root.calScreen : (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
    }

    // Notifications
    Variants {
        model: Quickshell.screens
        NotifPopup {
            suppressed: root.panelOpen && screen === root.panelScreen
        }
    }
}
