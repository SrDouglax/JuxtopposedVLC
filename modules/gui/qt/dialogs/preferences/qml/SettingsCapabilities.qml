/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Controls.Basic as C
import VLC.Style

// Keep the reference's system controls visible when this platform/build lacks
// their native option. Never offer a successful action without a backend.
Column {
    id: root
    required property var settingsModel
    required property string category
    property string section: ""
    property int revision: 0
    Connections {
        target: root.settingsModel
        function onDataChanged() { ++root.revision }
        function onModelReset() { ++root.revision }
    }
    C.Label {
        visible: root.category === "network"
        width: parent.width
        height: visible ? VLCStyle.dp(58, VLCStyle.scale) : 0
        topPadding: VLCStyle.dp(22, VLCStyle.scale)
        text: qsTr("Proxy")
        color: VLCStyle.redesign.color("#d2d2d2", "#252525")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
    }
    readonly property var missing: (category === "performance" ? [
        {key: "high-priority", label: qsTr("Give VLC real-time priority"), type: "boolean", value: false},
        {key: "process-priority", label: qsTr("Process priority"), type: "integer", value: 0}
    ] : category === "recording" ? [
        {key: "sout-chromecast-conversion-quality", label: qsTr("Cast quality"), type: "integer", value: 0, choices: [{value: 0, label: qsTr("Automatic")}]},
        {key: "sout-x264-preset", label: qsTr("Encoding preset"), type: "string", value: "medium", choices: [{value: "medium", label: qsTr("Medium")}]},
        {key: "sout-x264-tune", label: qsTr("Tuning"), type: "string", value: "", choices: [{value: "", label: qsTr("None")}]}
    ] : category === "network" ? [
        {key: "http-proxy", label: qsTr("HTTP proxy"), type: "string", value: ""},
        {key: "http-proxy-pwd", label: qsTr("HTTP proxy password"), type: "string", value: "", editor: "password"}
    ] : []).filter(row => !section || (section === "Casting") === row.key.startsWith("sout-chromecast"))
    Repeater {
        model: root.missing
        SettingsOptionRow {
            required property var modelData
            visible: root.category === "network" || !root.settingsModel.hasOption(modelData.key)
            width: root.width
            settingKey: modelData.key
            label: modelData.label
            settingType: modelData.type
            settingValue: { root.revision; return root.settingsModel.hasOption(modelData.key)
                           ? root.settingsModel.valueFor(modelData.key) : modelData.value }
            editorKind: modelData.editor || ""
            choices: modelData.choices || []
            enabled: root.category === "network" && root.settingsModel.hasOption(modelData.key)
            onCommit: value => root.settingsModel.setValue(modelData.key, value)
            help: qsTr("This platform or VLC build does not provide this option")
        }
    }
    Item {
        visible: root.category === "performance"
        width: root.width
        height: VLCStyle.dp(46, VLCStyle.scale)
        C.Label {
            text: qsTr("Rescan plugins")
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            color: VLCStyle.redesign.color("#949494", "#494949")
        }
        C.Button {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(VLCStyle.dp(320, VLCStyle.scale), root.width * 0.46)
            height: VLCStyle.dp(34, VLCStyle.scale)
            enabled: false
            text: qsTr("Rescan")
            C.ToolTip.text: qsTr("VLC rebuilds its plugin cache during startup, not while the player is running")
            C.ToolTip.visible: hover.hovered
            HoverHandler { id: hover }
            background: Rectangle { radius: 4; color: VLCStyle.redesign.color("#191919", "#dedede") }
            contentItem: C.Label { text: parent.text; color: VLCStyle.redesign.color("#6b6b6b", "#777777"); font.family: VLCStyle.redesign.fontFamily; font.pixelSize: VLCStyle.dp(14, VLCStyle.scale); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
    }
}
