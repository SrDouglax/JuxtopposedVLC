/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Controls.Basic as Controls
import VLC.MainInterface
import VLC.Player
import VLC.Playlist
import VLC.MediaLibrary
import VLC.Dialogs
import VLC.Style

Controls.Popup {
    id: root
    objectName: "playerNavigationMenu"
    property int currentTab: 0
    property bool previousGlobalShortcuts: true
    width: VLCStyle.dp(400, VLCStyle.scale)
    height: VLCStyle.dp(500, VLCStyle.scale)
    padding: VLCStyle.dp(8, VLCStyle.scale)
    focus: true
    closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside
    onOpened: {
        previousGlobalShortcuts = MainCtx.useGlobalShortcuts
        MainCtx.useGlobalShortcuts = false
        tabs.itemAt(currentTab).forceActiveFocus()
    }
    onClosed: MainCtx.useGlobalShortcuts = previousGlobalShortcuts
    background: Rectangle {
        radius: VLCStyle.dp(6, VLCStyle.scale)
        color: VLCStyle.redesign.color(VLCStyle.redesign.windowBackground, "#c2c2c1")
        border.color: VLCStyle.redesign.separator
    }
    MLBookmarkModel { id: bookmarks; player: Player; ml: MediaLib }
    contentItem: Item {
        Row {
            id: header
            width: parent.width
            height: VLCStyle.dp(48, VLCStyle.scale)
            Repeater {
                id: tabs
                model: [qsTr("Queue"), qsTr("Bookmarks"), qsTr("Chapters")]
                Controls.Button {
                    required property int index
                    required property string modelData
                    width: header.width / 3
                    height: header.height
                    text: modelData
                    checked: root.currentTab === index
                    onClicked: root.currentTab = index
                    background: Rectangle {
                        color: parent.hovered ? VLCStyle.redesign.color("#222222", "#ababaa") : "transparent"
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: VLCStyle.dp(2, VLCStyle.scale)
                            visible: parent.parent.checked
                            color: VLCStyle.redesign.accent
                        }
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.checked ? VLCStyle.redesign.accent : VLCStyle.redesign.color("#EAEAEA", "#2e2e2e")
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }
        PlaylistPane {
            anchors { top: header.bottom; bottom: parent.bottom; left: parent.left; right: parent.right }
            visible: root.currentTab === 0
            useAcrylic: false
        }
        ListView {
            id: entries
            anchors { top: header.bottom; bottom: manage.top; left: parent.left; right: parent.right }
            clip: true
            visible: root.currentTab !== 0
            model: root.currentTab === 1 ? bookmarks : Player.chapters
            Controls.ScrollBar.vertical: Controls.ScrollBar {}
            delegate: Controls.ItemDelegate {
                width: entries.width
                height: VLCStyle.dp(44, VLCStyle.scale)
                text: root.currentTab === 1 ? model.name : model.display
                onClicked: {
                    if (root.currentTab === 1) bookmarks.select(bookmarks.index(index, 0))
                    else Player.chapters.selectChapter(index)
                }
                contentItem: Text {
                    text: parent.text
                    color: VLCStyle.redesign.color("#EAEAEA", "#2e2e2e")
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }
            Text {
                anchors.centerIn: parent
                width: parent.width
                visible: entries.count === 0
                text: root.currentTab === 1 ? qsTr("No bookmarks for this media") : qsTr("No chapters in this media")
                color: VLCStyle.redesign.color("#8F8F8F", "#4d4d4d")
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
        Controls.Button {
            id: manage
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: visible ? VLCStyle.dp(36, VLCStyle.scale) : 0
            visible: root.currentTab === 1
            enabled: MainCtx.mediaLibraryAvailable
            text: qsTr("Manage bookmarks…")
            onClicked: { root.close(); DialogsProvider.bookmarksDialog() }
        }
    }
}
