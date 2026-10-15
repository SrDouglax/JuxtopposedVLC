/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Controls.Basic as C
import VLC.Widgets as Widgets
import VLC.MainInterface
import VLC.Style

Column {
    id: root
    required property var settingsModel
    property int revision: 0
    readonly property bool available: settingsModel.moduleAvailable("skins2") && settingsModel.hasOption("skins2-last")
    Widgets.FilePicker { id: picker; ctx: MainCtx }
    Connections {
        target: root.settingsModel
        function onDataChanged() { ++root.revision }
        function onModelReset() { ++root.revision }
    }
    C.Label {
        width: parent.width
        height: VLCStyle.dp(32, VLCStyle.scale)
        text: qsTr("Skin")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
        color: VLCStyle.redesign.color("#d2d2d2", "#333333")
    }
    SettingsOptionRow {
        width: parent.width
        settingKey: "use-custom-skin"
        label: qsTr("Use a custom skin")
        help: qsTr("Uses VLC's skins interface after restart when the skins module is installed")
        enabled: root.available
        settingType: "boolean"
        settingValue: { root.revision; return root.settingsModel.valueFor("intf") === "skins2" }
        onCommit: value => root.settingsModel.setValue("intf", value ? "skins2" : "qt")
    }
    SettingsOptionRow {
        width: parent.width
        settingKey: "skins2-last"
        label: qsTr("Skin file")
        enabled: root.available
        settingType: "string"
        editorKind: "skinfile"
        settingValue: { root.revision; return root.settingsModel.valueFor("skins2-last") || "" }
        onCommit: value => root.settingsModel.setValue("skins2-last", value)
        onBrowseRequested: {
            const url = picker.chooseFile(qsTr("Choose a VLC skin"), qsTr("VLC skins (*.vlt *.wsz)"))
            if (url.toString()) root.settingsModel.setFileUrl("skins2-last", url)
        }
    }
}
