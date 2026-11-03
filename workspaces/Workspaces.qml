import QtQuick
import Quickshell
import Quickshell.Hyprland

Row {
    id: root

    property var hmon: null
    property color colWhite: "#ffffff"
    property color colDim: "#333333"
    property color colRed: "#d71921"
    property color colBlack: "#000000"
    property string fontDot: "monospace"
    property int rowHeight: 28

    spacing: 8

    readonly property var activeWs: hmon ? hmon.activeWorkspace : null
    readonly property int offset: (activeWs && activeWs.id > 0) ? Math.floor((activeWs.id - 1) / 10) * 10 : 0
    readonly property var list: [1,2,3,4,5,6,7,8,9,10].map(function(i) { return offset + i })

    function find(id) {
        var l = Hyprland.workspaces.values
        for (var i = 0; i < l.length; i++) if (l[i].id === id) return l[i]
        return null
    }

    function switchTo(id) {
        Hyprland.dispatch('hl.dsp.focus({ workspace = "' + id + '" })')
    }

    function step(dir) {
        var cur = activeWs ? activeWs.id : (offset + 1)
        var next = cur + dir
        if (next < offset + 1) next = offset + 10
        if (next > offset + 10) next = offset + 1
        switchTo(next)
    }

    Repeater {
        model: root.list
        delegate: Item {
            id: wsItem
            required property var modelData
            readonly property var obj: root.find(modelData)
            readonly property bool active: root.activeWs !== null && root.activeWs.id === modelData
            readonly property bool occupied: obj !== null && obj.toplevels.values.length > 0

            width: root.rowHeight
            height: root.rowHeight

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: wsItem.active ? root.colWhite : "transparent"
                border.width: wsItem.active ? 0 : 1
                border.color: wsItem.occupied ? root.colRed : root.colDim
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
            }

            Text {
                anchors.centerIn: parent
                text: String(wsItem.modelData)
                color: wsItem.active ? root.colBlack : (wsItem.occupied ? root.colRed : root.colDim)
                font.family: root.fontDot
                font.pixelSize: 16
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.switchTo(wsItem.modelData)
                onWheel: function(w) { root.step(w.angleDelta.y > 0 ? -1 : 1) }
            }
        }
    }
}
