/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Templates as T
import VLC.Style

Rectangle {
    id: root
    required property Component panel
    property bool expanded: false
    property real contentMargin: VLCStyle.dp(16, VLCStyle.scale)
    implicitHeight: header.height + (expanded ? body.implicitHeight + contentMargin * 2 : 0)
    radius: VLCStyle.dp(6, VLCStyle.scale)
    color: VLCStyle.redesign.color(expanded ? "#1b1b1b" : "#090909", "#dedede")
    T.Button {
        id: header
        objectName: root.objectName + "Toggle"
        width: parent.width
        height: VLCStyle.dp(48, VLCStyle.scale)
        Accessible.name: root.expanded ? qsTr("Collapse settings") : qsTr("Expand settings")
        onClicked: root.expanded = !root.expanded
        background: Rectangle { color: parent.hovered ? VLCStyle.redesign.color("#252525", "#cccccc") : "transparent"; radius: root.radius }
        contentItem: Item {
            Text {
                anchors.left: parent.left
                anchors.leftMargin: VLCStyle.dp(16, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                text: root.expanded ? qsTr("Collapse Settings") : qsTr("Expand Settings")
                color: VLCStyle.redesign.color("#6b6b6b", "#494949")
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }
            Image {
                anchors.right: parent.right
                anchors.rightMargin: VLCStyle.dp(16, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                width: VLCStyle.dp(16, VLCStyle.scale)
                height: width
                sourceSize: Qt.size(width, height)
                source: "qrc:///redesign/icons/" + (root.expanded ? "chevron-down" : "chevron-right") + "/default.png"
            }
        }
    }
    Loader {
        id: body
        x: root.contentMargin
        y: header.height + root.contentMargin
        width: root.width - 2 * root.contentMargin
        visible: root.expanded
        sourceComponent: root.panel
    }
}
