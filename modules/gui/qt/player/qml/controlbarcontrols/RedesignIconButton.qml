/*****************************************************************************
 * Copyright (C) 2021 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
import QtQuick
import QtQuick.Controls.impl as Impl
import VLC.Widgets as Widgets
import VLC.Style

Widgets.IconToolButton {
    id: root
    required property url iconSource

    font.pixelSize: VLCStyle.redesign.iconSize
    implicitWidth: VLCStyle.dp(30, VLCStyle.scale)
    implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
    color: VLCStyle.redesign.color(checked ? VLCStyle.redesign.accent : VLCStyle.redesign.textMuted,
                                   colorContext.fg.primary, colorContext.palette?.isDark ?? true)
    backgroundColor: VLCStyle.redesign.color(hovered || down ? VLCStyle.redesign.controlHoverBackground : "transparent",
                                             colorContext.bg.primary, colorContext.palette?.isDark ?? true)
    radius: VLCStyle.dp(4, VLCStyle.scale)
    contentItem: Item {
        implicitWidth: VLCStyle.redesign.iconSize
        implicitHeight: VLCStyle.redesign.iconSize
        Impl.IconImage {
            anchors.centerIn: parent
            width: VLCStyle.redesign.iconSize
            height: width
            source: root.iconSource
            color: root.color
            opacity: root.enabled ? 1 : 0.4
        }
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: VLCStyle.dp(12, VLCStyle.scale)
            height: VLCStyle.dp(2, VLCStyle.scale)
            color: VLCStyle.redesign.accent
            visible: root.checked
        }
    }
}
