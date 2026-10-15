/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Layouts
import VLC.Dialogs
import VLC.MainInterface
import VLC.Style

ColumnLayout {
    id: root
    readonly property alias audioBridge: audioEffects
    property var settingsModel
    property int configRevision: 0
    Connections {
        target: root.settingsModel
        function onDataChanged() { ++root.configRevision }
        function onModelReset() { ++root.configRevision }
    }
    property string category: ""
    property bool searchActive: false
    property bool audioDirty: false
    property bool videoDirty: false
    property bool starting: false
    readonly property bool dirty: audioDirty || videoDirty
    readonly property string error: audioEffects.lastError || videoEffects.lastError
    spacing: VLCStyle.dp(12, VLCStyle.scale)
    visible: !searchActive && (category === "audio" || category === "video")

    AudioEffects {
        id: audioEffects
        // Keep the Night-mode rollback point while category delegates reload.
        property var nightSnapshot: null
        ctx: MainCtx
        onStateChanged: {
            if (!root.starting && transactionActive)
                root.audioDirty = true
        }
    }
    VideoEffects {
        id: videoEffects
        ctx: MainCtx
        onStateChanged: {
            if (!root.starting && transactionActive)
                root.videoDirty = true
        }
    }

    function beginForCurrentCategory() {
        starting = true
        if (category === "audio" && !audioEffects.transactionActive && audioEffects.activeAudio)
            audioEffects.begin()
        if (category === "video" && !videoEffects.transactionActive && videoEffects.activeVideo)
            videoEffects.begin()
        starting = false
    }

    function cancel() {
        if (audioEffects.transactionActive) audioEffects.cancel()
        if (videoEffects.transactionActive) videoEffects.cancel()
        audioDirty = false
        videoDirty = false
    }

    function clearDirty() {
        audioDirty = false
        videoDirty = false
    }

    function audioForSave() { return audioDirty ? audioEffects : null }
    function videoForSave() { return videoDirty ? videoEffects : null }

    Text {
        Layout.fillWidth: true
        visible: root.category === "audio"
        text: qsTr("Effects")
        color: VLCStyle.redesign.color("#EAEAEA", "#2e2e2e")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
    }
    Text {
        Layout.fillWidth: true
        visible: (root.category === "audio" && !audioEffects.transactionActive)
                 || (root.category === "video" && !videoEffects.transactionActive)
        text: root.category === "audio"
              ? qsTr("Play audio to adjust and preview sound effects.")
              : qsTr("Play video to adjust and preview the picture.")
        wrapMode: Text.WordWrap
        color: VLCStyle.redesign.color("#8F8F8F", "#7c7c7b")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    }
    SettingsEqualizer {
        Layout.fillWidth: true
        visible: root.category === "audio" && audioEffects.transactionActive
                 && audioEffects.filterAvailable("equalizer")
        effects: audioEffects
    }
    SettingsOptionRow {
        Layout.fillWidth: true
        visible: root.category === "audio"
        settingKey: "spatial-audio-enabled"
        label: qsTr("Spatial audio")
        settingType: "boolean"
        settingValue: { root.configRevision; return Number(root.settingsModel.valueFor("mix-mode")) >= 2 }
        onCommit: value => root.settingsModel.setValue("mix-mode", value ? 2 : 0)
    }
    SettingsOptionRow {
        Layout.fillWidth: true
        visible: root.category === "audio"
        settingKey: "mix-mode"
        label: qsTr("Spatial audio mode")
        settingType: "integer"
        settingValue: { root.configRevision; return Math.max(2, Number(root.settingsModel.valueFor("mix-mode"))) }
        choices: (root.settingsModel.optionFor("mix-mode").choices || []).filter(choice => Number(choice.value) >= 2)
            .map(choice => ({value: choice.value, label: Number(choice.value) === 2 ? qsTr("Headphone virtualization") : choice.label}))
        onCommit: value => root.settingsModel.setValue("mix-mode", value)
    }
    SettingsOptionRow {
        Layout.fillWidth: true
        visible: root.category === "audio"
        settingKey: "stereo-widening"
        label: qsTr("Stereo widening")
        settingType: "boolean"
        enabled: audioEffects.transactionActive && audioEffects.filterAvailable("stereo_widen")
        settingValue: { audioEffects.bands; return audioEffects.filterEnabled("stereo_widen") }
        onCommit: value => audioEffects.setFilterEnabled("stereo_widen", value)
    }
    SettingsPicture {
        Layout.fillWidth: true
        visible: root.category === "video" && videoEffects.transactionActive
                 && videoEffects.filterAvailable("adjust")
        effects: videoEffects
    }
}
