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


import VLC.MainInterface
import VLC.Player
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Util


PlayerPanelButton {
    iconSource: "qrc:///redesign/queue.svg"
    id: playlistBtn

    property int initialTab: 0
    text: VLCIcons.playlist
    signal requestLockUnlockAutoHide(bool lock)
    onClicked: {
        if (menu.visible) menu.close()
        else { menu.currentTab = initialTab; playlistBtn.positionPopup(menu); menu.open() }
    }
    checked: menu.visible

    NavigationMenu {
        id: menu
        parent: playlistBtn
        closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutsideParent
        onOpened: playlistBtn.requestLockUnlockAutoHide(true)
        onClosed: { playlistBtn.requestLockUnlockAutoHide(false); playlistBtn.forceActiveFocus() }
    }

    function forceUnlock() { if (menu) menu.close() }

    description: qsTr("Play Queue")

    AccessibleCompat.id: "playqueueButton"
}
