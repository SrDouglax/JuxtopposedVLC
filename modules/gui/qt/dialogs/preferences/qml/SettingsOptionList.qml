/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import VLC.Style
import VLC.MainInterface
import VLC.Widgets as Widgets


Column {
    id: root
    Widgets.FilePicker { id: filePicker; ctx: MainCtx }
    SettingsPresentation { id: presentationData }
    property var settingsModel
    property string category: ""
    property string search: ""
    readonly property int count: optionsRepeater.count
    width: parent ? parent.width : implicitWidth
    spacing: 0

    Repeater {
        id: optionsRepeater
        model: root.settingsModel
        delegate: Column {
            width: root.width
            spacing: 0
            readonly property var presentation: presentationData.entry(model.key, model.label)
            readonly property string previousSection: index > 0
                ? presentationData.entry(root.settingsModel.keyAt(index - 1), "").section : ""

            Label {
                visible: index === 0 || presentation.section !== previousSection
                width: parent.width
                height: visible ? VLCStyle.dp(58, VLCStyle.scale) : 0
                topPadding: VLCStyle.dp(22, VLCStyle.scale)
                text: presentation.section
                color: VLCStyle.palette.isDark ? "#d2d2d2" : "#252525"
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            }

            SettingsOptionRow {
                width: parent.width
                settingKey: model.key
                label: presentation.label
                help: model.help
                settingType: model.type
                settingValue: model.value
                choices: model.choices
                minimum: model.minimum
                maximum: model.maximum
                editorKind: presentation.editor
                dirty: model.dirty
                onCommit: (value) => root.settingsModel.setValue(settingKey, value)
                onBrowseRequested: {
                    const file = filePicker.chooseSaveFile(qsTr("Choose a log file"), String(settingValue || ""))
                    if (file.length) root.settingsModel.setValue(settingKey, file)
                }
            }

            Label {
                visible: model.key === "file-logging"
                width: parent.width
                height: visible ? implicitHeight + 8 : 0
                text: qsTr("Restart VLC to apply changes to file logging.")
                wrapMode: Text.WordWrap
                color: VLCStyle.redesign.textMuted
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
            }

            Loader {
                width: parent.width
                active: root.category === "privacy" && root.search.length === 0
                        && model.key === "restore-playback-states"
                sourceComponent: SettingsPrivacyActions { width: root.width }
            }
        }
    }
}
