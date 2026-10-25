import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

ShellRoot {
    id: root
    property bool panelOpen: false
    property var panelScreen: null

    // Bind every Pipewire node so volume / mute are reactively tracked
    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    Variants {
        model: Quickshell.screens
        Bar {
            onTogglePanel: function(name, scr) {
                root.panelScreen = scr
                root.panelOpen = !root.panelOpen
            }
        }
    }

    Panel {
        opened: root.panelOpen
        screen: root.panelScreen !== null
            ? root.panelScreen
            : (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
    }
}
