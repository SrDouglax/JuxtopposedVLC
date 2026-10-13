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
import QtQuick.Layouts
import VLC.MainInterface
import VLC.Playlist
import VLC.Style
import VLC.Util
import VLC.Widgets as Widgets

Column {
    id: root

    required property var listView
    required property var contextMenu
    required property Item navigationParent
    property alias searchBox: searchBox
    property alias sortButton: sort
    readonly property real titleWidth: titleRowLayout.implicitWidth

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    Layout.fillHeight: false
    Layout.fillWidth: true
    Layout.leftMargin: VLCStyle.margin_normal
    Layout.rightMargin: VLCStyle.margin_normal

    spacing: VLCStyle.margin_xxxsmall

    RowLayout {
        id: titleRowLayout

        anchors.left: parent.left
        anchors.right: parent.right

        spacing: VLCStyle.margin_normal

        Widgets.SubtitleLabel {
            id: titleLabel

            Layout.fillWidth: true

            text: qsTr("Queue")
            color: theme.fg.primary
            font.weight: Font.Medium
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
        }

        Widgets.SortControl {
            id: sort

            font.pixelSize: VLCStyle.icon_banner

            description : qsTr("Sort")

            AccessibleCompat.id: "playqueueSort"

            enabled: MainPlaylistController.count > 1

            checked: MainPlaylistController.sortKey !== PlaylistController.SORT_KEY_NONE

            popupAbove: false

            model: MainPlaylistController.sortKeyTitleList

            onSortSelected: key => {
                MainPlaylistController.sortKey = key
                MainPlaylistController.sort()
            }

            onSortOrderSelected: type => {
                if (type === Qt.AscendingOrder)
                    MainPlaylistController.sortOrder = PlaylistController.SORT_ORDER_ASC
                else if (type === Qt.DescendingOrder)
                    MainPlaylistController.sortOrder = PlaylistController.SORT_ORDER_DESC

                MainPlaylistController.sort()
            }

            sortOrder: {
                if (MainPlaylistController.sortOrder === PlaylistController.SORT_ORDER_ASC) {
                    Qt.AscendingOrder
                }
                else if (MainPlaylistController.sortOrder === PlaylistController.SORT_ORDER_DESC) {
                    Qt.DescendingOrder
                }
            }

            sortKey: MainPlaylistController.sortKey

            Navigation.parentItem: root.navigationParent
            Navigation.rightItem: searchBox
            Navigation.downItem: listView
        }

        Widgets.SearchBox {
            id: searchBox

            enabled: MainPlaylistController.count > 1

            toggleButton.font.pixelSize: VLCStyle.icon_banner

            popBelow: true

            displayRegexToggleButton: true
            displayCaseSensitiveToggleButton: true

            popup.width: Math.min(root.width, Math.max(popup.implicitWidth, root.width * 0.6))
            popup.topPadding: VLCStyle.margin_xxsmall

            Navigation.parentItem: root.navigationParent
            Navigation.leftItem: sort
            Navigation.downItem: listView

            Connections {
                target: contextMenu

                function onDiscardedFilteredOutItems() {
                    searchBox.retract()
                }
            }
        }
    }

    Widgets.CaptionLabel {
        color: theme.fg.secondary
        visible: listView.count !== 0
        text: {
            if (listView.count <= 0)
                return "" // Not visible otherwise

            let duration
            const model = listView.model
            if (model instanceof PlaylistListModel) {
                duration = model.duration
            } else {
                // Proxy model, we need to use `QAbstractItemModel` api:

                duration = []
                for (let i = 0; i < listView.count; ++i) {
                    const itemDuration = model.data(model.index(i, 0), PlaylistListModel.DurationRole)
                    console.assert(itemDuration !== undefined && itemDuration !== null) // typeof `vlcDuration`
                    duration.push(itemDuration)
                }
                duration = duration[0].sum(duration)
            }

            return qsTr("%1 elements, %2").arg(listView.count).arg(duration.formatLong())
        }
    }
}
