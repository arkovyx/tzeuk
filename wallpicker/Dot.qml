import QtQuick

import "../themes"

// numbers and short words: Doto, round dots
Text {
    textFormat: Text.PlainText
    readonly property string fDot: Theme.fontDoto !== "" ? Theme.fontDoto : "monospace"
    color: Theme.fg
    font { family: fDot; pixelSize: 44; weight: Font.Black; variableAxes: ({ "ROND": 100, "wght": 900 }) }
}
