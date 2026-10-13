/*
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify it
 * under the GNU General Public License, version 2 or any later version.
 * See the COPYING file for the license and warranty disclaimer.
 */
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Playlist
import VLC.Player
import VLC.Style
import VLC.Widgets as Widgets

T.Control {
    id: root
    property real dragXMin: 0
    property real dragXMax: 0
    property real dragYMin: 0
    property real dragYMax: 0
    property int metadataHeight: VLCStyle.dp(80, VLCStyle.scale)
    readonly property string folderName: {
        const parts = decodeURIComponent(Player.url.toString()).split("/")
        return parts.length > 1 ? parts[parts.length - 2] : ""
    }
    padding: VLCStyle.dp(8, VLCStyle.scale)
    implicitWidth: VLCStyle.dp(391, VLCStyle.scale)
    implicitHeight: video.height + seek.height + VLCStyle.dp(24, VLCStyle.scale) + metadataHeight + padding * 2
    Accessible.name: qsTr("Mini player")
    objectName: "libraryMiniPlayer"

    background: Rectangle {
        color: VLCStyle.redesign.playerControlBackground
        radius: VLCStyle.dp(14, VLCStyle.scale)
        border.color: VLCStyle.redesign.separator
    }
    contentItem: Item {
        PIPPlayer {
            id: video
            width: parent.width
            height: width * 9 / 16
            dragTarget: root
            dragXMin: root.dragXMin
            dragXMax: root.dragXMax
            dragYMin: root.dragYMin
            dragYMax: root.dragYMax
            hideControls: false
        }
        T.Slider {
            id: seek
            anchors.top: video.bottom
            anchors.topMargin: VLCStyle.dp(4, VLCStyle.scale)
            width: parent.width
            height: VLCStyle.dp(16, VLCStyle.scale)
            padding: 0
            from: 0
            to: 1
            value: Player.position
            enabled: Player.seekable
            Accessible.name: qsTr("Playback position")
            onMoved: Player.position = value
            Keys.onLeftPressed: Player.jumpBwd()
            Keys.onRightPressed: Player.jumpFwd()
            background: Rectangle {
                color: VLCStyle.redesign.seekBackground
                radius: VLCStyle.redesign.controlRadius
                Rectangle {
                    x: 2
                    y: 2
                    height: parent.height - 4
                    width: Math.max(0, (parent.width - 4) * seek.visualPosition)
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    color: VLCStyle.redesign.accentBackground
                }
            }
            handle: Rectangle {
                width: VLCStyle.dp(4, VLCStyle.scale)
                height: seek.height - 4
                x: Math.max(2, Math.min(seek.width - width - 2, seek.visualPosition * seek.width))
                y: 2
                radius: 2
                color: VLCStyle.redesign.accent
                visible: seek.hovered || seek.pressed || seek.visualFocus
            }
        }
        ColumnLayout {
            anchors.top: seek.bottom
            anchors.topMargin: VLCStyle.dp(20, VLCStyle.scale)
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: VLCStyle.dp(8, VLCStyle.scale)
            anchors.rightMargin: VLCStyle.dp(8, VLCStyle.scale)
            spacing: VLCStyle.dp(14, VLCStyle.scale)
            Widgets.LabelExt {
                Layout.fillWidth: true
                text: Player.name
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
                font.weight: Font.Normal
                color: VLCStyle.redesign.textSecondary
                elide: Text.ElideRight
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: VLCStyle.dp(8, VLCStyle.scale)
                Image {
                    source: "qrc:///redesign/folder.svg"
                    mirror: true
                    Layout.preferredWidth: VLCStyle.redesign.iconSize
                    Layout.preferredHeight: VLCStyle.redesign.iconSize
                    sourceSize: Qt.size(24, 24)
                }
                Widgets.LabelExt {
                    text: root.folderName
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
                    color: VLCStyle.redesign.textSecondary
                }
                Image {
                    visible: Player.artist.length > 0
                    source: "qrc:///redesign/artist.svg"
                    Layout.preferredWidth: VLCStyle.redesign.iconSize
                    Layout.preferredHeight: VLCStyle.redesign.iconSize
                    sourceSize: Qt.size(24, 24)
                }
                Widgets.LabelExt {
                    visible: Player.artist.length > 0
                    text: Player.artist
                    Layout.maximumWidth: root.width / 3
                    elide: Text.ElideRight
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
                    color: VLCStyle.redesign.textSecondary
                }
                Widgets.IconToolButton {
                    text: VLCIcons.playlist
                    description: qsTr("Show play queue")
                    width: VLCStyle.dp(30, VLCStyle.scale)
                    height: VLCStyle.dp(30, VLCStyle.scale)
                    backgroundColor: hovered ? VLCStyle.redesign.controlHoverBackground : "transparent"
                    onClicked: MainCtx.playqueuePanel.visible = !MainCtx.playqueuePanel.visible
                    contentItem: Image {
                        source: "qrc:///redesign/mini-queue.svg"
                        sourceSize: Qt.size(24, 24)
                        fillMode: Image.PreserveAspectFit
                    }
                }
            }
        }
    }
}
