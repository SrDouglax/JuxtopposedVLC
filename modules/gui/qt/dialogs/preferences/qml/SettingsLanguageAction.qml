/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import VLC.MainInterface
import VLC.Player
import VLC.Style

Item {
    id: root
    objectName: "interfaceLanguageAction"
    implicitHeight: VLCStyle.dp(46, VLCStyle.scale)
    property string selectedLanguage: ""
    property string initialLanguage: ""
    readonly property bool dirty: selectedLanguage !== initialLanguage
    function begin() {
        initialLanguage = String(MainCtx.settingValue("redesign/interface-language", ""))
        selectedLanguage = initialLanguage
    }
    function save() {
        MainCtx.setSettingValue("redesign/interface-language", selectedLanguage)
        initialLanguage = selectedLanguage
    }
    function cancel() { selectedLanguage = initialLanguage }
    function resetDefaults() { selectedLanguage = "" }
    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: qsTr("Interface language")
        color: VLCStyle.redesign.color("#969696", "#494949")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    }
    PanelCombo {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(VLCStyle.dp(318, VLCStyle.scale), parent.width * 0.46)
        height: VLCStyle.dp(34, VLCStyle.scale)
        objectName: "interfaceLanguageChoice"
        model: [qsTr("System language (%1)").arg(Qt.locale().name), "English"]
        currentIndex: root.selectedLanguage === "en" ? 1 : 0
        onActivated: index => root.selectedLanguage = index === 1 ? "en" : ""
        hoverEnabled: true
        // The gettext-backed system language and English source strings are
        // both available without downloading or manufacturing translations.
        Accessible.description: qsTr("Restart VLC to change the interface language")
    }
}
