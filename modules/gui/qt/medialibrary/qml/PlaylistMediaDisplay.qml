/*****************************************************************************
 * Copyright (C) 2021 VLC authors and VideoLAN
 *
 * Authors: Benjamin Arnaud <bunjee@omega.gg>
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
import QtQuick.Layouts
import QtQml.Models
import QtQuick.Dialogs

import VLC.MainInterface
import VLC.MediaLibrary

import VLC.Widgets as Widgets
import VLC.Util
import VLC.Style
import VLC.Dialogs

Widgets.PageExt {
    id: root

    property bool isMusic: true

    // NOTE: This is used to determine which media(s) shall be displayed.
    property alias parentId: model.parentId
    property alias searchPattern: model.searchPattern
    property alias sortOrder: model.sortOrder
    property alias sortCriteria: model.sortCriteria

    property int initialIndex: 0
    readonly property int currentIndex: view.currentIndex
    property alias model: model
    property alias dragItem: dragItem

    property string _placeHolder: root.isMusic ? VLCStyle.noArtAlbumCover : VLCStyle.noArtVideoCover

    hasGridListMode: false
    isSearchable: true

    headerAction: Component {
        RowLayout {
            spacing: VLCStyle.margin_xsmall

            Widgets.ButtonExt {
                objectName: "playlistAddFilesButton"
                text: qsTr("Add files")
                enabled: !model.transactionPending
                onClicked: addFilesDialog.open()
            }

            Widgets.ButtonExt {
                objectName: "playlistMoveUpButton"
                text: qsTr("Move up")
                enabled: root.selectedRow > 0 && !model.transactionPending
                onClicked: model.move(view.selectionModel.selectedRows(), root.selectedRow - 1)
            }

            Widgets.ButtonExt {
                objectName: "playlistMoveDownButton"
                text: qsTr("Move down")
                enabled: root.selectedRow >= 0 && root.selectedRow < model.count - 1
                         && !model.transactionPending
                onClicked: model.move(view.selectionModel.selectedRows(), root.selectedRow + 2)
            }

            Widgets.ButtonExt {
                objectName: "playlistRemoveItemButton"
                text: qsTr("Remove")
                enabled: view.selectionModel.hasSelection && !model.transactionPending
                onClicked: root.onDelete()
            }
        }
    }

    readonly property int selectedRow: view.selectionModel.selectedIndexes.length === 1
                                       ? view.selectionModel.selectedIndexes[0].row : -1

    FileDialog {
        id: addFilesDialog
        objectName: "playlistAddFilesDialog"
        title: qsTr("Add files to playlist")
        fileMode: FileDialog.OpenFiles
        onAccepted: if (selectedFiles.length > 0) model.insert(selectedFiles, model.count)
    }

    // Events

    onModelChanged: resetFocus()

    onInitialIndexChanged: resetFocus()


    function setCurrentItemFocus(reason) { view.setCurrentItemFocus(reason); }

    function resetFocus() {
        const count = model.count

        if (count === 0 || initialIndex === -1) return

        var index

        if (initialIndex < count)
            index = initialIndex
        else
            index = 0

        view.selectionModel.select(model.index(index, 0), ItemSelectionModel.ClearAndSelect);

        view.positionViewAtIndex(index, ItemView.Contain)

        view.setCurrentItem(index)
    }

    function onDelete()
    {
        const indexes = view.selectionModel.selectedIndexes;

        if (indexes.length === 0)
            return;

        if (DialogsProvider.questionDialog(qsTr("Remove selected media from this playlist?"),
                                           qsTr("Remove from playlist")))
            model.remove(indexes);
    }


    FocusScope {

        anchors.fill:  parent

        MLPlaylistModel {
            id: model

            ml: MediaLib

            onCountChanged: {
                // NOTE: We need to cancel the Drag item manually when resetting. Should this be called
                //       from 'onModelReset' only ?
                dragItem.Drag.cancel();

                if (count === 0 || view.selectionModel.hasSelection)
                    return;

                resetFocus();
            }

            function onBusynessChanged() {
                if (transactionPending || loading) {
                    MainCtx.setCursor(root, Qt.BusyCursor)
                    visibilityTimer.start()
                } else {
                    visibilityTimer.stop()
                    progressIndicator.visible = false
                    MainCtx.unsetCursor(root)
                }
            }
        }

        Component.onCompleted: {
            model.transactionPendingChanged.connect(model.onBusynessChanged)
            model.loadingChanged.connect(model.onBusynessChanged)
            model.onBusynessChanged()
        }

        Widgets.ProgressIndicator {
            id: progressIndicator
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: VLCStyle.margin_small

            visible: false

            z: 99

            text: root.model?.transactionPending ? qsTr("Processing...") : ""

            Timer {
                id: visibilityTimer

                interval: VLCStyle.duration_humanMoment
            }
        }

        MLDragItem {
            id: dragItem

            view: view

            indexes: indexesFlat ? view.selectionModel.selectedIndexesFlat
                                 : view.selectionModel.selectedIndexes
            indexesFlat: !!view.selectionModel.selectedIndexesFlat

            coverRole: "thumbnail"

            defaultCover: root._placeHolder
        }


        PlaylistMediaContextMenu {
            id: contextMenu

            model: root.model
            ctx: MainCtx

           function tableView_popup(index, selectedIndexes, globalPos) {
               popup(selectedIndexes, globalPos)
           }
        }

        PlaylistMedia
        {
            id: view

            // Settings

            anchors.fill: parent

            focus: (model.count !== 0)

            model: root.model

            dragItem: root.dragItem

            rowContextMenu: contextMenu

            isMusic: root.isMusic

            displayMarginBeginning: root.displayMarginBeginning
            displayMarginEnd: root.displayMarginEnd
            fadingEdge.enableBeginningFade: root.enableBeginningFade
            fadingEdge.enableEndFade: root.enableEndFade

            Navigation.parentItem: root

            Navigation.upItem: root.header

            Navigation.cancelAction: function () {
                if (view.currentIndex <= 0) {
                    root.Navigation.defaultNavigationCancel()
                } else {
                    positionViewAtIndex(0, ItemView.Contain)

                    setCurrentItem(0)
                }
            }

            // Events

            onRightClick: (_,_,globalMousePos) => {
                contextMenu.popup(selectionModel.selectedRows(), globalMousePos)
            }

            // Keys

            Keys.onDeletePressed: onDelete()
        }

        Widgets.EmptyLabelButton {
            anchors.centerIn: parent

            visible: !model.loading && (model.count <= 0)

            focus: visible

            text: qsTr("No media found")

            cover: root._placeHolder

            Navigation.parentItem: root
        }
    }
}
