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
    property var windowState: null
    property var audioEffects: null
    property var settingsModel
    property string category: ""
    property string search: ""
    property string filterMode: "all"
    property string sectionFilter: ""
    property string excludedSection: ""
    property bool hideSectionHeadings: false
    property bool customBuffering: false
    property var enabledEnumValues: ({"restore-playback-pos": 2, "disable-screensaver": 1})
    property int lastShadowOpacity: 128
    property int revision: 0
    readonly property bool buffersEditable: {
        revision
        if (customBuffering) return true
        const keys = ["file-caching", "disc-caching", "network-caching", "live-caching"]
        return ![[300,300,1000,300], [100,100,300,100], [1000,1000,3000,1000]]
            .some(values => keys.every((key, i) => Number(settingsModel.valueFor(key)) === values[i]))
    }
    Connections {
        target: root.settingsModel
        function onDataChanged() { ++root.revision }
        function onModelReset() { root.customBuffering = false; ++root.revision }
    }
    function compositeKind(key) {
        return ({"repeat": "repeat", "hw-dec": "hardware", "play-and-pause": "finished", "file-caching": "buffering", "qt-video-autoresize": "resize", "qt-fullscreen-screennumber": "screen", "qt-pin-controls": "autohide", "mouse-hide-timeout": "hideafter"})[key] || ""
    }
    readonly property int count: optionsRepeater.count
    readonly property int availableCount: {
        let total = 0
        for (let i = 0; i < optionsRepeater.count; ++i) {
            const entry = presentationData.entry(root.settingsModel.keyAt(i), "")
            if (!entry.hidden && (filterMode === "all" || (filterMode === "advanced") === entry.advanced)
                    && (!sectionFilter || entry.section === sectionFilter)
                    && (!excludedSection || entry.section !== excludedSection))
                ++total
        }
        return total
    }
    width: parent ? parent.width : implicitWidth
    spacing: 0

    Repeater {
        id: optionsRepeater
        model: root.settingsModel
        delegate: Column {
            width: root.width
            spacing: 0
            readonly property var presentation: presentationData.entry(model.key, model.label)
            readonly property bool enumToggle: model.key === "disable-screensaver"
                || (root.category === "privacy" && model.key === "restore-playback-pos")
            // A category can place an inline effect panel between native option groups.
            visible: !presentation.hidden && (root.filterMode === "all"
                      || (root.filterMode === "advanced") === presentation.advanced)
                     && (!root.sectionFilter || presentation.section === root.sectionFilter)
                     && (!root.excludedSection || presentation.section !== root.excludedSection)
            readonly property int previousVisibleIndex: {
                for (let i = index - 1; i >= 0; --i) {
                    const entry = presentationData.entry(root.settingsModel.keyAt(i), "")
                    if (!entry.hidden && (root.filterMode === "all" || (root.filterMode === "advanced") === entry.advanced)
                            && (!root.sectionFilter || entry.section === root.sectionFilter)
                            && (!root.excludedSection || entry.section !== root.excludedSection)) return i
                }
                return -1
            }
            readonly property string previousSection: previousVisibleIndex < 0 ? "" : presentationData.entry(root.settingsModel.keyAt(previousVisibleIndex), "").section


            Label {
                visible: !root.hideSectionHeadings && root.filterMode !== "advanced"
                         && (previousVisibleIndex < 0 || presentation.section !== previousSection)
                width: parent.width
                height: visible ? VLCStyle.dp(previousVisibleIndex < 0 ? (root.category === "audio" && root.excludedSection ? 44 : 28) : 58, VLCStyle.scale) : 0
                topPadding: previousVisibleIndex < 0 ? (root.category === "audio" && root.excludedSection ? VLCStyle.dp(8, VLCStyle.scale) : 0) : VLCStyle.dp(22, VLCStyle.scale)
                text: presentation.section
                color: VLCStyle.palette.isDark ? "#d2d2d2" : "#252525"
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            }

            Loader {
                width: parent.width
                active: parent.visible && root.compositeKind(model.key).length > 0
                visible: active
                sourceComponent: SettingsComposite {
                    settingsModel: root.settingsModel
                    kind: root.compositeKind(model.key)
                    onBufferingModeChanged: custom => root.customBuffering = custom
                }
            }
            SettingsRemote {
                width: parent.width
                visible: model.key === "http-port"
                settingsModel: root.settingsModel
            }
            SettingsComposite {
                width: parent.width
                visible: model.key === "playlist-autostart" || model.key === "media-library"
                settingsModel: root.settingsModel
                kind: model.key === "media-library" ? "artwork" : "resume"
            }
            Loader {
                width: parent.width
                active: parent.visible && model.key === "audio-replay-gain-mode" && root.audioEffects !== null
                visible: active
                sourceComponent: SettingsLoudness { effects: root.audioEffects }
            }
            SettingsOptionRow {
                visible: (!root.compositeKind(model.key) || model.key === "file-caching")
                         && !(model.key === "volume-save" && !root.search.length)
                         && !(model.key === "sub-text-scale" && !root.search.length && root.settingsModel.hasOption("freetype-absolute-size"))
                enabled: (["one-instance-when-started-from-file", "playlist-enqueue"].includes(model.key) ? Boolean(root.settingsModel.valueFor("one-instance")) : true)
                         && (!["file-caching", "disc-caching", "network-caching", "live-caching"].includes(model.key) || root.buffersEditable)
                width: parent.width
                settingKey: model.key
                label: presentation.label
                help: model.help
                settingType: presentation.editor === "shadow" || parent.enumToggle ? "boolean" : model.type
                settingValue: model.key === "input-fast-seek" ? !model.value
                              : presentation.editor === "shadow" || parent.enumToggle ? Number(model.value) > 0 : model.value
                choices: presentationData.choices(model.key, model.choices)
                minimum: model.minimum
                maximum: model.maximum
                editorKind: ["aspect-ratio", "audio-language", "sub-language", "menu-language"].includes(model.key) ? "custom-choice" : presentation.editor
                dirty: model.dirty
                onCommit: (value) => {
                    if (parent.enumToggle) {
                        if (!value && Number(model.value) > 0) root.enabledEnumValues[settingKey] = Number(model.value)
                        value = value ? root.enabledEnumValues[settingKey] : 0
                    }
                    if (settingKey === "input-fast-seek") value = !value
                    if (presentation.editor === "shadow") {
                        if (!value && Number(model.value) > 0) root.lastShadowOpacity = Number(model.value)
                        value = value ? root.lastShadowOpacity : 0
                    }
                    root.settingsModel.setValue(settingKey, value)
                }
                onBrowseRequested: {
                    if (editorKind === "directory") {
                        const folder = filePicker.chooseFolder(qsTr("Choose a recording folder"))
                        if (folder.toString() !== "")
                            root.settingsModel.setDirectoryUrl(settingKey, folder)
                    } else if (editorKind === "savefile") {
                        const file = filePicker.chooseSaveFile(qsTr("Choose a log file"), String(settingValue || ""))
                        if (file.length) root.settingsModel.setValue(settingKey, file)
                    }
                }
            }

            Loader {
                width: parent.width
                active: parent.visible && model.key === "volume-save" && !root.search.length
                visible: active
                sourceComponent: SettingsStartupVolume { settingsModel: root.settingsModel }
            }

            Loader {
                width: parent.width
                active: parent.visible && root.category === "network" && !root.search.length
                        && model.key === "live-caching"
                visible: active
                sourceComponent: SettingsCapabilities {
                    settingsModel: root.settingsModel
                    category: "network"
                }
            }

            SettingsSubtitleSize {
                width: parent.width
                visible: model.key === "sub-text-scale" && !root.search.length && root.settingsModel.hasOption("freetype-absolute-size")
                settingsModel: root.settingsModel
            }

            Loader {
                width: parent.width
                active: parent.visible && root.category === "recording" && !root.search.length
                        && ((model.key === "qt-cast-discovery" && !root.settingsModel.hasOption("sout-chromecast-conversion-quality"))
                            || (model.key === "sout-spu" && (!root.settingsModel.hasOption("sout-x264-preset") || !root.settingsModel.hasOption("sout-x264-tune"))))
                visible: active
                sourceComponent: SettingsCapabilities {
                    settingsModel: root.settingsModel
                    category: "recording"
                    section: model.key === "qt-cast-discovery" ? "Casting" : "Streaming"
                }
            }

            SettingsOptionRow {
                width: parent.width
                visible: model.key === "qt-remember-window-position" && root.windowState !== null
                settingKey: "interface-always-on-top"
                label: qsTr("Keep window above other windows")
                settingType: "boolean"
                settingValue: root.windowState ? root.windowState.selected : false
                onCommit: value => root.windowState.preview(value)
            }
            Loader {
                width: parent.width
                active: root.category === "privacy" && root.search.length === 0
                        && model.key === "qt-history-exclude"
                sourceComponent: SettingsPrivacyActions { width: root.width }
            }
        }
    }
}
