/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
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
import QtQuick.Templates as T
import QtQuick.Layouts
import QtQuick.Window


import VLC.MainInterface
import VLC.Style
import VLC.PlayerControls
import VLC.Playlist
import VLC.Widgets as Widgets
import VLC.Menus as Menus
import VLC.Util

T.Label {
    id: control

    property bool centerWithinBounds: false
    property real leftLimit: 0
    property real rightLimit: parent ? parent.width : 0

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    width: centerWithinBounds ? Math.max(0, Math.min(rightLimit - leftLimit, implicitWidth)) : implicitWidth
    x: centerWithinBounds ? Math.max(leftLimit, ((parent ? parent.width : 0) - width) / 2) : 0

    leftPadding: VLCStyle.margin_small
    rightPadding: VLCStyle.margin_small
    color: VLCStyle.redesign.color(VLCStyle.redesign.textMuted, theme.fg.primary, (theme.palette?.isDark ?? VLCStyle.darkPalette.isDark))
    font.family: VLCStyle.redesign.fontFamily
    font.pixelSize: VLCStyle.redesign.fontNormal
    font.weight: Font.Normal
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: centerWithinBounds ? Text.AlignHCenter : Text.AlignLeft
}
