/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import VLC.Style

Column {
    id: root
    property var settingsModel
    property bool available: false
    property bool selected: false
    property int revision: 0
    spacing: 0

    function begin() {
        available = settingsModel && settingsModel.audioscrobblerAvailable()
        selected = available && settingsModel.audioscrobblerEnabled()
        ++revision
    }
    Connections {
        target: root.settingsModel
        function onDataChanged() { ++root.revision }
        function onModelReset() { ++root.revision }
    }
    SettingsOptionRow {
        objectName: "settingsLastfmEnabled"
        width: parent.width
        settingKey: "lastfm-enabled"
        label: qsTr("Submit played tracks to Last.fm")
        help: root.available ? qsTr("Changes take effect after restarting VLC")
                             : qsTr("This VLC build does not provide Last.fm")
        settingType: "boolean"
        settingValue: root.selected
        enabled: root.available
        onCommit: value => {
            if (root.settingsModel.setAudioscrobblerEnabled(value)) root.selected = value
        }
    }
    Repeater {
        model: [
            { label: qsTr("Last.fm username"), key: "lastfm-username" },
            { label: qsTr("Last.fm password"), key: "lastfm-password" },
            { label: qsTr("Last.fm submission URL"), key: "scrobbler-url" }
        ]
        SettingsOptionRow {
            required property var modelData
            width: root.width
            objectName: "settings_" + modelData.key
            settingKey: modelData.key
            label: modelData.label
            settingType: "string"
            editorKind: modelData.key === "lastfm-password" ? "password" : ""
            settingValue: { root.revision; return root.settingsModel.valueFor(modelData.key) || "" }
            enabled: root.available
            onCommit: value => root.settingsModel.setValue(modelData.key, value)
        }
    }
}
