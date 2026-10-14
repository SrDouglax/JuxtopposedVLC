/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as C
import QtQuick.Controls.impl as Impl
import VLC.MainInterface
import VLC.Player
import VLC.PlayerControls
import VLC.Playlist
import VLC.MediaLibrary
import VLC.Dialogs
import VLC.Widgets as Widgets
import VLC.Style

C.Popup {
    id: root
    objectName: "playerNavigationMenu"
    property int currentTab: 0
    property int preferredHeight: 940
    property bool previousGlobalShortcuts: true
    readonly property ColorContext colorContext: ColorContext {
        palette: VLCStyle.palette
        colorSet: ColorContext.Window
    }
    width: VLCStyle.dp(400, VLCStyle.scale)
    height: VLCStyle.dp(940, VLCStyle.scale)
    padding: 0
    focus: true
    closePolicy: C.Popup.CloseOnEscape | C.Popup.CloseOnPressOutside
    onOpened: {
        previousGlobalShortcuts = MainCtx.useGlobalShortcuts;
        MainCtx.useGlobalShortcuts = false;
        tabs.focusCurrent();
    }
    onClosed: MainCtx.useGlobalShortcuts = previousGlobalShortcuts
    background: Rectangle {
        radius: VLCStyle.dp(6, VLCStyle.scale)
        color: VLCStyle.redesign.color("#0e0e0e", "#c2c2c1")
    }
    PlaylistListModel {
        id: queue
        playlist: MainPlaylistController.playlist
    }
    MLBookmarkModel {
        id: bookmarks
        player: Player
        ml: MediaLib
    }
    Widgets.FilePicker {
        id: picker
        ctx: MainCtx
    }
    contentItem: ColumnLayout {
        spacing: 0
        PanelTabs {
            id: tabs
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            model: [{
                    "title": qsTr("Queue"),
                    "icon": "qrc:///redesign/icons/queue/default.png"
                }, {
                    "title": qsTr("Bookmarks"),
                    "icon": "qrc:///redesign/icons/bookmarks/default.png"
                }, {
                    "title": qsTr("Chapters"),
                    "icon": "qrc:///redesign/icons/chapters/default.png"
                }]
            currentIndex: root.currentTab
            onSelected: index => root.currentTab = index
        }
        RowLayout {
            visible: root.currentTab === 0
            Layout.fillWidth: true
            Layout.leftMargin: VLCStyle.dp(24, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
            Layout.topMargin: VLCStyle.dp(16, VLCStyle.scale)
            Layout.bottomMargin: VLCStyle.dp(16, VLCStyle.scale)
            spacing: VLCStyle.dp(8, VLCStyle.scale)
            Text {
                Layout.fillWidth: true
                text: qsTr("%1 items - %2").arg(queue.count).arg(queue.duration.formatLong())
                elide: Text.ElideRight
                color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }
            Widgets.SortControl {
                width: VLCStyle.dp(28, VLCStyle.scale)
                height: VLCStyle.dp(28, VLCStyle.scale)
                model: MainPlaylistController.sortKeyTitleList
                sortKey: MainPlaylistController.sortKey
                sortOrder: MainPlaylistController.sortOrder
                background: Rectangle {
                    color: parent.hovered ? VLCStyle.redesign.color("#191919", "#ababaa") : "transparent"
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                }
                onSortSelected: key => MainPlaylistController.sort(key)
                onSortOrderSelected: order => {
                    MainPlaylistController.sortOrder = order;
                    MainPlaylistController.sort();
                }
                contentItem: Impl.IconImage {
                    source: "qrc:///redesign/icons/sort/default.png"
                    color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
                }
            }
            IconAction {
                iconName: "replay"
                Accessible.name: qsTr("Repeat")
                checked: MainPlaylistController.repeatMode !== PlaylistController.PLAYBACK_REPEAT_NONE
                onClicked: MainPlaylistController.toggleRepeatMode()
            }
            IconAction {
                iconName: "swap"
                Accessible.name: qsTr("Shuffle")
                checked: MainPlaylistController.random
                onClicked: MainPlaylistController.toggleRandom()
            }
            IconAction {
                iconName: "remove"
                Accessible.name: qsTr("Remove selected item")
                enabled: queue.count > 0
                onClicked: queue.removeItems([entries.currentIndex >= 0 ? entries.currentIndex : 0])
            }
            IconAction {
                iconName: "add"
                Accessible.name: qsTr("Add files to queue")
                onClicked: {
                    const files = picker.chooseFiles(qsTr("Add files to queue"));
                    if (files.length)
                        MainPlaylistController.append(files, false);
                }
            }
        }
        ListView {
            id: entries
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: VLCStyle.dp(24, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(24, VLCStyle.scale)
            Layout.topMargin: root.currentTab === 0 ? 0 : 24
            clip: true
            model: root.currentTab === 0 ? queue : root.currentTab === 1 ? bookmarks : Player.chapters
            C.ScrollBar.vertical: C.ScrollBar {
            }
            delegate: C.ItemDelegate {
                id: row
                required property var model
                required property int index
                width: entries.width
                height: VLCStyle.dp(44, VLCStyle.scale)
                onClicked: {
                    entries.currentIndex = index;
                    if (root.currentTab === 0)
                        MainPlaylistController.goTo(index, true);
                    else if (root.currentTab === 1)
                        bookmarks.select(bookmarks.index(index, 0));
                    else
                        Player.chapters.selectChapter(index);
                }
                background: Rectangle {
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    color: row.hovered ? VLCStyle.redesign.color("#191919", "#ababaa") : "transparent"
                    border.color: row.visualFocus ? VLCStyle.redesign.accent : "transparent"
                }
                contentItem: RowLayout {
                    spacing: VLCStyle.dp(12, VLCStyle.scale)
                    Impl.IconImage {
                        Layout.preferredWidth: VLCStyle.dp(20, VLCStyle.scale)
                        Layout.preferredHeight: VLCStyle.dp(20, VLCStyle.scale)
                        source: "qrc:///redesign/icons/" + (root.currentTab === 0 ? (row.model.isCurrent ? "play" : "move") : (root.currentTab === 1 ? "bookmarks" : "chapters")) + "/default.png"
                        color: root.currentTab === 0 && row.model.isCurrent ? VLCStyle.redesign.accent : VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
                        DragHandler {
                            target: null
                            enabled: root.currentTab === 0
                            property int dropIndex: -1
                            onCentroidChanged: if (active) {
                                const point = parent.mapToItem(entries, centroid.position.x, centroid.position.y);
                                dropIndex = entries.indexAt(4, point.y + entries.contentY);
                            }
                            onActiveChanged: if (!active && dropIndex >= 0 && dropIndex !== row.index) {
                                if (dropIndex > row.index)
                                    queue.moveItemsPost([row.index], dropIndex);
                                else
                                    queue.moveItemsPre([row.index], dropIndex);
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: (root.currentTab === 0 ? row.model.title : root.currentTab === 1 ? row.model.name : row.model.display) ?? ""
                        elide: Text.ElideRight
                        color: VLCStyle.redesign.color("#8f8f8f", "#4d4d4d")
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    }
                    Text {
                        text: root.currentTab === 0 ? (row.model.duration?.formatHMS() ?? "") : root.currentTab === 1 ? (row.model.time ?? "") : (row.model.time?.formatHMS() ?? "")
                        color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                width: parent.width
                visible: entries.count === 0
                text: root.currentTab === 0 ? qsTr("Queue is empty") : root.currentTab === 1 ? qsTr("No bookmarks for this media") : qsTr("No chapters in this media")
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
            }
        }
        PanelAction {
            visible: root.currentTab === 1
            Layout.fillWidth: true
            Layout.margins: VLCStyle.dp(20, VLCStyle.scale)
            text: qsTr("Manage bookmarks…")
            enabled: MainCtx.mediaLibraryAvailable
            onClicked: {
                root.close();
                DialogsProvider.bookmarksDialog();
            }
        }
    }
    component IconAction: C.ToolButton {
        property string iconName
        implicitWidth: VLCStyle.dp(28, VLCStyle.scale)
        implicitHeight: VLCStyle.dp(28, VLCStyle.scale)
        background: Rectangle {
            color: parent.hovered ? VLCStyle.redesign.color("#191919", "#ababaa") : "transparent"
            radius: VLCStyle.dp(4, VLCStyle.scale)
        }
        contentItem: Impl.IconImage {
            source: "qrc:///redesign/icons/" + parent.iconName + "/default.png"
            color: parent.checked ? VLCStyle.redesign.accent : VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
            opacity: parent.enabled ? 1 : 0.4
        }
    }
}
