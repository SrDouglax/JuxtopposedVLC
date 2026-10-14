/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 or later.
 *****************************************************************************/
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.Dialogs
import VLC.MainInterface
import VLC.MediaLibrary
import VLC.Player
import VLC.Style

ColumnLayout {
    id: root
    objectName: "subtitleTracksPanel"
    spacing: VLCStyle.dp(8, VLCStyle.scale)
    property var reveal: null
    readonly property bool localMedia: Player.url.toString().startsWith("file://")

    SubtitleAssociationsDialog {
        id: associationsDialog
        parent: g_mainDisplay
    }

    Text {
        Layout.fillWidth: true
        text: qsTr("Embedded tracks")
        color: VLCStyle.redesign.textMuted
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    }

    ActionButton {
        objectName: "subtitleOffButton"
        Layout.fillWidth: true
        text: qsTr("Off")
        checked: {
            for (let i = 0; i < Player.subtitleTracks.count; ++i)
                if (Player.subtitleTracks.data(Player.subtitleTracks.index(i, 0), Qt.CheckStateRole))
                    return false
            return true
        }
        onClicked: {
            for (let i = 0; i < Player.subtitleTracks.count; ++i) {
                const index = Player.subtitleTracks.index(i, 0)
                if (Player.subtitleTracks.data(index, Qt.CheckStateRole))
                    Player.subtitleTracks.setData(index, false, Qt.CheckStateRole)
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: Player.subtitleTracks.count === 0
        text: qsTr("No subtitle tracks in this media")
        color: VLCStyle.redesign.textMuted
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
        wrapMode: Text.WordWrap
    }

    Repeater {
        model: Player.subtitleTracks
        delegate: ActionButton {
            objectName: "subtitleTrack" + index
            Layout.fillWidth: true
            text: model.display
            checked: model.checked
            onClicked: model.checked = !model.checked
        }
    }

    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: VLCStyle.redesign.separator }

    ActionButton {
        objectName: "addSubtitleButton"
        Layout.fillWidth: true
        text: qsTr("Load subtitle for playback…")
        onClicked: DialogsProvider.loadSubtitlesFile()
    }

    ActionButton {
        objectName: "associateSubtitleButton"
        Layout.fillWidth: true
        text: qsTr("Add subtitles to library…")
        enabled: root.localMedia && MainCtx.mediaLibraryAvailable
        onClicked: associationsDialog.openForUrl(Player.url)
    }

    Text {
        Layout.fillWidth: true
        visible: !root.localMedia || !MainCtx.mediaLibraryAvailable
        text: qsTr("Library association needs a local media file and media library.")
        color: VLCStyle.redesign.textMuted
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
        wrapMode: Text.WordWrap
    }

    SubtitleSyncTimeline {
        Layout.fillWidth: true
        presets: g_mainDisplay.subtitleSeriesPreset
        reveal: root.reveal
    }

    component ActionButton: T.Button {
        implicitHeight: VLCStyle.dp(40, VLCStyle.scale)
        checkable: false
        focusPolicy: Qt.StrongFocus
        onActiveFocusChanged: if (activeFocus && root.reveal) root.reveal(this)
        background: Rectangle {
            color: parent.checked ? VLCStyle.redesign.accentBackground
                 : parent.hovered || parent.activeFocus ? VLCStyle.redesign.controlHoverBackground : "transparent"
            border.width: VLCStyle.dp(1, VLCStyle.scale)
            border.color: parent.activeFocus ? VLCStyle.redesign.focusColor : VLCStyle.redesign.border
            radius: VLCStyle.dp(4, VLCStyle.scale)
        }
        contentItem: Item {
            Image {
                anchors.left: parent.left
                anchors.leftMargin: VLCStyle.dp(12, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                source: "qrc:///redesign/track-check-active.png"
                visible: parent.parent.checked
                width: VLCStyle.dp(24, VLCStyle.scale)
                height: width
            }
            Text {
                anchors.left: parent.left
                anchors.leftMargin: parent.parent.checked
                                    ? VLCStyle.dp(40, VLCStyle.scale)
                                    : VLCStyle.dp(12, VLCStyle.scale)
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: parent.parent.text
                color: parent.parent.checked ? VLCStyle.redesign.accent : VLCStyle.redesign.textPrimary
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                elide: Text.ElideRight
            }
        }
    }
}
