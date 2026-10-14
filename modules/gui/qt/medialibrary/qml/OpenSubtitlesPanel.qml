/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 or later.
 *****************************************************************************/
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls

import VLC.MediaLibrary
import VLC.Style

ColumnLayout {
    id: root
    required property var associations
    property int selectedIndex: -1
    readonly property bool busy: service.busy
    signal downloadReady()
    spacing: VLCStyle.dp(10, VLCStyle.scale)

    function clearCredentials() {
        apiKeyField.clear()
        usernameField.clear()
        passwordField.clear()
        service.cancel()
        selectedIndex = -1
    }

    MLOpenSubtitles {
        id: service
        onFileReady: (url, filename) => {
            root.associations.addLinkWithName(url, filename)
            root.downloadReady()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: VLCStyle.dp(8, VLCStyle.scale)
        Controls.TextField {
            id: queryField
            objectName: "openSubtitlesQuery"
            Layout.fillWidth: true
            placeholderText: qsTr("Title or episode")
            color: "#d0d0d0"
            selectByMouse: true
            onAccepted: if (searchButton.enabled) searchButton.clicked()
            background: Rectangle { color: "#151515"; radius: 4 }
        }
        Controls.TextField {
            id: languageField
            objectName: "openSubtitlesLanguage"
            Layout.preferredWidth: VLCStyle.dp(110, VLCStyle.scale)
            placeholderText: qsTr("Language code")
            text: "en"
            color: "#d0d0d0"
            selectByMouse: true
            background: Rectangle { color: "#151515"; radius: 4 }
        }
        Controls.Button {
            id: searchButton
            objectName: "openSubtitlesSearchButton"
            text: qsTr("Search")
            enabled: !service.busy && queryField.text.trim().length > 0 && apiKeyField.text.trim().length > 0
            onClicked: {
                root.selectedIndex = -1
                service.search(queryField.text, languageField.text, apiKeyField.text)
            }
            background: Rectangle {
                color: parent.hovered ? "#252525" : "#151515"
                radius: VLCStyle.dp(4, VLCStyle.scale)
            }
            contentItem: Controls.Label {
                text: parent.text
                color: parent.enabled ? "#d0d0d0" : "#676767"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: VLCStyle.dp(8, VLCStyle.scale)
        Controls.TextField {
            id: apiKeyField
            objectName: "openSubtitlesApiKey"
            Layout.fillWidth: true
            placeholderText: qsTr("OpenSubtitles API key")
            echoMode: TextInput.Password
            color: "#d0d0d0"
            selectByMouse: true
            background: Rectangle { color: "#151515"; radius: 4 }
        }
        Controls.TextField {
            id: usernameField
            objectName: "openSubtitlesUsername"
            Layout.fillWidth: true
            placeholderText: qsTr("Username")
            color: "#d0d0d0"
            selectByMouse: true
            background: Rectangle { color: "#151515"; radius: 4 }
        }
        Controls.TextField {
            id: passwordField
            objectName: "openSubtitlesPassword"
            Layout.fillWidth: true
            placeholderText: qsTr("Password")
            echoMode: TextInput.Password
            color: "#d0d0d0"
            selectByMouse: true
            background: Rectangle { color: "#151515"; radius: 4 }
        }
    }

    Controls.Label {
        Layout.fillWidth: true
        text: qsTr("Your credentials are used for this session only. Downloads use your OpenSubtitles quota.")
        color: "#8f8f8f"
        font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
        wrapMode: Text.WordWrap
    }

    Controls.BusyIndicator {
        Layout.alignment: Qt.AlignHCenter
        visible: service.busy
        running: visible
    }

    Controls.Label {
        Layout.fillWidth: true
        visible: service.error.length > 0 || (!service.busy && service.results.length === 0)
        text: service.error.length > 0 ? service.error : qsTr("Search OpenSubtitles to see available files.")
        color: service.error.length > 0 ? "#d37918" : "#8f8f8f"
        font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
        wrapMode: Text.WordWrap
    }

    ListView {
        id: results
        objectName: "openSubtitlesResults"
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: service.results
        spacing: VLCStyle.dp(4, VLCStyle.scale)
        delegate: Controls.ItemDelegate {
            required property int index
            required property var modelData
            width: results.width
            height: VLCStyle.dp(46, VLCStyle.scale)
            highlighted: root.selectedIndex === index
            text: modelData.filename + " · " + modelData.language
            onClicked: root.selectedIndex = index
            background: Rectangle {
                color: parent.highlighted ? "#252525" : parent.hovered ? "#1b1b1b" : "transparent"
                radius: VLCStyle.dp(4, VLCStyle.scale)
            }
            contentItem: Controls.Label {
                text: parent.text
                color: "#d0d0d0"
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideMiddle
            }
        }
    }

    Controls.Button {
        objectName: "openSubtitlesDownloadButton"
        Layout.alignment: Qt.AlignRight
        text: qsTr("Download selected")
        enabled: root.selectedIndex >= 0 && !service.busy && !root.associations.busy
        onClicked: service.download(root.selectedIndex, apiKeyField.text,
                                    usernameField.text, passwordField.text)
        background: Rectangle {
            color: parent.hovered ? "#633000" : "#402000"
            radius: VLCStyle.dp(4, VLCStyle.scale)
        }
        contentItem: Controls.Label {
            text: parent.text
            color: parent.enabled ? VLCStyle.redesign.accent : "#676767"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
