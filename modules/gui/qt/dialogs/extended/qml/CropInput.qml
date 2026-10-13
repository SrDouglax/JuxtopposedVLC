/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 or later.
 *****************************************************************************/
import QtQuick
import QtQuick.Layouts
import VLC.Style

Rectangle {
    id: root
    required property var effects
    required property string side
    property string label
    signal edited(int pixels)
    implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
    radius: VLCStyle.dp(5, VLCStyle.scale)
    color: "#0E0E0E"
    objectName: "crop-" + side

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: VLCStyle.dp(10, VLCStyle.scale)
        anchors.rightMargin: VLCStyle.dp(8, VLCStyle.scale)
        spacing: VLCStyle.dp(8, VLCStyle.scale)
        Text {
            Layout.fillWidth: true
            text: root.label
            color: VLCStyle.redesign.textMuted
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
        }
        TextInput {
            id: pixelsInput
            Layout.preferredWidth: VLCStyle.dp(58, VLCStyle.scale)
            horizontalAlignment: TextInput.AlignRight
            color: VLCStyle.redesign.textSecondary
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
            validator: IntValidator { bottom: 0; top: 2147483647 }
            selectByMouse: true
            text: root.effects.cropValue(root.side).toString()
            Accessible.name: qsTr("%1 crop in pixels").arg(root.label)
            onEditingFinished: {
                const parsed = Number(text)
                if (Number.isSafeInteger(parsed) && parsed >= 0) root.edited(parsed)
                text = root.effects.cropValue(root.side).toString()
            }
            Connections {
                target: root.effects
                function onStateChanged() {
                    if (!pixelsInput.activeFocus)
                        pixelsInput.text = root.effects.cropValue(root.side).toString()
                }
            }
        }
        Text {
            text: qsTr("px")
            color: VLCStyle.redesign.textMuted
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
        }
    }
}
