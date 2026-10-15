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
import QtQuick.Layouts
import VLC.Style

import VLC.Dialogs
import VLC.Util
import VLC.Widgets as Widgets

Widgets.ButtonExt {
    id: root
    property bool iconOnly: false
    colorContext.palette: VLCStyle.palette
    padding: iconOnly ? 0 : VLCStyle.dp(8, VLCStyle.scale)
    contentItem: RowLayout {
        spacing: 0
        Image {
            visible: root.iconOnly
            Layout.preferredWidth: VLCStyle.redesign.iconSize
            Layout.preferredHeight: VLCStyle.redesign.iconSize
            source: "qrc:///redesign/menu.svg"
            sourceSize: Qt.size(24, 24)
        }
        Widgets.LabelExt {
            visible: !root.iconOnly
            text: root.text
            color: VLCStyle.redesign.textMuted
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }
    }
    objectName: "openMediaButton"

    text: qsTr("Open media")
    AccessibleCompat.id: "openMediaButton"

    onClicked: menu.popup([], mapToGlobal(0, height))

    NativeMenu {
        id: menu

        actions: [
            { text: qsTr("File…"), icon: "file", action: () => DialogsProvider.simpleOpenDialog() },
            { text: qsTr("Folder…"), icon: "folder", action: () => DialogsProvider.PLOpenDir() },
            { text: qsTr("Network stream…"), icon: "streaming", action: () => DialogsProvider.openNetDialog() },
            { text: qsTr("Disc…"), icon: "disc", action: () => DialogsProvider.openDiscDialog() },
            { text: qsTr("Capture device…"), icon: "capture-device", action: () => DialogsProvider.openCaptureDialog() },
            { text: qsTr("Convert…"), icon: "swap", action: () => DialogsProvider.openAndTranscodingDialogs() },
            { text: qsTr("Stream…"), icon: "streaming", action: () => DialogsProvider.openAndStreamingDialogs() }
        ]

        onRequestData: (requestID, _) => setData(requestID, [])
    }
}
