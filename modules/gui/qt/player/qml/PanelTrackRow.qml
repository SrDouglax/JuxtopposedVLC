/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Templates as T
import VLC.Style

T.Button {
    id: root
    implicitHeight: VLCStyle.dp(44, VLCStyle.scale)
    background: Rectangle {
        radius: VLCStyle.dp(4, VLCStyle.scale)
        color: root.hovered ? VLCStyle.redesign.color("#191919", "#ababaa") : "transparent"
        border.color: root.visualFocus ? VLCStyle.redesign.accent : "transparent"
    }
    contentItem: Item {
        Image {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: VLCStyle.dp(24, VLCStyle.scale)
            height: VLCStyle.dp(24, VLCStyle.scale)
            source: "qrc:///redesign/track-check-active.png"
            visible: root.checked
        }
        Text {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 40
            }
            text: root.text
            color: VLCStyle.redesign.color("#8f8f8f", "#4d4d4d")
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            elide: Text.ElideRight
        }
    }
}
