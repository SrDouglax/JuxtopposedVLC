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
import QtQuick.Templates as T


import VLC.Widgets as Widgets
import VLC.Style
import VLC.Player
import VLC.Util

PlayerPanelButton {
    iconSource: "qrc:///redesign/subtitles.svg"
    id: root

    // Proprerties

    readonly property var _seriesPreset: {
        let item = root.parent
        while (item) {
            if ("subtitleSeriesPreset" in item) return item.subtitleSeriesPreset
            item = item.parent
        }
        return null
    }

    // Signals

    signal requestLockUnlockAutoHide(bool lock)
    signal menuOpened(var menu)

    // Settings

    text: VLCIcons.audiosub

    enabled: menuLoader.status === Loader.Ready
    checked: menuLoader.item ? menuLoader.item.visible : false

    description: qsTr("Languages and tracks")

    AccessibleCompat.id: "langButton"

    // Events

    onClicked: {
        const menu = menuLoader.item
        if (menu.opened) {
            menu.close()
            return
        }
        root.positionPopup(menu)
        menu.open()
    }

    // Children

    Loader {
        id: menuLoader

        sourceComponent: TracksMenu {
            id: menu

            parent: root
            closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutsideParent
            seriesPreset: root._seriesPreset

            z: 1

            focus: true

            onOpened: {
                root.requestLockUnlockAutoHide(true)
                root.menuOpened(menu)
            }

            onClosed: {
                root.requestLockUnlockAutoHide(false)
                root.forceActiveFocus()
                root.menuOpened(null)
            }
        }
    }

    function forceUnlock() {
        if((menuLoader)&&(menuLoader.item))
            menuLoader.item.close()
    }
}
