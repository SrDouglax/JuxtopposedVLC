/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as C
import QtQuick.Controls.impl as Impl
import VLC.Style

C.Button {
    id: root
    property string arrow: ""
    implicitHeight: VLCStyle.dp(42, VLCStyle.scale)
    background: Rectangle {
        radius: VLCStyle.dp(4, VLCStyle.scale)
        color: root.hovered ? VLCStyle.redesign.color("#191919", "#ababaa") : VLCStyle.redesign.color("#090909", "#bcbcbc")
        border.color: root.visualFocus ? VLCStyle.redesign.accent : "transparent"
    }
    contentItem: RowLayout {
        Text {
            Layout.fillWidth: true
            text: root.text
            leftPadding: VLCStyle.dp(12, VLCStyle.scale)
            color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            verticalAlignment: Text.AlignVCenter
        }
        Impl.IconImage {
            visible: root.arrow.length > 0
            rotation: root.arrow === "chevron-up" ? 180 : 0
            source: root.arrow ? "qrc:///redesign/icons/" + (root.arrow === "chevron-up" ? "chevron-down" : root.arrow) + "/default.png" : ""
            Layout.preferredWidth: VLCStyle.dp(24, VLCStyle.scale)
            Layout.preferredHeight: VLCStyle.dp(24, VLCStyle.scale)
            color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
            Layout.rightMargin: VLCStyle.dp(12, VLCStyle.scale)
        }
    }
}
