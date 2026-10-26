import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

ShellRoot {
    id: root
    property bool panelOpen: false
    property var panelScreen: null
    property string activeTab: "home"

    // Bind every Pipewire node so volume / mute are reactively tracked
    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    Variants {
        model: Quickshell.screens
        Bar {
            onTogglePanel: function(name, scr) {
                // If the panel is open on the same tab, close it
                if (root.panelOpen && root.activeTab === name) {
                    root.panelOpen = false
                } else {
                    root.activeTab = name
                    root.panelScreen = scr
                    root.panelOpen = true
                }
            }
        }
    }

    Panel {
        opened: root.panelOpen
        activeTab: root.activeTab

        onTabChanged: function(name) {
            root.activeTab = name
        }
        onCloseRequested: {
            root.panelOpen = false
        }

        screen: root.panelScreen !== null
            ? root.panelScreen
            : (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
    }
}
