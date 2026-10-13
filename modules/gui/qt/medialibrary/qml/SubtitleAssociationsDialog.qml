/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *****************************************************************************/
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import VLC.MediaLibrary
import VLC.Style

Dialog {
    id: root
    objectName: "subtitleAssociationsDialog"

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    title: qsTr("Add subtitles")
    modal: true
    closePolicy: associations.busy ? Popup.NoAutoClose : Popup.CloseOnEscape
    width: Math.min(VLCStyle.dp(620, VLCStyle.scale),
                    parent ? parent.width - VLCStyle.margin_normal * 2 : 620)
    height: Math.min(VLCStyle.dp(460, VLCStyle.scale),
                     parent ? parent.height - VLCStyle.margin_normal * 2 : 460)
    anchors.centerIn: parent
    padding: VLCStyle.margin_normal
    font.pixelSize: VLCStyle.fontSize_normal

    background: Rectangle {
        color: theme.bg.primary
        border.color: theme.border
        radius: VLCStyle.dp(12, VLCStyle.scale)
    }

    function openFor(itemId) {
        associations.open(itemId)
        open()
    }

    function openForUrl(url) {
        associations.openUrl(url)
        open()
    }

    onRejected: associations.cancel()
    onClosed: associations.cancel()

    MLSubtitleAssociations {
        id: associations
        ml: MediaLib
        onSaved: root.close()
    }

    contentItem: ColumnLayout {
        spacing: 12

        Label {
            Layout.fillWidth: true
            text: qsTr("Choose subtitle files, then check the media assigned to each one.")
            wrapMode: Text.WordWrap
            color: theme.fg.primary
        }

        Button {
            objectName: "subtitleChooseFilesButton"
            text: qsTr("Choose subtitle files…")
            enabled: !associations.busy
            onClicked: associations.chooseFiles()
        }

        Label {
            Layout.fillWidth: true
            visible: associations.destinations.length === 0 && !associations.busy
            text: qsTr("Select a media file, folder, or playlist to add subtitles.")
            wrapMode: Text.WordWrap
            color: theme.fg.secondary
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                model: associations.sources
                spacing: 8
                delegate: RowLayout {
                    required property int index
                    required property var modelData
                    width: ListView.view.width
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        Label {
                            Layout.fillWidth: true
                            text: modelData.label
                            elide: Text.ElideMiddle
                            color: theme.fg.primary
                        }
                        Label {
                            Layout.fillWidth: true
                            visible: modelData.issue.length > 0
                            text: modelData.issue
                            wrapMode: Text.WordWrap
                            color: theme.fg.secondary
                        }
                    }

                    ComboBox {
                        objectName: "subtitleDestinationSelector"
                        Layout.preferredWidth: 220
                        model: associations.destinations
                        textRole: "label"
                        currentIndex: modelData.destination
                        enabled: !associations.busy
                        displayText: currentIndex < 0 ? qsTr("Choose media") : currentText
                        onActivated: associations.assign(index, currentIndex)
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            visible: associations.error.length > 0
            text: associations.error
            wrapMode: Text.WordWrap
            color: theme.fg.primary
        }
    }

    footer: RowLayout {
        spacing: 8
        Item { Layout.fillWidth: true }
        Button {
            objectName: "subtitleCancelButton"
            text: qsTr("Cancel")
            enabled: !associations.busy
            onClicked: root.reject()
        }
        Button {
            objectName: "subtitleSaveButton"
            text: qsTr("Save associations")
            enabled: !associations.busy && associations.sources.length > 0
            onClicked: associations.save()
        }
    }
}
