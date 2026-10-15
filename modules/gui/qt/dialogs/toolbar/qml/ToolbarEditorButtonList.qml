/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
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
import QtQuick.Templates as T
import QtQml.Models
import QtQuick.Layouts


import VLC.Player
import VLC.PlayerControls
import VLC.Style
import VLC.Widgets as Widgets
import VLC.Util

GridView {
    id: root
    objectName: "toolbarEditorControlCatalog"

    clip: true

    T.ScrollBar.vertical: Widgets.ScrollBarExt { }
    readonly property var catalog: {
        const order = [
            ControlListModel.WIDGET_SPACER, ControlListModel.DIVIDER_WIDGET, ControlListModel.PLAYBACK_SPEED_BUTTON,
            ControlListModel.SKIP_FW_BUTTON, ControlListModel.SKIP_BACK_BUTTON, ControlListModel.SKIP_FW_15_BUTTON,
            ControlListModel.SKIP_BACK_15_BUTTON, ControlListModel.STOP_BUTTON, ControlListModel.LOOP_BUTTON,
            ControlListModel.RANDOM_BUTTON, ControlListModel.RECORD_BUTTON, ControlListModel.SNAPSHOT_BUTTON,
            ControlListModel.PLAYER_SWITCH_BUTTON, ControlListModel.HDR_BUTTON, ControlListModel.ZOOM_WIDGET,
            ControlListModel.SOURCE_SIDEBAR_BUTTON, ControlListModel.QUIT_BUTTON, ControlListModel.SETTINGS_BUTTON,
            ControlListModel.HOME_BUTTON, ControlListModel.ARTWORK_INFO, ControlListModel.FILE_NAME_WIDGET,
            ControlListModel.ARTIST_NAME_WIDGET, ControlListModel.FOLDER_NAME_WIDGET, ControlListModel.PLAYLIST_NAME_WIDGET,
            ControlListModel.INFO_BUTTON, ControlListModel.REPLAY_BUTTON, ControlListModel.CHAPTERS_BUTTON,
            ControlListModel.FAVORITE_BUTTON, ControlListModel.BOOKMARK_BUTTON, ControlListModel.BOOKMARKS_BUTTON,
            ControlListModel.PLAYLISTS_BUTTON
        ]
        const controls = PlayerControlbarControls.controlList
        return order.map(id => controls.find(entry => entry.id === id)).filter(entry => !!entry)
    }
    model: catalog.length

    currentIndex: -1
    highlightFollowsCurrentItem: false

    // Nine controls fit the 1048px reference dialog; narrower windows retain
    // usable drag targets instead of clipping columns.
    cellWidth: width >= VLCStyle.dp(990, VLCStyle.scale) ? VLCStyle.dp(110, VLCStyle.scale)
               : Math.max(VLCStyle.dp(94, VLCStyle.scale),
                        Math.floor(width / Math.max(1, Math.floor(width / VLCStyle.dp(108, VLCStyle.scale)))))
    cellHeight: VLCStyle.dp(120, VLCStyle.scale)

    boundsBehavior: Flickable.StopAtBounds

    property alias removeInfoRectVisible: removeInfoRect.visible

    signal controlDragStarted(int id)
    signal controlDragStopped(int id)


    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    MouseArea {
        anchors.fill: parent
        z: -1

        preventStealing: true
    }

    property Component implicitFlickableScrollHandler: DefaultFlickableScrollHandler { }

    // NOTE: This property can be set to null to prevent using a scroll handler:
    property FlickableScrollHandler scrollHandler: {
        if (interactive) {
            // JS ownership:
            return implicitFlickableScrollHandler.createObject(null, { target: root })
        } else {
            return null
        }
    }

    DropArea {
        id: dropArea
        anchors.fill: parent

        z: 3

        function isFromList() {
            if (drag.source.objectName === "buttonsList")
                return true
            else
                return false
        }

        onDropped: (drop) => {
            if (isFromList())
                return

            const sourceModel = drop.source.dndView.model
            const sourceIndex = drop.source.DelegateModel.itemsIndex
            Qt.callLater(() => sourceModel.remove(sourceIndex))
            drop.accept(Qt.MoveAction)
        }
    }

    Rectangle {
        id: removeInfoRect
        anchors.fill: parent
        z: 2

        visible: false

        opacity: 0.8
        color: theme.bg.primary

        border.color: theme.border
        border.width: VLCStyle.dp(2, VLCStyle.scale)
        border.pixelAligned: (radius < Number.EPSILON)

        Text {
            anchors.centerIn: parent

            text: VLCIcons.del
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter

            font.pointSize: VLCStyle.fontHeight_xxxlarge

            font.family: VLCIcons.fontFamily
            color: theme.fg.secondary
        }

        MouseArea {
            anchors.fill: parent

            cursorShape: visible ? Qt.DragMoveCursor : Qt.ArrowCursor
        }
    }

    MouseArea {
        anchors.fill: parent
        z: 1

        visible: buttonDragItem.Drag.active

        cursorShape: visible ? Qt.DragMoveCursor : Qt.ArrowCursor
    }

    delegate: MouseArea {
        width: cellWidth
        height: cellHeight

        hoverEnabled: true
        cursorShape: Qt.OpenHandCursor

        objectName: "buttonsList"

        drag.target: buttonDragItem

        drag.smoothed: false

        readonly property int mIndex: root.catalog[model.index].id

        readonly property ColorContext colorContext: ColorContext {
            colorSet: ColorContext.Item
        }

        drag.onActiveChanged: {
            if (drag.active) {
                root.controlDragStarted(mIndex)

                buttonDragItem.iconSource = root.catalog[model.index].icon || ""
                buttonDragItem.text = root.catalog[model.index].label
                buttonDragItem.Drag.source = this
                buttonDragItem.Drag.start()

                GridView.delayRemove = true
            } else {
                buttonDragItem.Drag.drop()

                root.controlDragStopped(mIndex)

                GridView.delayRemove = false
            }
        }

        onPressed: (mouse) => {
            const pos = mapToItem(buttonDragItem.parent, mouseX, mouseY)
            buttonDragItem.y = pos.y + VLCStyle.dragDelta
            buttonDragItem.x = pos.x + VLCStyle.dragDelta
        }

        Rectangle {
            anchors.fill: parent

            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height

            color: "transparent"

            radius: VLCStyle.redesign.controlRadius
            border.width: VLCStyle.dp(1, VLCStyle.scale)
            border.color: containsMouse && !buttonDragItem.Drag.active ? VLCStyle.redesign.accent
                                                                       : "transparent"
            border.pixelAligned: (radius < Number.EPSILON)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: VLCStyle.dp(6, VLCStyle.scale)
                spacing: VLCStyle.dp(8, VLCStyle.scale)

                Rectangle {
                    Layout.preferredWidth: VLCStyle.dp(32, VLCStyle.scale)
                    Layout.preferredHeight: VLCStyle.dp(32, VLCStyle.scale)
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: VLCStyle.dp(8, VLCStyle.scale)
                    color: "transparent"
                    Canvas {
                        anchors.fill: parent
                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.strokeStyle = VLCStyle.redesign.color("#6b6b6b", "#777777")
                            ctx.setLineDash([3, 3]); ctx.strokeRect(0.5, 0.5, width - 1, height - 1)
                        }
                    }

                    Image {
                        anchors.centerIn: parent
                        width: VLCStyle.dp(24, VLCStyle.scale)
                        height: width
                        source: root.catalog[model.index].icon || ""
                        fillMode: Image.PreserveAspectFit
                        visible: source.toString().length > 0
                    }

                    EditorDummyButton {
                        visible: !root.catalog[model.index].icon && root.catalog[model.index].id !== ControlListModel.WIDGET_SPACER
                        anchors.centerIn: parent
                        color: VLCStyle.redesign.color("#969696", colorContext.fg.primary)
                        text: root.catalog[model.index].label
                        font.pixelSize: VLCStyle.dp(23, VLCStyle.scale)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    color: VLCStyle.redesign.color("#969696", colorContext.fg.secondary)
                    elide: Text.ElideRight
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.redesign.fontNormal
                    text: [ControlListModel.SKIP_FW_BUTTON, ControlListModel.SKIP_BACK_BUTTON,
                           ControlListModel.SKIP_FW_15_BUTTON, ControlListModel.SKIP_BACK_15_BUTTON,
                           ControlListModel.SOURCE_SIDEBAR_BUTTON, ControlListModel.PLAYLIST_NAME_WIDGET]
                            .includes(root.catalog[model.index].id)
                          ? root.catalog[model.index].text.replace(" ", "\n") : root.catalog[model.index].text
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignTop
                    maximumLineCount: 2
                }
            }
        }
    }
}
