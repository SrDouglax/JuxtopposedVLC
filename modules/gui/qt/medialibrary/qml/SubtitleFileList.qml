/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls
import VLC.Style

ListView {
    id: root
    required property var associations
    objectName: "subtitleFileList"
    model: associations.sources
    clip: true
    spacing: VLCStyle.dp(4, VLCStyle.scale)
    delegate: Controls.ItemDelegate {
        required property int index
        required property var modelData
        objectName: "subtitleSource_" + index
        width: ListView.view.width
        height: VLCStyle.dp(36, VLCStyle.scale)
        enabled: !root.associations.busy
        highlighted: modelData.selected
        onClicked: root.associations.setSourceSelected(index, !modelData.selected)
        Accessible.role: Accessible.CheckBox
        Accessible.checkable: true
        Accessible.checked: modelData.selected
        background: Rectangle {
            color: parent.highlighted ? VLCStyle.redesign.color("#090909", "#ababaa")
                                     : parent.hovered ? VLCStyle.redesign.color("#191919", "#dedede") : "transparent"
            radius: VLCStyle.dp(4, VLCStyle.scale)
        }
        contentItem: RowLayout {
            spacing: VLCStyle.dp(16, VLCStyle.scale)
            Image {
                Layout.preferredWidth: VLCStyle.dp(24, VLCStyle.scale)
                Layout.preferredHeight: width
                source: "qrc:///redesign/subtitle-file.png"
            }
            Controls.Label {
                Layout.fillWidth: true
                text: modelData.label
                elide: Text.ElideMiddle
                color: VLCStyle.redesign.color("#969696", "#4d4d4d")
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }
            Controls.Label {
                text: modelData.selected ? "✓" : ""
                color: VLCStyle.redesign.accent
                font.pixelSize: VLCStyle.dp(20, VLCStyle.scale)
                Layout.preferredWidth: VLCStyle.dp(24, VLCStyle.scale)
            }
        }
    }
}
