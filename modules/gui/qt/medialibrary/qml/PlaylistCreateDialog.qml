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

import VLC.MainInterface
import VLC.MediaLibrary
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Util

Controls.Popup {
    id: root
    objectName: "playlistCreateDialog"

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
        palette: VLCStyle.palette
    }

    required property MLPlaylistListModel playlistModel
    property var files: []
    property bool previousGlobalShortcuts: true

    width: Math.min(parent ? parent.width - VLCStyle.margin_large * 2 : 440,
                    VLCStyle.dp(440, VLCStyle.scale))
    padding: VLCStyle.margin_large
    modal: true
    focus: true
    closePolicy: Controls.Popup.CloseOnEscape
    anchors.centerIn: parent

    onOpened: {
        previousGlobalShortcuts = MainCtx.useGlobalShortcuts
        MainCtx.useGlobalShortcuts = false
        titleField.forceActiveFocus()
    }
    onClosed: {
        MainCtx.useGlobalShortcuts = previousGlobalShortcuts
        titleField.clear()
        files = []
    }

    background: Rectangle {
        color: VLCStyle.redesign.color(VLCStyle.redesign.sidebarBackground,
                                       theme.bg.primary)
        border.color: VLCStyle.redesign.color(VLCStyle.redesign.border,
                                              theme.border)
        radius: VLCStyle.redesign.controlRadius
    }

    contentItem: ColumnLayout {
        spacing: VLCStyle.margin_normal

        Text {
            text: qsTr("New playlist")
            color: VLCStyle.redesign.color(VLCStyle.redesign.textPrimary,
                                           theme.fg.primary)
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.fontSize_xlarge
            font.weight: Font.DemiBold
        }

        Widgets.TextFieldExt {
            colorContext.palette: theme.palette
            id: titleField
            objectName: "playlistTitleField"
            Layout.fillWidth: true
            placeholderText: qsTr("Playlist title")
            Accessible.name: qsTr("Playlist title")
            onAccepted: if (createButton.enabled) root.createPlaylist()
        }

        Widgets.ButtonExt {
            colorContext.palette: theme.palette
            objectName: "playlistChooseFilesButton"
            text: qsTr("Choose files")
            onClicked: {
                const selected = filePicker.chooseFiles(qsTr("Add files to playlist"))
                if (selected.length > 0) root.files = selected
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.files.length === 0
                  ? qsTr("Choose at least one file")
                  : qsTr("%1 file selected", "%1 files selected", root.files.length).arg(root.files.length)
            color: VLCStyle.redesign.color(VLCStyle.redesign.textSecondary,
                                           theme.fg.primary)
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.fontSize_normal
        }

        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }

            Widgets.ButtonExt {
                colorContext.palette: theme.palette
                text: qsTr("Cancel")
                onClicked: root.close()
            }

            Widgets.ButtonExt {
                colorContext.palette: theme.palette
                id: createButton
                objectName: "playlistCreateButton"
                text: qsTr("Create playlist")
                enabled: titleField.text.trim().length > 0 && root.files.length > 0
                         && !root.playlistModel.transactionPending
                onClicked: root.createPlaylist()
            }
        }
    }

    Widgets.FilePicker { id: filePicker; ctx: MainCtx }

    function createPlaylist() {
        if (!createButton.enabled)
            return
        playlistModel.create(titleField.text.trim(), files)
        close()
    }
}
