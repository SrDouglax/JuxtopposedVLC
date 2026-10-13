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
import VLC.Style
import VLC.Util
import VLC.Widgets as Widgets

RowLayout {
    required property var listView
    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
        palette: VLCStyle.palette
    }
    visible: listView.count !== 0

    Layout.fillHeight: false
    Layout.leftMargin: VLCStyle.margin_normal
    Layout.rightMargin: Math.max(listView.T.ScrollBar.vertical.width, VLCStyle.margin_normal)

    spacing: VLCStyle.margin_large

    Widgets.IconLabel {
        // play queue cover column
        Layout.preferredWidth: VLCStyle.icon_playlistArt

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: VLCIcons.album_cover
        font.pixelSize: VLCStyle.icon_playlistHeader

        color: theme.fg.secondary

        Accessible.role: Accessible.ColumnHeader
        Accessible.name: qsTr("Cover")
        Accessible.ignored: false
    }

    //Use Text here as we're redefining its Accessible.role
    Text {
        Layout.fillWidth: true

        elide: Text.ElideRight
        font.pixelSize: VLCStyle.fontSize_normal
        textFormat: Text.PlainText

        verticalAlignment: Text.AlignVCenter
        text: qsTr("Title")
        color: theme.fg.secondary

        Accessible.role: Accessible.ColumnHeader
        Accessible.name: text
    }

    Widgets.IconLabel {
        Layout.preferredWidth: durationMetric.width

        text: VLCIcons.time
        color: theme.fg.secondary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: VLCStyle.icon_playlistHeader

        Accessible.role: Accessible.ColumnHeader
        Accessible.name: qsTr("Duration")
        Accessible.ignored: false

        TextMetrics {
            id: durationMetric

            font.weight: Font.DemiBold
            font.pixelSize: VLCStyle.fontSize_normal
            text: "00:00"
        }
    }
}
