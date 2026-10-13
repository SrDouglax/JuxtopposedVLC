/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
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

import VLC.Dialogs
import VLC.Util
import VLC.Widgets as Widgets

Widgets.ButtonExt {
    id: root
    objectName: "openMediaButton"

    text: qsTr("Open media")
    AccessibleCompat.id: "openMediaButton"

    onClicked: menu.popup([], mapToGlobal(0, height))

    NativeMenu {
        id: menu

        actions: [
            { text: qsTr("File…"), action: () => DialogsProvider.simpleOpenDialog() },
            { text: qsTr("Folder…"), action: () => DialogsProvider.PLOpenDir() },
            { text: qsTr("Network stream…"), action: () => DialogsProvider.openNetDialog() },
            { text: qsTr("Disc…"), action: () => DialogsProvider.openDiscDialog() },
            { text: qsTr("Capture device…"), action: () => DialogsProvider.openCaptureDialog() },
            { text: qsTr("Convert…"), action: () => DialogsProvider.openAndTranscodingDialogs() },
            { text: qsTr("Stream…"), action: () => DialogsProvider.openAndStreamingDialogs() }
        ]

        onRequestData: (requestID, _) => setData(requestID, [])
    }
}
