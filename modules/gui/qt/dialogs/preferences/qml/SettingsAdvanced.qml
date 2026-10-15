/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Controls.Basic as Controls
import VLC.Style

Column {
    id: root
    required property var settingsModel
    required property string category
    property bool editingEnabled: true
    property int revision: 0
    readonly property bool supportedCategory: category === "general" || category === "performance"
    readonly property var rows: category === "general" ? [
        {key: "qt-error-dialogs", label: qsTr("Show minor warnings"), type: "boolean", fallback: false},
        {key: "command-line", label: qsTr("Additional command line options"), type: "string", fallback: "",
         unavailable: true, help: qsTr("Pass these options when launching VLC")},
        {key: "logmode", label: qsTr("Log format"), type: "string", fallback: "text",
         choices: [{value: "text", label: qsTr("Plain text")}, {value: "html", label: qsTr("HTML")}]},
        {key: "stats", label: qsTr("Collect playback statistics"), type: "boolean", fallback: true}
    ] : category === "performance" ? [
        {key: "encoder", label: qsTr("Encoder"), type: "string", fallback: "any", unavailable: true,
         help: qsTr("VLC 4 uses encoder-specific options"), choices: [{value: "any", label: qsTr("Automatic")}]},
        {key: "codec", label: qsTr("Decoder"), type: "string", fallback: "any", editor: "custom-choice"},
        {key: "clock-synchro", label: qsTr("Clock synchronization"), type: "integer", fallback: -1},
        {key: "clock-jitter", label: qsTr("Clock jitter"), type: "integer", fallback: 5000},
        {key: "cr-average", label: qsTr("Clock reference averaging"), type: "integer", fallback: 40}
    ] : []
    spacing: 0

    Connections {
        target: root.settingsModel
        function onDataChanged() { ++root.revision }
        function onModelReset() { ++root.revision }
    }
    SettingsPresentation { id: presentation }

    Controls.Label {
        visible: root.category === "performance"
        width: root.width
        height: visible ? VLCStyle.dp(58, VLCStyle.scale) : 0
        topPadding: VLCStyle.dp(22, VLCStyle.scale)
        text: qsTr("Developer")
        color: VLCStyle.redesign.color("#d2d2d2", "#252525")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
    }
    Repeater {
        model: root.rows
        delegate: Item {
            id: row
            required property var modelData
            readonly property var option: { root.revision; return root.settingsModel.optionFor(modelData.key) }
            readonly property bool available: !modelData.unavailable && !!option.key
            readonly property string disabledHelp: modelData.help || qsTr("Unavailable in this VLC build")
            width: root.width
            height: VLCStyle.dp(46, VLCStyle.scale)

            SettingsOptionRow {
                width: parent.width
                enabled: row.available && root.editingEnabled
                settingKey: row.modelData.key
                label: row.modelData.label
                help: !row.available ? row.disabledHelp : (row.option.help || "")
                settingType: row.option.type || row.modelData.type
                settingValue: row.available ? row.option.value : row.modelData.fallback
                minimum: row.option.minimum
                maximum: row.option.maximum
                choices: row.modelData.choices || presentation.choices(settingKey, row.option.choices || [])
                editorKind: row.modelData.editor || ""
                onCommit: value => root.settingsModel.setValue(settingKey, value)
            }
            HoverHandler { id: hover }
            Controls.ToolTip.visible: hover.hovered && (!row.available || !root.editingEnabled)
            Controls.ToolTip.text: !row.available ? row.disabledHelp : qsTr("Enable Developer mode to edit diagnostics")
            Controls.ToolTip.delay: 450
        }
    }
}
