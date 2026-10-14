/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import VLC.Style

ColumnLayout {
    id: root
    property var settingsModel
    property bool available: false
    property bool selected: false
    spacing: VLCStyle.dp(8, VLCStyle.scale)

    function begin() {
        available = settingsModel && settingsModel.audioscrobblerAvailable()
        if (!available) return
        selected = settingsModel.audioscrobblerEnabled()
        if (username) username.text = String(settingsModel.valueFor("lastfm-username") || "")
        if (password) password.text = String(settingsModel.valueFor("lastfm-password") || "")
        if (submissionUrl) submissionUrl.text = String(settingsModel.valueFor("scrobbler-url") || "")
    }

    Label {
        Layout.fillWidth: true
        text: qsTr("Last.fm")
        color: VLCStyle.redesign.color("#EAEAEA", "#2e2e2e")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
    }
    Label {
        Layout.fillWidth: true
        visible: !root.available
        text: qsTr("Last.fm is unavailable in this VLC installation.")
        color: VLCStyle.redesign.color("#8F8F8F", "#7c7c7b")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    }
    RowLayout {
        Layout.fillWidth: true
        visible: root.available
        implicitHeight: VLCStyle.dp(38, VLCStyle.scale)
        Label {
            Layout.fillWidth: true
            text: qsTr("Submit played tracks to Last.fm")
            color: VLCStyle.redesign.color("#8F8F8F", "#7c7c7b")
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }
        Switch {
            id: submitSwitch
            objectName: "settingsLastfmEnabled"
            Binding on checked { when: !submitSwitch.pressed; value: root.selected }
            onClicked: {
                if (root.settingsModel.setAudioscrobblerEnabled(checked))
                    root.selected = checked
            }
            indicator: Rectangle {
                implicitWidth: VLCStyle.dp(40, VLCStyle.scale)
                implicitHeight: VLCStyle.dp(22, VLCStyle.scale)
                radius: height / 2
                color: submitSwitch.checked ? VLCStyle.redesign.accent : "#373737"
                Rectangle {
                    x: submitSwitch.checked ? parent.width - width - 3 : 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: VLCStyle.dp(16, VLCStyle.scale)
                    height: width
                    radius: width / 2
                    color: "#eaeaea"
                }
            }
        }
    }
    Repeater {
        model: [
            { label: qsTr("Last.fm username"), key: "lastfm-username" },
            { label: qsTr("Last.fm password"), key: "lastfm-password" },
            { label: qsTr("Last.fm submission URL"), key: "scrobbler-url" }
        ]
        RowLayout {
            id: fieldRow
            required property var modelData
            Layout.fillWidth: true
            visible: root.available
            implicitHeight: VLCStyle.dp(38, VLCStyle.scale)
            Label {
                Layout.fillWidth: true
                text: fieldRow.modelData.label
                color: VLCStyle.redesign.color("#8F8F8F", "#7c7c7b")
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }
            TextField {
                id: editor
                objectName: "settings_" + fieldRow.modelData.key
                Layout.preferredWidth: VLCStyle.dp(319, VLCStyle.scale)
                color: VLCStyle.redesign.color("#EAEAEA", "#2e2e2e")
                selectByMouse: true
                echoMode: fieldRow.modelData.key === "lastfm-password" ? TextInput.Password : TextInput.Normal
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                onTextEdited: root.settingsModel.setValue(fieldRow.modelData.key, text)
                background: Rectangle {
                    color: VLCStyle.redesign.color("#191919", "#ababaa")
                    border.color: VLCStyle.redesign.color("#373737", "#8e8e8d")
                    radius: 4
                }
                Component.onCompleted: {
                    if (fieldRow.modelData.key === "lastfm-username") root.username = editor
                    else if (fieldRow.modelData.key === "lastfm-password") root.password = editor
                    else root.submissionUrl = editor
                }
            }
        }
    }
    Label {
        Layout.fillWidth: true
        visible: root.available
        text: qsTr("Last.fm connection changes take effect after restarting VLC.")
        color: VLCStyle.redesign.color("#8F8F8F", "#7c7c7b")
        wrapMode: Text.WordWrap
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
    }

    property var username
    property var password
    property var submissionUrl
}
