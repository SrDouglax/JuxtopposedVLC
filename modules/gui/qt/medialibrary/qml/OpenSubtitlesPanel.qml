/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls
import VLC.MediaLibrary
import VLC.Style
import VLC.Widgets as Widgets

ColumnLayout {
    id: root
    required property var associations
    required property Item searchHost
    property int selectedIndex: -1
    property bool pendingSave: false
    property bool downloadIntent: false
    readonly property bool busy: service.busy || associations.busy
    readonly property bool readyToSave: selectedIndex >= 0 && selectedIndex < service.results.length
        && !busy
    signal downloadReady()
    spacing: VLCStyle.dp(10, VLCStyle.scale)

    function clearCredentials() { pendingSave = false; downloadIntent = false; account.clearCredentials(); service.cancel(); selectedIndex = -1; account.close() }
    function search() {
        if (!queryField.text.trim().length || busy) return
        downloadIntent = false
        if (!account.apiKey.trim().length) { account.downloadRequired = false; account.open(); return }
        selectedIndex = -1
        service.search(queryField.text, languagePicker.currentValue, account.apiKey)
    }
    function saveSelection() {
        if (!readyToSave) return
        downloadIntent = true
        if (!account.apiKey.trim().length || !account.username.trim().length || !account.password.length) {
            account.downloadRequired = true
            account.open()
            return
        }
        service.download(selectedIndex, account.apiKey, account.username, account.password)
    }
    MLOpenSubtitles {
        id: service
        onFileReady: (url, filename) => {
            root.pendingSave = true
            root.associations.addLinkWithName(url, filename)
        }
    }
    Connections {
        target: root.associations
        function onLinkReady() {
            if (!root.pendingSave) return
            root.pendingSave = false
            root.downloadReady()
        }
        function onChanged() {
            if (!root.associations.busy && root.associations.error.length) root.pendingSave = false
        }
    }
    OpenSubtitlesAccount {
        id: account
        parent: root.Window.window ? root.Window.window.contentItem : root
        onAccepted: if (root.downloadIntent) root.saveSelection(); else root.search()
    }
    RowLayout {
        parent: root.searchHost
        anchors.fill: parent
        visible: root.visible
        spacing: VLCStyle.dp(10, VLCStyle.scale)
        Controls.TextField {
            id: queryField
            objectName: "openSubtitlesQuery"
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
            placeholderText: qsTr("Title or episode")
            placeholderTextColor: VLCStyle.redesign.textMuted
            color: VLCStyle.redesign.color("#d0d0d0", "#2e2e2e")
            selectByMouse: true
            leftPadding: VLCStyle.dp(36, VLCStyle.scale)
            rightPadding: VLCStyle.dp(36, VLCStyle.scale)
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            onAccepted: if (root.downloadIntent) root.saveSelection(); else root.search()
            background: Rectangle { color: VLCStyle.redesign.color("#151515", "#dedede"); radius: 4 }
            Controls.Button {
                objectName: "openSubtitlesSearchButton"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: VLCStyle.dp(34, VLCStyle.scale)
                height: width
                enabled: !root.busy
                Accessible.name: qsTr("Search OpenSubtitles")
                onClicked: root.search()
                background: Item {}
                contentItem: Image { source: "qrc:///redesign/icons/search/default.png"; fillMode: Image.PreserveAspectFit; sourceSize.width: 18 }
            }
            Controls.Button {
                objectName: "openSubtitlesAccountButton"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: VLCStyle.dp(32, VLCStyle.scale)
                height: width
                Accessible.name: qsTr("OpenSubtitles account")
                onClicked: account.open()
                background: Item {}
                contentItem: Image { source: "qrc:///redesign/player-settings.svg"; fillMode: Image.PreserveAspectFit; sourceSize.width: 18 }
            }
        }
        Widgets.ComboBoxExt {
            id: languagePicker
            objectName: "openSubtitlesLanguage"
            Layout.preferredWidth: VLCStyle.dp(200, VLCStyle.scale)
            Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
            enabled: !root.busy
            textRole: "label"
            valueRole: "code"
            model: [
                {label: qsTr("English"), code: "en"}, {label: qsTr("Portuguese"), code: "pt"},
                {label: qsTr("Spanish"), code: "es"}, {label: qsTr("French"), code: "fr"},
                {label: qsTr("German"), code: "de"}, {label: qsTr("Japanese"), code: "ja"},
                {label: qsTr("Dutch"), code: "nl"}, {label: qsTr("Italian"), code: "it"}
            ]
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            background: Rectangle { color: VLCStyle.redesign.color("#151515", "#dedede"); radius: 4 }
            contentItem: Controls.Label { text: languagePicker.displayText; color: VLCStyle.redesign.textMuted; font: languagePicker.font; leftPadding: 12; verticalAlignment: Text.AlignVCenter }
        }
    }
    Controls.BusyIndicator { Layout.alignment: Qt.AlignHCenter; visible: root.busy; running: visible }
    Controls.Label {
        Layout.fillWidth: true
        visible: service.error.length > 0 || (!root.busy && service.results.length === 0)
        text: service.error.length > 0 ? service.error : qsTr("Search OpenSubtitles to see available files.")
        color: service.error.length > 0 ? VLCStyle.redesign.accent : VLCStyle.redesign.textMuted
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
            height: VLCStyle.dp(36, VLCStyle.scale)
            highlighted: root.selectedIndex === index
            onClicked: root.selectedIndex = highlighted ? -1 : index
            background: Rectangle {
                color: parent.highlighted ? VLCStyle.redesign.color("#090909", "#ababaa") : parent.hovered ? VLCStyle.redesign.color("#191919", "#dedede") : "transparent"
                radius: VLCStyle.dp(4, VLCStyle.scale)
            }
            contentItem: RowLayout {
                spacing: VLCStyle.dp(16, VLCStyle.scale)
                Image { Layout.preferredWidth: 24; Layout.preferredHeight: 24; source: "qrc:///redesign/subtitle-file.png" }
                Controls.Label {
                    Layout.fillWidth: true
                    text: modelData.filename
                    color: VLCStyle.redesign.textMuted
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    elide: Text.ElideMiddle
                }
                Controls.Label { text: root.selectedIndex === index ? "✓" : ""; color: VLCStyle.redesign.accent; font.pixelSize: VLCStyle.dp(20, VLCStyle.scale); Layout.preferredWidth: 24 }
            }
        }
    }
}
