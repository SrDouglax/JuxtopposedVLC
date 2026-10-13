/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import VLC.MainInterface
import VLC.MediaLibrary
import VLC.Style

Item {
    id: root
    objectName: "privacyHistoryActions"
    implicitHeight: VLCStyle.dp(48, VLCStyle.scale)
    readonly property bool available: MainCtx.mediaLibraryAvailable
    readonly property bool dark: VLCStyle.palette.isDark

    MLRecentMediaModel {
        id: recentMedia
        ml: MediaLib
    }

    Label {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: qsTr("Clear history now")
        color: root.dark ? "#969696" : "#444444"
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    }

    Button {
        id: clearButton
        objectName: "clearRecentHistory"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: VLCStyle.dp(100, VLCStyle.scale)
        height: VLCStyle.dp(34, VLCStyle.scale)
        text: qsTr("Clear")
        enabled: root.available
        onClicked: confirmClear.open()
        background: Rectangle {
            color: root.dark ? "#1a1a1a" : "#e9e9e9"
            radius: 4
        }
        contentItem: Label {
            text: parent.text
            color: parent.enabled ? (root.dark ? "#aaaaaa" : "#444444") : "#777777"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }
    }

    Label {
        visible: !root.available
        anchors.right: clearButton.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: qsTr("Media library unavailable")
        color: "#777777"
        font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
    }

    Dialog {
        id: confirmClear
        objectName: "confirmClearRecentHistory"
        parent: root.parent
        anchors.centerIn: parent
        modal: true
        title: qsTr("Clear playback history?")
        standardButtons: Dialog.Cancel | Dialog.Ok
        onAccepted: {
            if (root.available)
                recentMedia.clearHistory()
        }
        contentItem: Label {
            text: qsTr("Recently played items will be removed from the media library.")
            wrapMode: Text.WordWrap
            color: root.dark ? "#dddddd" : "#333333"
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }
    }
}
