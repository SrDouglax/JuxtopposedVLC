/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Controls.Basic as C
import VLC.Style

C.CheckBox {
    id: root
    implicitWidth: VLCStyle.dp(64, VLCStyle.scale)
    implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
    padding: 0
    indicator: Rectangle {
        width: root.width
        height: root.height
        radius: VLCStyle.dp(4, VLCStyle.scale)
        color: VLCStyle.redesign.color("#191919", "#ababaa")
        border.color: root.visualFocus ? VLCStyle.redesign.accent : VLCStyle.redesign.color("#222222", "#8e8e8d")
        Rectangle {
            x: root.checked ? parent.width / 2 : 2
            y: 2
            width: parent.width / 2 - 4
            height: parent.height - 4
            radius: VLCStyle.dp(3, VLCStyle.scale)
            color: root.checked ? VLCStyle.redesign.accent : "#373737"
        }
        Text {
            x: root.checked ? 0 : parent.width / 2
            width: parent.width / 2
            height: parent.height
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.checked ? qsTr("ON") : qsTr("OFF")
            color: root.checked ? "#eaeaea" : "#6b6b6b"
            font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
        }
    }
    contentItem: Item {
    }
}
