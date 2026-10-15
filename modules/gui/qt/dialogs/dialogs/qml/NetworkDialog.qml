/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as C
import VLC.MediaLibrary
import VLC.MainInterface
import VLC.Playlist
import VLC.Player
import VLC.Style

FormDialog {
    id: root
    objectName: "networkStreamDialog"
    title: qsTr("Open Network Stream")
    property string urlsText: ""
    property string playlistName: ""
    readonly property var urls: urlsText.split(/\r?\n/).map(line => line.trim()).filter(line => line.length > 0)
    readonly property bool validUrls: urls.length > 0 && urls.every(url => /^[a-z][a-z0-9+.-]*:\/\/\S+$/i.test(url))
    canSave: validUrls && (!playlistName.trim() || (MainCtx.mediaLibraryAvailable && !playlists.transactionPending))
    MLPlaylistListModel { id: playlists; ml: MediaLib }
    onSaveRequested: {
        if (!canSave) return
        if (playlistName.trim()) playlists.create(playlistName.trim(), urls)
        else MainPlaylistController.append(urls, true)
        close()
    }
    onClosed: { urlsText = ""; playlistName = "" }
    panel: Component {
        ColumnLayout {
            spacing: VLCStyle.dp(24, VLCStyle.scale)
            component Heading: Text {
                color: VLCStyle.redesign.color("#bfbfbf", "#333333")
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            }
            component Hint: Text {
                color: VLCStyle.redesign.color("#6b6b6b", "#555555")
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: VLCStyle.dp(12, VLCStyle.scale)
                Heading { text: qsTr("Network URL") }
                Hint { text: qsTr("You can enter multiple links to load.") }
            }
            C.TextArea {
                objectName: "networkUrls"
                Layout.fillWidth: true
                Layout.preferredHeight: VLCStyle.dp(190, VLCStyle.scale)
                padding: VLCStyle.dp(12, VLCStyle.scale)
                placeholderText: qsTr("e.g., https://www.example.com/stream.avi")
                text: root.urlsText
                onTextChanged: root.urlsText = text
                color: VLCStyle.redesign.color("#8f8f8f", "#494949")
                placeholderTextColor: VLCStyle.redesign.color("#3b3b3b", "#777777")
                selectByMouse: true
                wrapMode: TextEdit.WrapAnywhere
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                background: Rectangle { color: VLCStyle.redesign.color("#090909", "#fafafa"); radius: 4; border.color: parent.activeFocus ? VLCStyle.redesign.accent : "transparent" }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: VLCStyle.redesign.separator }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: VLCStyle.dp(12, VLCStyle.scale)
                Heading { text: qsTr("Playlist Name (optional)") }
                Hint { text: qsTr("The playlist will be saved and displayed with this title.") }
            }
            C.TextField {
                objectName: "networkPlaylistName"
                Layout.fillWidth: true
                Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
                placeholderText: qsTr("e.g., Favorite TV Channels")
                text: root.playlistName
                onTextChanged: root.playlistName = text
                enabled: MainCtx.mediaLibraryAvailable
                leftPadding: VLCStyle.dp(12, VLCStyle.scale)
                color: VLCStyle.redesign.color("#8f8f8f", "#494949")
                placeholderTextColor: VLCStyle.redesign.color("#3b3b3b", "#777777")
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                background: Rectangle { color: VLCStyle.redesign.color("#090909", "#fafafa"); radius: 4; border.color: parent.activeFocus ? VLCStyle.redesign.accent : "transparent" }
            }
        }
    }
}
