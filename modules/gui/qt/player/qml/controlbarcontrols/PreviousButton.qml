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


import VLC.Widgets as Widgets
import VLC.Style
import VLC.Playlist
import VLC.Util

Widgets.IconToolButton {
    id: prevBtn

    text: VLCIcons.previous
    enabled: MainPlaylistController.hasPrev
    onClicked: MainPlaylistController.prev()
    description: qsTr("Previous")

    contentItem: Item {
        implicitWidth: VLCStyle.redesign.iconSize
        implicitHeight: VLCStyle.redesign.iconSize

        Image {
            anchors.centerIn: parent
            source: "qrc:/redesign/previous.svg"
            width: VLCStyle.redesign.iconSize
            height: VLCStyle.redesign.iconSize
            fillMode: Image.PreserveAspectFit
            opacity: enabled ? 1 : 0.4
        }
    }

    AccessibleCompat.id: "previousButton"
}
