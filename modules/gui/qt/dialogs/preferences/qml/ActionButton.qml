/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import VLC.Style

Button {
    id: control
    property bool primary: false
    readonly property bool dark: VLCStyle.palette.isDark

    implicitWidth: Math.max(VLCStyle.dp(88, VLCStyle.scale),
                            label.implicitWidth + VLCStyle.dp(28, VLCStyle.scale))
    implicitHeight: VLCStyle.dp(34, VLCStyle.scale)
    font.family: VLCStyle.redesign.fontFamily
    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)

    background: Rectangle {
        radius: 4
        color: !control.enabled ? (control.dark ? "#1c1c1c" : "#eeeeee")
               : control.primary ? (control.down ? Qt.lighter(VLCStyle.redesign.accentBackground, 1.2) : VLCStyle.redesign.accentBackground)
               : control.down ? (control.dark ? "#303030" : "#dddddd")
               : control.hovered ? (control.dark ? "#292929" : "#e8e8e8")
               : (control.dark ? "#202020" : "#f4f4f4")
        border.color: control.visualFocus ? VLCStyle.redesign.accent
                      : control.primary ? "transparent"
                      : (control.dark ? "#353535" : "#cccccc")
    }
    contentItem: Label {
        id: label
        text: control.text
        color: !control.enabled ? (control.dark ? "#666666" : "#999999")
               : control.primary ? VLCStyle.redesign.accent
               : (control.dark ? "#d0d0d0" : "#303030")
        font: control.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
