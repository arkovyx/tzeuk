import QtQuick
import Quickshell

ShellRoot {
    property bool panelOpen: false;

    Bar {
        onTogglePanel: panelOpen = !panelOpen
    }

    Panel {
        opened: panleOpen
    }
}
