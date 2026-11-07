import QtQuick

Text {
    property int px: 12
    font.family: "Space Mono"
    font.pixelSize: px
    font.capitalization: Font.AllUppercase
    font.letterSpacing: 0.8
    color: "#b0b0b0"
    elide: Text.ElideRight
}
