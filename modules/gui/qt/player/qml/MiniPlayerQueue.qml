import QtQuick
import QtQuick.Controls.Basic as Controls

import VLC.MainInterface
import VLC.Playlist
import VLC.Style
import VLC.Widgets as Widgets

Item {
    id: root
    objectName: "miniPlayerQueue"
    implicitHeight: 228

    PlaylistListModel {
        id: queueModel
        playlist: MainPlaylistController.playlist
    }
    Widgets.FilePicker { id: filePicker; ctx: MainCtx }

    Rectangle {
        anchors.fill: parent
        color: "#111111"
        radius: VLCStyle.dp(8, VLCStyle.scale)
    }

    Text {
        x: 12
        y: 10
        width: parent.width - 24
        text: qsTr("Queue")
        color: VLCStyle.redesign.textSecondary
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
        horizontalAlignment: Text.AlignHCenter
    }
    Rectangle {
        x: 0
        y: 37
        width: parent.width
        height: 1
        color: VLCStyle.redesign.separator
    }
    Text {
        x: 12
        y: 48
        width: parent.width - 110
        text: queueModel.count > 0
              ? qsTr("%1 items · %2").arg(queueModel.count).arg(queueModel.duration.formatLong())
              : qsTr("Queue is empty")
        color: VLCStyle.redesign.textMuted
        elide: Text.ElideRight
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(11, VLCStyle.scale)
    }
    Row {
        x: parent.width - width - 8
        y: 41
        spacing: 0
        Widgets.SortControl {
            width: 26
            height: 28
            enabled: queueModel.count > 1
            model: MainPlaylistController.sortKeyTitleList
            sortKey: MainPlaylistController.sortKey
            sortOrder: MainPlaylistController.sortOrder === PlaylistController.SORT_ORDER_ASC
                       ? Qt.AscendingOrder : Qt.DescendingOrder
            onSortSelected: key => {
                MainPlaylistController.sortKey = key
                MainPlaylistController.sort()
            }
            onSortOrderSelected: order => {
                MainPlaylistController.sortOrder = order === Qt.AscendingOrder
                                                 ? PlaylistController.SORT_ORDER_ASC
                                                 : PlaylistController.SORT_ORDER_DESC
                MainPlaylistController.sort()
            }
        }
        Controls.Button {
            width: 26
            height: 28
            text: "−"
            enabled: queueList.currentIndex >= 0 && queueModel.count > 0
            Accessible.name: qsTr("Remove current item from queue")
            background: Item {}
            contentItem: Text {
                text: parent.text
                color: parent.enabled ? VLCStyle.redesign.textSecondary : VLCStyle.redesign.textDisabled
                font.pixelSize: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: queueModel.removeItems([queueList.currentIndex])
        }
        Controls.Button {
            width: 26
            height: 28
            text: "+"
            Accessible.name: qsTr("Add files to queue")
            background: Item {}
            contentItem: Text {
                text: parent.text
                color: VLCStyle.redesign.textSecondary
                font.pixelSize: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: {
                const selected = filePicker.chooseFiles(qsTr("Add files to queue"))
                if (selected.length > 0)
                    MainPlaylistController.append(selected, false)
            }
        }
    }

    ListView {
        id: queueList
        objectName: "miniPlayerQueueList"
        x: 10
        y: 78
        width: parent.width - 20
        height: parent.height - 86
        clip: true
        model: queueModel
        currentIndex: queueModel.currentIndex
        boundsBehavior: Flickable.StopAtBounds
        delegate: Controls.ItemDelegate {
            required property int index
            required property string title
            required property var duration
            required property bool isCurrent
            width: queueList.width
            height: VLCStyle.dp(31, VLCStyle.scale)
            leftPadding: 5
            rightPadding: 5
            background: Rectangle {
                color: parent.hovered || parent.highlighted ? "#262626" : "transparent"
                radius: 4
            }
            contentItem: Row {
                spacing: 8
                Text {
                    width: 14
                    height: parent.height
                    text: isCurrent ? "▶" : "="
                    color: isCurrent ? VLCStyle.redesign.accent : VLCStyle.redesign.textMuted
                    font.pixelSize: VLCStyle.dp(11, VLCStyle.scale)
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    width: parent.width - 72
                    height: parent.height
                    text: title
                    color: VLCStyle.redesign.textSecondary
                    elide: Text.ElideRight
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(11, VLCStyle.scale)
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    width: 43
                    height: parent.height
                    text: duration.formatHMS()
                    color: VLCStyle.redesign.textMuted
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(10, VLCStyle.scale)
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Accessible.name: title
            onClicked: MainPlaylistController.goTo(index, true)
        }
    }
}
