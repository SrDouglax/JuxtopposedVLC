/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Templates as T
import VLC.Style

T.Control {
    id: root
    property bool paintOnly: false
    property url iconSource: ""
    property string value: ""
    property string placeholder: ""
    readonly property ColorContext colorContext: ColorContext {
        palette: VLCStyle.palette
        colorSet: ColorContext.ToolButton
    }
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
    leftPadding: VLCStyle.dp(6, VLCStyle.scale)
    rightPadding: VLCStyle.dp(6, VLCStyle.scale)
    Accessible.role: Accessible.Indicator
    Accessible.name: value.length ? value : placeholder
    contentItem: Row {
        spacing: VLCStyle.dp(6, VLCStyle.scale)
        Image {
            visible: root.iconSource.toString().length > 0
            source: root.iconSource
            width: visible ? VLCStyle.dp(18, VLCStyle.scale) : 0
            height: width
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.value.length ? root.value : root.placeholder
            width: Math.min(implicitWidth, VLCStyle.dp(160, VLCStyle.scale))
            elide: Text.ElideRight
            color: VLCStyle.redesign.color("#969696", root.colorContext.fg.primary)
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
