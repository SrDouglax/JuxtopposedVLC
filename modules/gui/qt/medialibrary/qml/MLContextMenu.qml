
/*****************************************************************************
 * Copyright (C) 2022 VLC authors and VideoLAN
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
import QtQml

import VLC.MainInterface
import VLC.MediaLibrary
import VLC.Dialogs

import VLC.Util

// @brief - a generic ML context menu
NativeMenu {
    id: root

    // Properties

    required property MLBaseModel model

    property string idDataRole: "id"
    property string albumIdDataRole: "album_id"

    property bool showPlayAsAudioAction: false
    property bool showLegacyActions: false

    property var subtitleDialog: null
    property Component subtitleDialogComponent: Component { SubtitleAssociationsDialog {} }
    Component.onDestruction: if (subtitleDialog) subtitleDialog.destroy()

    // This is only applicable when the model is `MLAudioModel`:
    property bool showPlayAsAlbumAction: implicitShowPlayAsAlbumAction
    property bool implicitShowPlayAsAlbumAction: !showPlayAsAudioAction

    // Signals

    signal showMediaInformation(int index)


    // required by TableViewExt
    property var tableView_popup: function (index/* reserved for future */, selectedIndexes, globalPos) {
        return popup(selectedIndexes, globalPos)
    }

    // Settings

    actions: [
        { text: qsTr("Play"), icon: "play", action: addAndPlay },
        { text: qsTr("Mark as Watched"), icon: "check", action: markSeen, visible: _showSeen },
        { text: qsTr("Mark as Unwatched"), icon: "check", action: markUnseen, visible: _showUnseen },
        { text: qsTr("Favorite"), icon: "favorite", action: addFavorite, visible: _showAddFavorite },
        { text: qsTr("Remove from favorites"), icon: "favorite", action: removeFavorite, visible: _showRemoveFavorite },
        { text: qsTr("Stream"), icon: "streaming", action: function(data) { DialogsProvider.streamingDialog(data.map(item => item.mrl), true) }, visible: hasMediaUrls },
        { text: qsTr("Convert"), icon: "swap", action: function(data) { DialogsProvider.streamingDialog(data.map(item => item.mrl), false) }, visible: hasMediaUrls },
        { text: qsTr("Add to Queue"), icon: "queue", action: enqueue },
        { text: qsTr("Add to Playlist"), icon: "playlist", action: addToAPlaylist },
        { text: qsTr("Show in File Explorer"), icon: "folder", action: openContainingFolder, visible: _openContainingFolder },
        { text: qsTr("Go to Source"), icon: "next", action: function(data) { Qt.openUrlExternally(data[0].mrl) }, visible: function(data) { return data.length === 1 && data[0].mrl && !String(data[0].mrl).startsWith("file:") } },
        { text: qsTr("Add Subtitle Tracks"), icon: "subtitles", action: function(data) {
            if (!root.subtitleDialog) root.subtitleDialog = root.subtitleDialogComponent.createObject(g_mainDisplay)
            root.subtitleDialog.audioTracks = false
            root.subtitleDialog.openFor(data[0][root.idDataRole])
          }, visible: function(data) { return root.showPlayAsAudioAction && data.length === 1 } },
        { text: qsTr("Add Audio Tracks"), icon: "audio", action: function(data) {
            if (!root.subtitleDialog) root.subtitleDialog = root.subtitleDialogComponent.createObject(g_mainDisplay)
            root.subtitleDialog.audioTracks = true
            root.subtitleDialog.openFor(data[0][root.idDataRole])
          }, visible: function(data) { return root.showPlayAsAudioAction && data.length === 1 } },
        { text: qsTr("Properties & Metadata"), icon: "info", action: function(data) { DialogsProvider.mediaInfoDialog(data[0][idDataRole]) }, visible: function(data) { return data.length === 1 && !data[0][idDataRole].hasParent() } },
        { text: qsTr("Play as audio"), icon: "audio", action: playAsAudio, visible: root.showLegacyActions && root.showPlayAsAudioAction },
        { text: qsTr("Play as album"), icon: "audio", action: playAsAlbum, visible: root.showLegacyActions && root.showPlayAsAlbumAction && root.model instanceof MLAudioModel },
        { text: qsTr("Enqueue as album"), icon: "queue", action: enqueueAsAlbum, visible: root.showLegacyActions && root.showPlayAsAlbumAction && root.model instanceof MLAudioModel },
        { text: qsTr("Information"), icon: "info", action: _signalShowInformation, visible: showInformationAvailable },
        { text: qsTr("Delete"), icon: "remove", action: deleteStream, visible: _deleteStream },
        { text: qsTr("Delete File From System"), icon: "remove", action: deleteFileFromSource, visible: root.showLegacyActions && _deleteFileFromSource }
    ]
    function hasMediaUrls(data) { return data.length > 0 && data.every(item => !!item.mrl) }


    // Events

    onRequestData: (requestID, indexes) => {
        model.getData(indexes, function (data) {
            setData(requestID, data)
        })
    }

    // Functions

    function addAndPlay(dataList, options, indexes) {
        model.ml.addAndPlay(_mlIDList(dataList), _playerOptions(options))
    }

    function playAsAudio(dataList, options, indexes) {
        model.ml.addAndPlay(_mlIDList(dataList), _playerOptions(options, ":no-video"))
    }

    function playAsAlbum(dataList, options, indexes) {
        model.ml.addAndPlay(_mlIDList(dataList, root.albumIdDataRole), _playerOptions(options))
    }

    function enqueue(dataList, options, indexes) {
        model.ml.addToPlaylist(_mlIDList(dataList), _playerOptions(options))
    }

    function enqueueAsAlbum(dataList, options, indexes) {
        model.ml.addToPlaylist(_mlIDList(dataList, root.albumIdDataRole), _playerOptions(options))
    }

    function addToAudioOnlyPlaylist(dataList, options, indexes) {
        addToAPlaylist(dataList, options, indexes, MLPlaylistListModel.PLAYLIST_TYPE_AUDIO_ONLY)
    }

    function addToVideoOnlyPlaylist(dataList, options, indexes) {
        addToAPlaylist(dataList, options, indexes, MLPlaylistListModel.PLAYLIST_TYPE_VIDEO_ONLY)
    }

    function addToAPlaylist(dataList, options, indexes, type) {
        if (type === undefined)
            type = MLPlaylistListModel.PLAYLIST_TYPE_ALL

        DialogsProvider.playlistsDialog(_mlIDList(dataList), type)
    }

    function addFavorite(dataList, options, indexes) {
        model.setMediaIsFavorite(indexes[0], true)
    }

    function removeFavorite(dataList, options, indexes) {
        model.setMediaIsFavorite(indexes[0], false)
    }

    function markSeen(dataList, options, indexes) {
        model.setItemPlayed(indexes[0], true)
    }

    function markUnseen(dataList, options, indexes) {
        model.setItemPlayed(indexes[0], false)
    }

    function openContainingFolder(dataList, options, indexes) {
        const parentDir = model.getParentURL(indexes[0]);

        Qt.openUrlExternally(parentDir)
    }

    function deleteStream(dataList, options, indexes) {
        model.deleteStream(dataList[0][idDataRole])
    }

    function deleteFileFromSource(dataList, options, indexes) {
        let confirm = DialogsProvider.questionDialog(qsTr("Are you sure you want to delete this file?"));
        
        if (confirm) {
            model.deleteFileFromSource(indexes[0]);
            console.log("File Deleted !!");
        }
    }

    function showInformationAvailable(dataList, options, indexes) {
        return indexes.length === 1
                && Helpers.isInteger(options?.["information"] ?? null)
    }

    // Private

    function _checkRole(dataList, role, expected) {
        if (dataList.length !== 1)
            return false

        if (!(role in dataList[0]))
            return false

        return (dataList[0][role] === expected)
    }

    function _showAddFavorite(dataList, options, indexes) {
        return _checkRole(dataList, "isFavorite", false)
    }

    function _showRemoveFavorite(dataList, options, indexes) {
        return _checkRole(dataList, "isFavorite", true)
    }

    function _showSeen(dataList, options, indexes) {
        return _checkRole(dataList, "isNew", true)
    }

    function _showUnseen(dataList, options, indexes) {
        return _checkRole(dataList, "isNew", false)
    }

    function _openContainingFolder(dataList, options, indexes) {
        return _checkRole(dataList, "isLocal", true)
    }

    function _deleteStream(dataList,options, indexes) {
        return _checkRole(dataList, "isDeletable", true)
    }

    function _deleteFileFromSource(dataList, options, indexes) {
        return  _checkRole(dataList, "isDeletableFile", true)
    }

    function _signalShowInformation(dataList, options) {
        const index = options?.["information"] ?? null
        console.assert(Helpers.isInteger(index))
        showMediaInformation(index)
    }

    function _playerOptions(options, extraOptions) {
        const playerOpts = options?.["player-options"] ?? []
        return playerOpts.concat(extraOptions)
    }

    function _mlIDList(dataList, role = root.idDataRole) {
        const idList = []
        for (let i in dataList) {
            console.assert(dataList[i][role] !== undefined)
            idList.push(dataList[i][role])
        }

        return idList
    }
}
