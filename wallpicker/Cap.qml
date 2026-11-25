import QtQuick

import "../themes"

// label: Space Mono, caps, tracked, dim
Text {
    textFormat: Text.PlainText
    property real px: 12
    readonly property string fMono: Theme.fontMono !== "" ? Theme.fontMono : "monospace"
    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.5)
    font { family: fMono; pixelSize: px; letterSpacing: px * 0.14; capitalization: Font.AllUppercase }
}
