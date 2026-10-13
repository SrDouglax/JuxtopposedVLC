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

    // Bottom rounding is provided by the progress bar if it is visible:
    mediaCover.radiusBottomLeft: progressBar.visible ? 0.0 : mediaCover.radius
    mediaCover.radiusBottomRight: progressBar.visible ? 0.0 : mediaCover.radius

    selectedShadow.height: selectedShadow.implicitHeight + (progressBar.visible ? progressBar.height : 0.0)
    unselectedShadow.height: unselectedShadow.implicitHeight + (progressBar.visible ? progressBar.height : 0.0)

    Widgets.VideoProgressBar {
        id: progressBar

        parent: root.mediaCover

        // If the background color of the image is opaque (which should be
        // the case by default), we can place the progress bar beneath the
        // thumbnail and disable clipping because the top part would not be
        // exposed. Note that the top part is still going to be painted, as
        // long as the image is not opaque which is the expected case since
        // SDF-based round images always have transparent parts which needs
        // blending. If the image is not rounded and its blending is disabled,
        // the top part of the bar is not going to be painted, thanks to depth
        // testing. Furthermore, fragment shader may not even be executed for
        // the top part that are obscured by the opaque image, provided that
        // early depth test is applicable. In any case, since bottom radii
        // are 0.0 and background color is opaque, the top part (if painted)
        // will not be exposed to the user.
        z: (root.mediaCover.color.a > (1.0 - Number.EPSILON)) ? -0.1 : 0.0
        clip: (z >= 0.0)

        anchors {
            top: parent.bottom
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

        // Software Qt Quick cannot run the image rounding shader. Paint only
        // the four exterior corners, leaving the actual thumbnail unchanged.
        Canvas {
            anchors.fill: parent
            visible: root.GraphicsInfo.shaderType !== GraphicsInfo.RhiShader
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = VLCStyle.redesign.windowBackground
                const corners = [ [0, 0, 0, root.mediaCover.radiusTopLeft],
                                  [width, 0, 90, root.mediaCover.radiusTopRight],
                                  [width, height, 180, root.mediaCover.radiusBottomRight],
                                  [0, height, 270, root.mediaCover.radiusBottomLeft] ]
                for (const corner of corners) {
                    const r = Math.min(corner[3], width / 2, height / 2)
                    ctx.save()
                    ctx.translate(corner[0], corner[1])
                    ctx.rotate(corner[2] * Math.PI / 180)
                    ctx.beginPath()
                    ctx.moveTo(0, 0)
                    ctx.lineTo(r, 0)
                    ctx.arcTo(0, 0, 0, r, r)
                    ctx.closePath()
                    ctx.fill()
                    ctx.restore()
                }
            }
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
