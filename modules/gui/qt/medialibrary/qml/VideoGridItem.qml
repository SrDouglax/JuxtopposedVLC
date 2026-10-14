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

import VLC.MainInterface
import VLC.MediaLibrary

import VLC.Widgets as Widgets
import VLC.Util
import VLC.Style

Widgets.GridItem {
    id: root

    property bool showNewIndicator: false
    property bool redesignTitle: false
    
    property var labels

    function play() {
        if ( model.id !== undefined ) {
            MediaLib.addAndPlay( model.id )
            MainCtx.playerView = true
        }
    }

    image: model.thumbnail || ""
    fallbackImage: VLCStyle.noArtVideoCover
    fillMode: Image.PreserveAspectCrop

    title: model.title || qsTr("Unknown title")
    subtitle: model?.duration?.formatHMS() ?? ""
    pictureWidth: VLCStyle.gridCover_video_width
    pictureHeight: VLCStyle.gridCover_video_height
    titleFontFamily: redesignTitle ? VLCStyle.redesign.fontFamily : ""
    titleFontWeight: redesignTitle ? Font.Normal : Font.DemiBold
    titleColor: redesignTitle
                ? VLCStyle.redesign.color("#6B6B6B", colorContext.fg.primary,
                                          colorContext.palette?.isDark ?? true)
                : colorContext.fg.primary
    selectedTitleColor: redesignTitle
                        ? VLCStyle.redesign.color(VLCStyle.redesign.textSecondary,
                                                  colorContext.fg.highlight,
                                                  colorContext.palette?.isDark ?? true)
                        : colorContext.fg.highlight

    Widgets.VideoProgressBar {
        id: progressBar

        parent: root.mediaCover

        // Overlay the bottom of the thumbnail so both shapes share one edge.
        // Appending the strip below a square image leaves black corner seams.
        z: 1
        clip: true

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        visible: (model.progress > 0)

        radius: root.pictureRadius
        value: Helpers.clamp(model.progress !== undefined ? model.progress : 0, 0, 1)
    }

    pictureOverlay: Item {
        implicitWidth: root.pictureWidth
        implicitHeight: root.pictureHeight

        Rectangle {
            anchors.fill: parent
            color: "#33000000"
            radius: root.pictureRadius
            visible: VLCStyle.palette.isDark
        }

        Widgets.ScaledImage {
            id: image

            anchors.right: parent.right
            anchors.top: parent.top

            width: VLCStyle.gridItem_newIndicator
            height: width

            visible: root.showNewIndicator

            source: VLCStyle.newIndicator
        }

        Widgets.VideoQualityLabels {
            anchors {
                top: parent.top
                right: parent.right
                topMargin: VLCStyle.margin_xxsmall
                leftMargin: VLCStyle.margin_xxsmall
                rightMargin: VLCStyle.margin_xxsmall
            }

            labels: root.labels
        }
    }

    onPlayClicked: root.play()
}
