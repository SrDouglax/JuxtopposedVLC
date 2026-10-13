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

Dialog {
    id: root

    title: qsTr("Add subtitles")
    modal: true
    closePolicy: associations.busy ? Popup.NoAutoClose : Popup.CloseOnEscape
    width: Math.min(620, parent ? parent.width - 32 : 620)
    height: Math.min(460, parent ? parent.height - 32 : 460)
    anchors.centerIn: parent

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
        }

        Button {
            text: qsTr("Choose subtitle files…")
            enabled: !associations.busy
            onClicked: associations.chooseFiles()
        }

        Label {
            Layout.fillWidth: true
            visible: associations.destinations.length === 0 && !associations.busy
            text: qsTr("Select a media file, folder, or playlist to add subtitles.")
            wrapMode: Text.WordWrap
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
                        }
                        Label {
                            Layout.fillWidth: true
                            visible: modelData.issue.length > 0
                            text: modelData.issue
                            wrapMode: Text.WordWrap
                        }
                    }

                    ComboBox {
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
        }
    }

    footer: RowLayout {
        spacing: 8
        Item { Layout.fillWidth: true }
        Button {
            text: qsTr("Cancel")
            enabled: !associations.busy
            onClicked: root.reject()
        }
        Button {
            text: qsTr("Save associations")
            enabled: !associations.busy && associations.sources.length > 0
            onClicked: associations.save()
        }
    }
}
