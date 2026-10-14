import QtQuick
import VLC.Style

Image {
    property bool paintOnly: false
    width: VLCStyle.dp(24, VLCStyle.scale)
    height: VLCStyle.dp(32, VLCStyle.scale)
    fillMode: Image.PreserveAspectFit
    source: "qrc:///redesign/icons/divider/default.png"
    Accessible.role: Accessible.Indicator
    Accessible.name: qsTr("Divider")
}
