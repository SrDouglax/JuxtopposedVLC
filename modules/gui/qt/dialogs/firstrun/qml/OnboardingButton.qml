import QtQuick
import QtQuick.Controls.Basic as Controls

import VLC.Style

Controls.Button {
    id: control
    property bool primary: false
    implicitWidth: 100
    implicitHeight: 32
    font.family: VLCStyle.redesign.fontFamily
    font.pixelSize: 16
    font.weight: primary ? Font.DemiBold : Font.Normal
    background: Rectangle {
        radius: 6
        color: !control.enabled ? "#292929"
             : control.primary ? VLCStyle.redesign.accent
             : control.down || control.hovered ? "#303030" : "#1b1b1b"
    }
    contentItem: Text {
        text: control.text
        color: !control.enabled ? "#666666" : control.primary ? "#161616" : "#969696"
        font: control.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
