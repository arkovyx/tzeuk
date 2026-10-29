import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

ShellRoot {
    id: root
    property bool panelOpen: false
    property var panelScreen: null
    property string activeTab: "home"

    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    Variants {
        model: Quickshell.screens
        Bar {
            onTogglePanel: function(name, scr) {
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

    Variants {
        model: Quickshell.screens
        NotifPopup {
            // Suppress popups on the focused screen while the panel is open
            // to prevent them from stacking over the panel
            suppressed: root.panelOpen && screen === root.panelScreen
        }
    }
}
