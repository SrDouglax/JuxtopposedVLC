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
        color: VLCStyle.redesign.textPrimary
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
        color: VLCStyle.redesign.textMuted
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    }
    SettingsEqualizer {
        Layout.fillWidth: true
        visible: root.category === "audio" && audioEffects.transactionActive
                 && audioEffects.filterAvailable("equalizer")
        effects: audioEffects
    }
    FilterSection {
        Layout.fillWidth: true
        visible: root.category === "audio" && audioEffects.transactionActive
                 && audioEffects.filterAvailable("compressor")
        effects: audioEffects
        filterId: "compressor"
        title: qsTr("Compressor")
    }
    FilterSection {
        Layout.fillWidth: true
        visible: root.category === "audio" && audioEffects.transactionActive
                 && audioEffects.filterAvailable("spatializer")
        effects: audioEffects
        filterId: "spatializer"
        title: qsTr("Spatial audio")
    }
    FilterSection {
        Layout.fillWidth: true
        visible: root.category === "audio" && audioEffects.transactionActive
                 && audioEffects.filterAvailable("stereo_widen")
        effects: audioEffects
        filterId: "stereo_widen"
        title: qsTr("Stereo widening")
    }
    SettingsPicture {
        Layout.fillWidth: true
        visible: root.category === "video" && videoEffects.transactionActive
                 && videoEffects.filterAvailable("adjust")
        effects: videoEffects
    }
}
