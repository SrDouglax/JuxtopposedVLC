/*
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License, version 2 or later.
 */
import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Playlist
import VLC.Player
import VLC.Style

T.Control {
    id: root
    objectName: "libraryMiniPlayer"
    Accessible.name: qsTr("Mini player")

    property real dragXMin: 0
    property real dragXMax: 0
    property real dragYMin: 0
    property real dragYMax: 0
    property bool queueExpanded: false
    readonly property string folderName: {
        const parts = decodeURIComponent(Player.url.toString()).split("/")
        return parts.length > 1 ? parts[parts.length - 2] : ""
    }

    padding: VLCStyle.dp(8, VLCStyle.scale)
    implicitWidth: VLCStyle.dp(300, VLCStyle.scale)
    implicitHeight: topPadding + bottomPadding +
                    (queueExpanded ? queueArea.height + VLCStyle.dp(6, VLCStyle.scale) : 0) +
                    video.height + VLCStyle.dp(6, VLCStyle.scale) + seek.height +
                    VLCStyle.dp(8, VLCStyle.scale) + titleLabel.height +
                    VLCStyle.dp(4, VLCStyle.scale) + details.height

    background: Rectangle {
        color: VLCStyle.redesign.playerControlBackground
        radius: VLCStyle.dp(14, VLCStyle.scale)
        border.color: VLCStyle.redesign.separator
    }
    contentItem: Item {
        MiniPlayerQueue {
            id: queueArea
            width: parent.width
            height: implicitHeight
            visible: root.queueExpanded
        }

        PIPPlayer {
            id: video
            objectName: "miniPlayerVideo"
            y: root.queueExpanded ? queueArea.height + VLCStyle.dp(6, VLCStyle.scale) : 0
            width: parent.width
            height: width * 9 / 16
            dragTarget: root
            dragXMin: root.dragXMin
            dragXMax: root.dragXMax
            dragYMin: root.dragYMin
            dragYMax: root.dragYMax
            hideControls: false
        }

        Controls.Slider {
            id: seek
            objectName: "miniPlayerSeek"
            y: video.y + video.height + VLCStyle.dp(6, VLCStyle.scale)
            width: parent.width
            height: VLCStyle.dp(8, VLCStyle.scale)
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
                radius: height / 2
                Rectangle {
                    width: Math.max(0, parent.width * seek.visualPosition)
                    height: parent.height
                    radius: parent.radius
                    color: VLCStyle.redesign.accentBackground
                }
            }
            handle: Rectangle {
                width: VLCStyle.dp(7, VLCStyle.scale)
                height: VLCStyle.dp(7, VLCStyle.scale)
                radius: width / 2
                x: Math.max(0, Math.min(seek.width - width, seek.visualPosition * seek.width - width / 2))
                y: (seek.height - height) / 2
                color: VLCStyle.redesign.accent
                visible: seek.hovered || seek.pressed || seek.visualFocus
            }
        }

        Text {
            id: titleLabel
            x: VLCStyle.dp(6, VLCStyle.scale)
            y: seek.y + seek.height + VLCStyle.dp(8, VLCStyle.scale)
            width: parent.width - x * 2
            height: VLCStyle.dp(20, VLCStyle.scale)
            text: Player.name
            color: VLCStyle.redesign.textSecondary
            elide: Text.ElideRight
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
            verticalAlignment: Text.AlignVCenter
        }

        Row {
            id: details
            x: VLCStyle.dp(6, VLCStyle.scale)
            y: titleLabel.y + titleLabel.height + VLCStyle.dp(4, VLCStyle.scale)
            width: parent.width - x * 2
            height: VLCStyle.dp(23, VLCStyle.scale)
            spacing: VLCStyle.dp(6, VLCStyle.scale)

            Image {
                width: VLCStyle.dp(17, VLCStyle.scale)
                height: width
                anchors.verticalCenter: parent.verticalCenter
                source: "qrc:///redesign/folder.svg"
                sourceSize: Qt.size(17, 17)
            }
            Text {
                width: Math.min(70, implicitWidth)
                height: parent.height
                text: root.folderName
                color: VLCStyle.redesign.textSecondary
                elide: Text.ElideRight
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
                verticalAlignment: Text.AlignVCenter
            }
            Image {
                visible: Player.artist.length > 0
                width: visible ? VLCStyle.dp(17, VLCStyle.scale) : 0
                height: width
                anchors.verticalCenter: parent.verticalCenter
                source: "qrc:///redesign/artist.svg"
                sourceSize: Qt.size(17, 17)
            }
            Text {
                visible: Player.artist.length > 0
                width: visible ? Math.max(0, details.width - 155) : 0
                height: parent.height
                text: Player.artist
                color: VLCStyle.redesign.textSecondary
                elide: Text.ElideRight
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
                verticalAlignment: Text.AlignVCenter
            }
        }
        Controls.Button {
            id: queueButton
            objectName: "miniPlayerQueueToggle"
            x: parent.width - width - VLCStyle.dp(3, VLCStyle.scale)
            y: details.y
            width: VLCStyle.dp(24, VLCStyle.scale)
            height: details.height
            Accessible.name: root.queueExpanded ? qsTr("Hide queue") : qsTr("Show queue")
            onClicked: root.queueExpanded = !root.queueExpanded
            background: Item {}
            contentItem: Image {
                source: "qrc:///redesign/mini-queue.svg"
                sourceSize: Qt.size(20, 20)
                fillMode: Image.PreserveAspectFit
                opacity: root.queueExpanded ? 1 : 0.65
            }
        }
    }
}
