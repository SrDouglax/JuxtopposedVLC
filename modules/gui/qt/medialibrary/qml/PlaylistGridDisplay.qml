/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *****************************************************************************/
import QtQuick
import QtQml.Models

import VLC.MediaLibrary
import VLC.Widgets as Widgets
import VLC.MainInterface
import VLC.Style

Widgets.ExpandGridItemView {
    id: gridView

    required property var host

    //-------------------------------------------------------------------------------------
    // Settings

    basePictureWidth: host.isMusic ? VLCStyle.gridCover_music_width
                                   : VLCStyle.dp(316, VLCStyle.scale)
    basePictureHeight: host.isMusic ? VLCStyle.gridCover_music_height
                                    : VLCStyle.dp(178, VLCStyle.scale)
    horizontalSpacing: VLCStyle.dp(20, VLCStyle.scale)
    verticalSpacing: VLCStyle.dp(40, VLCStyle.scale)
    titleTopMargin: VLCStyle.dp(20, VLCStyle.scale)

    model: host.model

    selectionModel: host.selectionModel

    headerDelegate: host.header

    displayMarginBeginning: host.displayMarginBeginning
    displayMarginEnd: host.displayMarginEnd

    Navigation.parentItem: host

    delegate: VideoGridItem {
        //---------------------------------------------------------------------------------
        // Properties

        property var model: ({})

        property int index: -1

        //---------------------------------------------------------------------------------
        // Settings

        width: gridView.cellWidth;
        height: gridView.cellHeight;

        pictureWidth : gridView.maxPictureWidth
        pictureHeight: gridView.maxPictureHeight
        pictureRadius: VLCStyle.dp(12, VLCStyle.scale)
        titleFontPixelSize: VLCStyle.dp(16, VLCStyle.scale)

        title: (model.name) ? model.name
                            : qsTr("Unknown title")

        labels: [
            (function () {
                const labels = []
                if (model.nb_audio > 0)
                    labels.push(qsTr("%1 Track", "%1 Tracks", model.nb_audio).arg(model.nb_audio))
                if (model.nb_video > 0)
                    labels.push(qsTr("%1 Video", "%1 Videos", model.nb_video).arg(model.nb_video))
                if (model.nb_unknown > 0)
                    labels.push(qsTr("%1 Other", "%1 Other", model.nb_unknown).arg(model.nb_unknown))

                return labels.join("\n")
            })()
        ]

        dragItem: host.dragItemPlaylist


        //---------------------------------------------------------------------------------
        // Events

        onItemClicked: (modifier, select) => { gridView.leftClickOnItem(modifier, index, select) }

        onItemDoubleClicked: host.showList(model, Qt.MouseFocusReason)

        onPlayClicked: {
            if (model.id) {
                MediaLib.addAndPlay(model.id)
                MainCtx.playerView = true
            }
        }

        onContextMenuButtonClicked: (_, globalMousePos) => {
            gridView.rightClickOnItem(index);

            host.contextMenu.popup(selectionModel.selectedRows(), globalMousePos);
        }

        //---------------------------------------------------------------------------------
        // Animations

        Behavior on opacity {
            OpacityAnimator {
                duration: VLCStyle.duration_short
            }
        }

        DropArea {
            anchors.fill: parent

            onEntered: function(drag) {
                host._adjustDragAccepted(drag)
            }

            onDropped: function(drop) {
                MainCtx.setCursor(gridView, Qt.BusyCursor)
                host._dropAction(drop, index).then(() => {
                    if (gridView)
                        MainCtx.unsetCursor(gridView)
                })
            }
        }
    }

    //-------------------------------------------------------------------------------------
    // Events

    // NOTE: Define the initial position and selection. This is done on activeFocus rather
    //       than Component.onCompleted because selectionModel.selectedGroup update itself
    //       after this event.
    onActiveFocusChanged: {
        if (activeFocus == false || model.count === 0 || selectionModel.hasSelection)
            return;

        selectionModel.select(model.index(0,0), ItemSelectionModel.ClearAndSelect)
    }

    onActionAtIndex: host._actionAtIndex()

}
