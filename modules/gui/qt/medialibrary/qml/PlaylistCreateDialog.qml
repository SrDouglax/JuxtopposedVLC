/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as C
import VLC.Dialogs
import VLC.MainInterface
import VLC.MediaLibrary
import VLC.Widgets as Widgets
import VLC.Style

FormDialog {
    id: root
    objectName: "playlistCreateDialog"
    title: qsTr("New Playlist")
    preferredWidth: 712
    preferredHeight: 590
    required property MLPlaylistListModel playlistModel
    property var files: []
    property string playlistTitle: ""
    property url cover: ""
    property bool coverValid: true
    property bool creating: false
    property string error: ""
    canSave: playlistTitle.trim().length > 0 && files.length > 0 && coverValid
             && !creating && !playlistModel.transactionPending
    Widgets.FilePicker { id: filePicker; ctx: MainCtx }
    function chooseFiles() {
        const selected = filePicker.chooseFiles(qsTr("Add files to playlist"))
        if (selected.length) files = selected
    }
    function createPlaylist() {
        if (!canSave) return
        error = ""
        creating = true
        playlistModel.create(playlistTitle.trim(), files, cover)
    }
    onSaveRequested: createPlaylist()
    onClosed: { files = []; playlistTitle = ""; cover = ""; error = "" }
    Connections {
        target: root.playlistModel
        function onCreationFinished(success) {
            if (!root.creating) return
            root.creating = false
            if (success) root.close()
            else root.error = qsTr("The playlist could not be created.")
        }
    }
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
                wrapMode: Text.WordWrap
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: VLCStyle.dp(24, VLCStyle.scale)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: VLCStyle.dp(24, VLCStyle.scale)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: VLCStyle.dp(12, VLCStyle.scale)
                        Heading { text: qsTr("Playlist Details") }
                        Hint { Layout.fillWidth: true; text: qsTr("The playlist will be saved and displayed with this title and thumbnail.") }
                    }
                    C.TextField {
                        objectName: "playlistTitleField"
                        Layout.fillWidth: true
                        Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
                        text: root.playlistTitle
                        onTextChanged: root.playlistTitle = text
                        placeholderText: qsTr("e.g., Favorite Videos")
                        leftPadding: VLCStyle.dp(12, VLCStyle.scale)
                        color: VLCStyle.redesign.color("#8f8f8f", "#494949")
                        placeholderTextColor: VLCStyle.redesign.color("#3b3b3b", "#777777")
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                        background: Rectangle { color: VLCStyle.redesign.color("#090909", "#fafafa"); radius: 4; border.color: parent.activeFocus ? VLCStyle.redesign.accent : "transparent" }
                        onAccepted: root.createPlaylist()
                    }
                }
                Rectangle {
                    Layout.preferredWidth: VLCStyle.dp(108, VLCStyle.scale)
                    Layout.preferredHeight: VLCStyle.dp(108, VLCStyle.scale)
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    color: VLCStyle.redesign.color("#090909", "#fafafa")
                    Widgets.ImageExt {
                        id: thumbnail
                        anchors.fill: parent
                        radius: VLCStyle.dp(4, VLCStyle.scale)
                        fillMode: Image.PreserveAspectCrop
                        source: root.cover
                        onStatusChanged: root.coverValid = !root.cover.toString() || status === Image.Ready
                    }
                    ActionButton {
                        objectName: "playlistThumbnail"
                        anchors.centerIn: parent
                        width: VLCStyle.dp(32, VLCStyle.scale)
                        text: "+"
                        Accessible.name: qsTr("Choose playlist thumbnail")
                        onClicked: {
                            const image = filePicker.chooseImage(qsTr("Choose playlist thumbnail"))
                            if (image.toString()) root.cover = image
                        }
                    }
                }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: VLCStyle.redesign.separator }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: VLCStyle.dp(12, VLCStyle.scale)
                Heading { text: qsTr("Select Files") }
                Hint { text: qsTr("These files will be added to the playlist.") }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: VLCStyle.dp(186, VLCStyle.scale)
                color: VLCStyle.redesign.color("#090909", "#fafafa")
                Canvas {
                    anchors.fill: parent
                    property color stroke: VLCStyle.redesign.color("#3b3b3b", "#aaaaaa")
                    onStrokeChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset(); ctx.strokeStyle = stroke; ctx.lineWidth = 2
                        ctx.setLineDash([4,4]); ctx.strokeRect(1,1,width-2,height-2)
                    }
                }
                DropArea {
                    objectName: "playlistFilesDrop"
                    anchors.fill: parent
                    onEntered: drag => drag.accepted = drag.hasUrls
                    onDropped: drop => {
                        const urls = drop.urls.filter(url => url.toString().startsWith("file:"))
                        if (urls.length) { root.files = root.files.concat(urls); drop.acceptProposedAction() }
                    }
                }
                MouseArea { anchors.fill: parent; onClicked: root.chooseFiles() }
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: VLCStyle.dp(16, VLCStyle.scale)
                    Hint {
                        text: root.files.length ? qsTr("%1 file selected", "%1 files selected", root.files.length).arg(root.files.length)
                                                : qsTr("Drag files into the box or click here to select files.")
                    }
                    ActionButton {
                        objectName: "playlistChooseFilesButton"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: VLCStyle.dp(84, VLCStyle.scale)
                        text: "+"
                        onClicked: root.chooseFiles()
                    }
                }
            }
            Hint { visible: root.error.length > 0; text: root.error; color: VLCStyle.redesign.accent }
        }
    }
}
