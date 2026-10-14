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
    property real dragAreaHeight: parent ? parent.height - dragYMin : 0
    property bool queueExpanded: false
    readonly property bool lightTheme: !VLCStyle.palette.isDark

    function keepInBounds() {
        if (!video || !video.freelyPositioned)
            return
        x = Math.max(dragXMin, Math.min(dragXMax, x))
        y = Math.max(dragYMin, Math.min(dragYMax, y))
    }
    onDragXMinChanged: keepInBounds()
    onDragXMaxChanged: keepInBounds()
    onDragYMinChanged: keepInBounds()
    onDragYMaxChanged: keepInBounds()
    readonly property string folderName: {
        const parts = decodeURIComponent(Player.url.toString()).split("/")
        return parts.length > 1 ? parts[parts.length - 2] : ""
    }

    padding: VLCStyle.dp(8, VLCStyle.scale)
    implicitWidth: VLCStyle.dp(390, VLCStyle.scale)
    readonly property real baseHeight: topPadding + bottomPadding +
        video.height + VLCStyle.dp(6, VLCStyle.scale) + seek.height +
        VLCStyle.dp(24, VLCStyle.scale) + titleLabel.height +
        VLCStyle.dp(18, VLCStyle.scale) + details.height
    implicitHeight: baseHeight + (queueExpanded ? queueArea.height + VLCStyle.dp(6, VLCStyle.scale) : 0)

    background: Rectangle {
        color: root.lightTheme ? "#ababaa" : VLCStyle.redesign.playerControlBackground
        radius: VLCStyle.dp(14, VLCStyle.scale)
        border.color: root.lightTheme ? "#858585" : VLCStyle.redesign.separator
    }
    contentItem: Item {
        MiniPlayerQueue {
            id: queueArea
            width: parent.width
            height: Math.min(implicitHeight, Math.max(0, root.dragAreaHeight
                              - root.baseHeight - VLCStyle.dp(6, VLCStyle.scale)))
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
            height: VLCStyle.dp(14, VLCStyle.scale)
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
                color: root.lightTheme ? "#dedede" : VLCStyle.redesign.seekBackground
                radius: height / 2
                Rectangle {
                    width: Math.max(0, parent.width * seek.visualPosition)
                    height: parent.height
                    radius: parent.radius
                    color: root.lightTheme
                           ? Qt.rgba(VLCStyle.redesign.accent.r, VLCStyle.redesign.accent.g,
                                     VLCStyle.redesign.accent.b, 0.35)
                           : VLCStyle.redesign.accentBackground
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
            y: seek.y + seek.height + VLCStyle.dp(24, VLCStyle.scale)
            width: parent.width - x * 2
            height: VLCStyle.dp(24, VLCStyle.scale)
            text: Player.name
            color: root.lightTheme ? "#4d4d4d" : VLCStyle.redesign.textSecondary
            elide: Text.ElideRight
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            verticalAlignment: Text.AlignVCenter
        }

        Item {
            x: titleLabel.x
            y: titleLabel.y
            width: titleLabel.width
            height: titleLabel.height
            z: 2
            DragHandler {
                target: root
                cursorShape: Qt.DragMoveCursor
                grabPermissions: PointerHandler.CanTakeOverFromAnything
                xAxis.minimum: root.dragXMin
                xAxis.maximum: root.dragXMax
                yAxis.minimum: root.dragYMin
                yAxis.maximum: root.dragYMax
                onActiveChanged: {
                    if (active)
                        video.releaseAnchors()
                }
            }
        }

        Row {
            id: details
            x: VLCStyle.dp(6, VLCStyle.scale)
            y: titleLabel.y + titleLabel.height + VLCStyle.dp(18, VLCStyle.scale)
            width: parent.width - x * 2
            height: VLCStyle.dp(26, VLCStyle.scale)
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
                color: root.lightTheme ? "#4d4d4d" : VLCStyle.redesign.textSecondary
                elide: Text.ElideRight
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
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
                color: root.lightTheme ? "#4d4d4d" : VLCStyle.redesign.textSecondary
                elide: Text.ElideRight
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
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
