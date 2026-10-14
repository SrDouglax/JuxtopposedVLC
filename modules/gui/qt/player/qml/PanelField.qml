/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import VLC.Style

RowLayout {
    id: root
    property string label
    property real controlWidth: VLCStyle.dp(218, VLCStyle.scale)
    property real controlHeight: VLCStyle.dp(44, VLCStyle.scale)
    default property alias controls: host.data
    spacing: VLCStyle.dp(12, VLCStyle.scale)
    implicitHeight: controlHeight
    children: [
        Text {
            Layout.fillWidth: true
            text: root.label
            color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            wrapMode: Text.WordWrap
        },
        Item {
            id: host
            Layout.preferredWidth: root.controlWidth
            Layout.minimumWidth: root.controlWidth
            Layout.maximumWidth: root.controlWidth
            Layout.preferredHeight: root.controlHeight
        }
    ]
}
