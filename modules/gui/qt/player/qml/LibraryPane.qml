/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQml.Models
import QtQuick.Controls.Basic as Controls
import QtQuick.Templates as T
import VLC.MainInterface
import VLC.MediaLibrary
import VLC.Playlist
import VLC.Player
import VLC.PlayerControls
import VLC.Menus
import VLC.Dialogs
import VLC.Style
import VLC.Util
import VLC.Widgets as Widgets

FocusScope {
    id: root
    objectName: "sourceLibraryPane"
    implicitWidth: Math.min(VLCStyle.dp(426, VLCStyle.scale), Window.width * 0.6)
    readonly property bool isMusic: !MainCtx.hasEmbededVideo
    property string sourceId: Player.playlistId
    property string sourceName: Player.playlistName
    property bool browsingSources: false
    property bool gridMode: false
    property var sourceHistory: [{listing: true}]
    property int historyIndex: 0
    property var contextSourceId: null
    readonly property bool hasSource: MainCtx.mediaLibraryAvailable && sourceId.length > 0
    readonly property alias listView: tracks
    readonly property alias view: tracks
    readonly property alias searchBox: search
    signal closeRequested()

    // Browsing the source survives playing another item from that source.
    Component.onCompleted: {
        sourceId = Player.playlistId
        sourceName = Player.playlistName
        if (sourceId.length) navigateSource(sourceId, sourceName)
    }
    function navigateSource(id, name) {
        sourceHistory = sourceHistory.slice(0, historyIndex + 1).concat([{listing: false, id: id, name: name}])
        goToPage(sourceHistory.length - 1)
    }
    function goToPage(index) {
        if (index < 0 || index >= sourceHistory.length) return
        search.clear()
        historyIndex = index
        const page = sourceHistory[index]
        browsingSources = page.listing
        if (!page.listing) { sourceId = page.id; sourceName = page.name }
    }
    function activate(model, index) {
        if (browsingSources) { navigateSource(model.id.toString(), model.name); return }
        tracks.selectionModel.select(tracks.model.index(index, 0), ItemSelectionModel.ClearAndSelect)
        if (hasSource) MediaLib.playFromPlaylist(model.id, sourceModel.parentId)
        else MainPlaylistController.goTo(index, true)
    }
    Connections {
        target: Player
        function onInputChanged() {
            if (Player.playlistId.length > 0) {
                if (root.sourceId !== Player.playlistId) root.navigateSource(Player.playlistId, Player.playlistName)
                else root.sourceName = Player.playlistName
            }
        }
    }
    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }
    Navigation.cancelAction: root.closeRequested
    Keys.onEscapePressed: root.closeRequested()
    Rectangle { anchors.fill: parent; color: VLCStyle.redesign.color("#0e0e0e", theme.bg.primary) }

    function openLibrary() {
        if (root.hasSource && !root.browsingSources)
            History.push([root.isMusic ? "music" : "video", "playlists", "list"],
                         {parentId: sourceModel.parentId, title: root.sourceName}, Qt.MouseFocusReason)
        else History.push(root.browsingSources ? [root.isMusic ? "music" : "video", "playlists"]
                                              : root.isMusic ? ["music", "tracks"] : ["video", "all"])
        MainCtx.playerView = false
    }
    function addFiles() {
        const urls = filePicker.chooseFiles(qsTr("Add files"))
        if (!urls.length) return
        if (root.hasSource) sourceModel.insert(urls, sourceModel.count)
        else MainPlaylistController.append(urls, false)
    }
    Widgets.FilePicker { id: filePicker; ctx: MainCtx }
    MLPlaylistListModel {
        id: sources
        ml: MediaLib
        searchPattern: root.browsingSources ? search.searchPattern : ""
    }
    PlaylistListContextMenu {
        id: sourceListContext
        model: sources
        ctx: MainCtx
        onRequestDeleteSelectedPlaylists: {
            if (root.contextSourceId && DialogsProvider.questionDialog(qsTr("Delete this playlist?")))
                sources.deletePlaylists([root.contextSourceId])
        }
    }
    MLPlaylistModel {
        id: sourceModel
        ml: MediaLib
        parentId: MediaLib.deserializeMlItemIdFromString(root.sourceId)
        searchPattern: search.searchPattern
    }
    PlaylistListModel { id: queueModel; playlist: MainPlaylistController.playlist }
    MLContextMenu {
        id: sourceContext
        model: sourceModel
        popupParent: root.Window.window ? root.Window.window.contentItem : root
    }
    PlaylistContextMenu {
        id: queueContext
        model: queueModel
        selectionModel: tracks.selectionModel
        controler: MainPlaylistController
        ctx: MainCtx
    }
    SideNavigationPane {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: VLCStyle.dp(50, VLCStyle.scale)
        padding: 0
        rowHeight: VLCStyle.dp(46, VLCStyle.scale)
        flatBackground: true
        highlightCurrent: false
        delegateShowText: false
        useAcrylic: false
        onItemClicked: uri => {
            History.update(uri)
            MainCtx.playerView = false
        }
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: VLCStyle.dp(70, VLCStyle.scale)
        anchors.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
        spacing: 0
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(56, VLCStyle.scale)
            spacing: VLCStyle.dp(12, VLCStyle.scale)
            Widgets.IconToolButton {
                text: VLCIcons.back
                objectName: "sourceBackButton"
                description: qsTr("Back")
                enabled: root.historyIndex > 0
                onClicked: root.goToPage(root.historyIndex - 1)
                color: theme.fg.secondary
                backgroundColor: "transparent"
            }
            Widgets.IconToolButton {
                objectName: "sourceForwardButton"
                text: VLCIcons.back
                rotation: 180
                description: qsTr("Forward")
                enabled: root.historyIndex + 1 < root.sourceHistory.length
                onClicked: root.goToPage(root.historyIndex + 1)
                color: theme.fg.secondary
                backgroundColor: "transparent"
            }
            T.Button {
                id: originButton
                Layout.fillWidth: true
                Layout.preferredHeight: VLCStyle.dp(32, VLCStyle.scale)
                text: root.browsingSources ? qsTr("Playlists") : root.hasSource ? qsTr("Playlists › %1").arg(root.sourceName) : qsTr("Queue")
                onClicked: root.goToPage(0)
                background: Item {}
                contentItem: Text {
                    text: originButton.text
                    elide: Text.ElideMiddle
                    color: theme.fg.secondary
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.redesign.fontNormal
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Widgets.IconToolButton {
                id: originMore
                objectName: "sourceContextButton"
                text: VLCIcons.ellipsis
                description: qsTr("Playlist actions")
                enabled: root.hasSource && !root.browsingSources
                color: theme.fg.secondary
                backgroundColor: "transparent"
                onClicked: {
                    root.contextSourceId = sourceModel.parentId
                    const point = originMore.mapToGlobal(0, originMore.height)
                    sources.getIndexFromId(root.contextSourceId).then(index => sourceListContext.popup([sources.index(index,0)], point))
                }
            }
            RedesignIconButton {
                text: VLCIcons.dropzone
                iconSource: "qrc:///redesign/icons/open/default.png"
                description: qsTr("Open in library")
                color: theme.fg.secondary
                backgroundColor: "transparent"
                onClicked: root.openLibrary()
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(50, VLCStyle.scale)
            Text {
                Layout.fillWidth: true
                text: qsTr("%1 items").arg(tracks.count)
                color: theme.fg.secondary
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.redesign.fontNormal
            }
            Widgets.SortControl {
                objectName: "sourceSortButton"
                description: qsTr("Sort")
                color: theme.fg.secondary
                backgroundColor: "transparent"
                enabled: tracks.count > 1
                model: root.hasSource || root.browsingSources ? [
                    {text: qsTr("Title"), criteria: root.browsingSources ? "name" : "title"},
                    {text: qsTr("Duration"), criteria: "duration"}
                ] : [
                    {text: qsTr("Title"), criteria: PlaylistController.SORT_KEY_TITLE},
                    {text: qsTr("Duration"), criteria: PlaylistController.SORT_KEY_DURATION}
                ]
                sortKey: root.browsingSources ? sources.sortCriteria : root.hasSource ? sourceModel.sortCriteria : MainPlaylistController.sortKey
                sortOrder: root.browsingSources ? sources.sortOrder : root.hasSource ? sourceModel.sortOrder
                    : MainPlaylistController.sortOrder === PlaylistController.SORT_ORDER_ASC ? Qt.AscendingOrder : Qt.DescendingOrder
                onSortSelected: key => {
                    if (root.browsingSources) sources.sortCriteria = key
                    else if (root.hasSource) sourceModel.sortCriteria = key
                    else MainPlaylistController.sortKey = key
                }
                onSortOrderSelected: order => {
                    if (root.browsingSources) sources.sortOrder = order
                    else if (root.hasSource) sourceModel.sortOrder = order
                    else {
                        MainPlaylistController.sortOrder = order === Qt.AscendingOrder ? PlaylistController.SORT_ORDER_ASC : PlaylistController.SORT_ORDER_DESC
                        MainPlaylistController.sort()
                    }
                }
            }
            Widgets.IconToolButton {
                objectName: "sourceViewModeButton"
                text: root.gridMode ? VLCIcons.list : VLCIcons.grid
                description: qsTr("List/Grid")
                color: theme.fg.secondary
                backgroundColor: "transparent"
                onClicked: root.gridMode = !root.gridMode
            }
            Widgets.SearchBox {
                id: search
                enabled: root.hasSource || root.browsingSources
                displayRegexToggleButton: false
                displayCaseSensitiveToggleButton: false
                popBelow: true
                toggleButton.font.pixelSize: VLCStyle.redesign.iconSize
            }
        }
        Rectangle { Layout.fillWidth: true; height: VLCStyle.dp(1, VLCStyle.scale); color: VLCStyle.redesign.color("#1b1b1b", theme.border) }
        T.Button {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(60, VLCStyle.scale)
            text: qsTr("Add")
            enabled: !root.browsingSources && (!root.hasSource || !sourceModel.transactionPending)
            onClicked: root.addFiles()
            background: Rectangle {
                radius: VLCStyle.redesign.controlRadius
                color: parent.hovered || parent.down ? VLCStyle.redesign.controlHoverBackground : "transparent"
                border.color: parent.visualFocus ? VLCStyle.redesign.focusColor : "transparent"
            }
            contentItem: RowLayout {
                spacing: VLCStyle.dp(16, VLCStyle.scale)
                Widgets.IconLabel { text: VLCIcons.add; color: theme.fg.secondary; font.pixelSize: VLCStyle.redesign.iconSize }
                Text { Layout.fillWidth: true; text: parent.parent.text; color: theme.fg.secondary; font.pixelSize: VLCStyle.redesign.fontNormal; font.family: VLCStyle.redesign.fontFamily }
            }
        }
        Widgets.ListViewExt {
            id: tracks
            objectName: "musicSourceTracks"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            focus: true
            visible: !root.gridMode
            model: root.browsingSources ? sources : root.hasSource ? sourceModel : queueModel
            selectionModel: ListSelectionModel { model: tracks.model }
            Navigation.parentItem: root
            delegate: mediaDelegate
        }
        GridView {
            id: grid
            objectName: "sourceGrid"
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.gridMode
            clip: true
            model: tracks.model
            cellWidth: width / Math.max(1, Math.floor(width / VLCStyle.dp(140, VLCStyle.scale)))
            cellHeight: cellWidth + VLCStyle.dp(32, VLCStyle.scale)
            delegate: mediaDelegate
        }
    }
    Component {
        id: mediaDelegate
        T.ItemDelegate {
            required property int index
            required property var model
            width: root.gridMode ? grid.cellWidth : tracks.width
            height: root.gridMode ? grid.cellHeight : VLCStyle.dp(42, VLCStyle.scale)
            padding: 0
            onClicked: root.activate(model, index)
            background: Rectangle {
                radius: VLCStyle.redesign.controlRadius
                color: parent.hovered || parent.down ? VLCStyle.redesign.controlHoverBackground : "transparent"
                border.color: parent.visualFocus ? VLCStyle.redesign.focusColor : "transparent"
            }
            contentItem: GridLayout {
                columns: root.gridMode ? 1 : 2
                rowSpacing: VLCStyle.dp(8, VLCStyle.scale)
                columnSpacing: VLCStyle.dp(10, VLCStyle.scale)
                Widgets.ImageExt {
                    Layout.preferredWidth: root.gridMode ? grid.cellWidth - VLCStyle.dp(12, VLCStyle.scale) : VLCStyle.dp(32, VLCStyle.scale)
                    Layout.preferredHeight: Layout.preferredWidth
                    source: root.hasSource ? (model.thumbnail || VLCStyle.noArtAlbumCover) : (model.artwork || VLCStyle.noArtAlbumCover)
                    fillMode: Image.PreserveAspectCrop
                    radius: 0
                }
                Text {
                    Layout.fillWidth: true
                    text: (root.browsingSources ? model.name : model.title) || ""
                    elide: Text.ElideRight
                    color: theme.fg.secondary
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.redesign.fontNormal
                }
            }
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: eventPoint => {
                    const itemIndex = tracks.model.index(index, 0)
                    tracks.selectionModel.select(itemIndex, ItemSelectionModel.ClearAndSelect)
                    const position = parent.mapToGlobal(eventPoint.position)
                    if (root.browsingSources) {
                        root.contextSourceId = model.id
                        sourceListContext.popup([itemIndex], position)
                    } else if (root.hasSource) sourceContext.popup([itemIndex], position)
                    else queueContext.popup(position)
                }
            }
        }
    }
}
