/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *****************************************************************************/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls
import QtQuick.Dialogs

import VLC.MediaLibrary
import VLC.Widgets as Widgets
import VLC.Style

Controls.Popup {
    id: root
    objectName: "playlistCreateDialog"

    required property MLPlaylistListModel playlistModel
    property var files: []

    width: Math.min(parent ? parent.width - VLCStyle.margin_large * 2 : 440,
                    VLCStyle.dp(440, VLCStyle.scale))
    padding: VLCStyle.margin_large
    modal: true
    focus: true
    closePolicy: Controls.Popup.CloseOnEscape
    anchors.centerIn: parent

    onOpened: titleField.forceActiveFocus()
    onClosed: {
        titleField.clear()
        files = []
    }

    background: Rectangle {
        color: VLCStyle.redesign.color(VLCStyle.redesign.sidebarBackground,
                                       VLCStyle.palette.base)
        border.color: VLCStyle.redesign.color(VLCStyle.redesign.border,
                                              VLCStyle.palette.mid)
        radius: VLCStyle.redesign.controlRadius
    }

    contentItem: ColumnLayout {
        spacing: VLCStyle.margin_normal

        Text {
            text: qsTr("New playlist")
            color: VLCStyle.redesign.color(VLCStyle.redesign.textPrimary,
                                           VLCStyle.palette.text)
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.fontSize_xlarge
            font.weight: Font.DemiBold
        }

        Widgets.TextFieldExt {
            id: titleField
            objectName: "playlistTitleField"
            Layout.fillWidth: true
            placeholderText: qsTr("Playlist title")
            Accessible.name: qsTr("Playlist title")
            onAccepted: if (createButton.enabled) root.createPlaylist()
        }

        Widgets.ButtonExt {
            objectName: "playlistChooseFilesButton"
            text: qsTr("Choose files")
            onClicked: fileDialog.open()
        }

        Text {
            Layout.fillWidth: true
            text: root.files.length === 0
                  ? qsTr("Choose at least one file")
                  : qsTr("%1 file selected", "%1 files selected", root.files.length).arg(root.files.length)
            color: VLCStyle.redesign.color(VLCStyle.redesign.textSecondary,
                                           VLCStyle.palette.text)
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.fontSize_normal
        }

        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }

            Widgets.ButtonExt {
                text: qsTr("Cancel")
                onClicked: root.close()
            }

            Widgets.ButtonExt {
                id: createButton
                objectName: "playlistCreateButton"
                text: qsTr("Create playlist")
                enabled: titleField.text.trim().length > 0 && root.files.length > 0
                         && !root.playlistModel.transactionPending
                onClicked: root.createPlaylist()
            }
        }
    }

    FileDialog {
        id: fileDialog
        objectName: "playlistFilesDialog"
        title: qsTr("Add files to playlist")
        fileMode: FileDialog.OpenFiles
        onAccepted: root.files = selectedFiles
    }

    function createPlaylist() {
        if (!createButton.enabled)
            return
        playlistModel.create(titleField.text.trim(), files)
        close()
    }
}
