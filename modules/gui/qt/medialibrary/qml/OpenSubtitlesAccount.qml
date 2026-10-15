/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls
import VLC.Style

Controls.Dialog {
    id: root
    objectName: "openSubtitlesAccount"
    property alias apiKey: apiKeyField.text
    property alias username: usernameField.text
    property alias password: passwordField.text
    title: qsTr("OpenSubtitles account")
    property bool downloadRequired: false
    readonly property bool credentialsReady: apiKey.trim().length > 0
        && (!downloadRequired || (username.trim().length > 0 && password.length > 0))
    z: 110
    modal: true
    width: Math.min(VLCStyle.dp(520, VLCStyle.scale), parent ? parent.width - 32 : 520)
    anchors.centerIn: parent
    standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel
    Binding {
        target: root.standardButton(Controls.Dialog.Ok)
        property: "enabled"
        value: root.credentialsReady
    }
    function clearCredentials() { apiKeyField.clear(); usernameField.clear(); passwordField.clear() }
    background: Rectangle { radius: 8; color: VLCStyle.redesign.color("#151515", "#dedede"); border.color: "#373737" }
    contentItem: ColumnLayout {
        spacing: VLCStyle.dp(12, VLCStyle.scale)
        Controls.TextField {
            id: apiKeyField
            objectName: "openSubtitlesApiKey"
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
            placeholderText: qsTr("API key")
            echoMode: TextInput.Password
            selectByMouse: true
        }
        Controls.TextField {
            id: usernameField
            objectName: "openSubtitlesUsername"
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
            placeholderText: qsTr("Username")
            selectByMouse: true
        }
        Controls.TextField {
            id: passwordField
            objectName: "openSubtitlesPassword"
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
            placeholderText: qsTr("Password")
            echoMode: TextInput.Password
            selectByMouse: true
        }
        Controls.Label {
            Layout.fillWidth: true
            text: qsTr("Used only for this session. Downloads use your OpenSubtitles quota.")
            wrapMode: Text.WordWrap
            color: VLCStyle.redesign.textMuted
            font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
        }
    }
}
