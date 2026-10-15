/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import VLC.Dialogs
import VLC.MainInterface
import VLC.Style

Dialog {
    id: root
    objectName: "redesignSettingsDialog"
    modal: true
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape
    width: Math.min(VLCStyle.dp(1048, VLCStyle.scale),
                    parent ? parent.width - VLCStyle.dp(32, VLCStyle.scale)
                           : VLCStyle.dp(1048, VLCStyle.scale))
    height: Math.min(VLCStyle.dp(865, VLCStyle.scale),
                     parent ? parent.height - VLCStyle.dp(32, VLCStyle.scale)
                            : VLCStyle.dp(865, VLCStyle.scale))
    anchors.centerIn: parent

    property string selectedCategory: "general"
    property bool saved: false
    property bool previousGlobalShortcuts: true
    property bool advancedExpanded: false
    property string profileError: ""
    readonly property bool dark: VLCStyle.palette.isDark
    readonly property bool appearanceDirty: appearance.dirty
    readonly property bool hasChanges: config.dirty || appearanceDirty
                                       || inlineEffects.dirty || developerMode.dirty || audioOutput.dirty || windowSettings.dirty

    readonly property var titles: ({
        extensions: qsTr("Add-ons & Scripts"),
        general: qsTr("Global Settings"), interface: qsTr("Interface Settings"),
        privacy: qsTr("Privacy Settings"), controls: qsTr("Mouse, Keyboard & Remote Controls"),
        playback: qsTr("Playback Preferences"), video: qsTr("Video Defaults"),
        audio: qsTr("Audio Defaults"), subtitles: qsTr("Subtitle Defaults"),
        library: qsTr("Playlists, Folders & Files"), network: qsTr("Network Connections & Security"),
        performance: qsTr("Performance Settings"), recording: qsTr("Recording, Casting & Streaming Out")
    })

    function openSettings(category) {
        selectedCategory = category || "general"
        searchField.text = ""
        open()
    }

    function persistProfileAndClose() {
        if (!MainCtx.controlbarProfileModel.save()) {
            profileError = MainCtx.controlbarProfileModel.lastError
            return
        }
        profileError = ""
        close()
    }

    function saveSettings() {
        if (!hasChanges && !profileError) { saved = true; close(); return }
        if (profileError) { persistProfileAndClose(); return }
        if (!audioOutput.canApply()) return
        if (!config.applyWithEffects(inlineEffects.audioForSave(), inlineEffects.videoForSave())) {
            inlineEffects.clearDirty()
            inlineEffects.beginForCurrentCategory()
            if (audioOutput.cancel() && root.selectedCategory === "audio")
                audioOutput.begin()
            return
        }
        if (!audioOutput.apply()) return
        inlineEffects.clearDirty()
        appearance.save()
        developerMode.save()
        windowSettings.save()
        saved = true
        persistProfileAndClose()
    }

    onOpened: {
        saved = false
        profileError = ""
        previousGlobalShortcuts = MainCtx.useGlobalShortcuts
        MainCtx.useGlobalShortcuts = false
        config.reload()
        appearance.begin()
        developerMode.begin()
        windowSettings.begin()
        lastfm.begin()
        advancedExpanded = false
        inlineEffects.beginForCurrentCategory()
        if (selectedCategory === "audio") audioOutput.begin()
    }
    onClosed: {
        if (!saved) {
            config.cancel()
            appearance.cancel()
            developerMode.cancel()
            windowSettings.cancel()
        }
        inlineEffects.cancel()
        audioOutput.cancel()
        MainCtx.useGlobalShortcuts = previousGlobalShortcuts
    }
    ShortcutsDialog { id: shortcutsDialog; parent: root.parent }
    SettingsWindowState { id: windowSettings; settingsModel: config }

    ConfigModel {
        id: config
        ctx: MainCtx
        category: searchField.text.length > 0 ? "" : root.selectedCategory
        search: searchField.text
    }
    background: Rectangle {
        color: VLCStyle.redesign.color(VLCStyle.redesign.windowBackground,
                                       VLCStyle.palette.lightGrey100)
        border.color: VLCStyle.redesign.color("#222222", VLCStyle.palette.lightGrey700)
        radius: VLCStyle.dp(8, VLCStyle.scale)
    }
    contentItem: Item {
        Rectangle {
            id: topbar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: VLCStyle.dp(49, VLCStyle.scale)
            color: "transparent"
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: VLCStyle.dp(8, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                width: VLCStyle.dp(200, VLCStyle.scale)
                height: VLCStyle.dp(34, VLCStyle.scale)
                radius: 4
                color: root.dark ? "#181818" : "#eeeeee"

                Image {
                    anchors.left: parent.left
                    anchors.leftMargin: VLCStyle.dp(12, VLCStyle.scale)
                    anchors.verticalCenter: parent.verticalCenter
                    width: VLCStyle.dp(20, VLCStyle.scale)
                    height: width
                    sourceSize: Qt.size(width, height)
                    source: "qrc:///redesign/icons/search/default.png"
                }
                TextField {
                    id: searchField
                    objectName: "settingsSearch"
                    anchors.fill: parent
                    leftPadding: VLCStyle.dp(42, VLCStyle.scale)
                    rightPadding: VLCStyle.dp(10, VLCStyle.scale)
                    placeholderText: qsTr("Search")
                    color: root.dark ? "#dddddd" : "#222222"
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    background: Item {}
                }
            }

            Label {
                anchors.left: parent.left
                anchors.leftMargin: VLCStyle.dp(240, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: closeButton.left
                elide: Text.ElideRight
                text: searchField.text.length > 0 ? qsTr("Search results")
                      : root.titles[root.selectedCategory] || qsTr("Settings")
                color: root.dark ? "#a7a7a7" : "#3c3c3c"
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            }
            Button {
                id: closeButton
                objectName: "settingsClose"
                anchors.right: parent.right
                anchors.rightMargin: VLCStyle.dp(15, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                width: VLCStyle.dp(32, VLCStyle.scale)
                height: width
                onClicked: root.saveSettings()
                background: Item {}
                contentItem: Image {
                    anchors.centerIn: parent
                    width: VLCStyle.dp(20, VLCStyle.scale)
                    height: width
                    sourceSize: Qt.size(width, height)
                    source: "qrc:///redesign/icons/close/default.png"
                }
            }
        }

        SettingsSidebar {
            id: sidebar
            objectName: "settingsSidebar"
            anchors.left: parent.left
            anchors.leftMargin: VLCStyle.dp(8, VLCStyle.scale)
            anchors.top: topbar.bottom
            anchors.bottom: parent.bottom
            anchors.bottomMargin: VLCStyle.dp(8, VLCStyle.scale)
            width: VLCStyle.dp(200, VLCStyle.scale)
            category: root.selectedCategory
            availableCategories: config.categories
            onSelected: (category) => {
                root.selectedCategory = category
                searchField.text = ""
                contentFlick.contentY = 0
                root.advancedExpanded = false
                inlineEffects.beginForCurrentCategory()
                if (category === "audio") audioOutput.begin()
            }
        }

        Flickable {
            id: contentFlick
            objectName: "settingsContent"
            anchors.left: sidebar.right
            anchors.leftMargin: VLCStyle.dp(32, VLCStyle.scale)
            anchors.right: parent.right
            anchors.rightMargin: VLCStyle.dp(24, VLCStyle.scale)
            anchors.top: topbar.bottom
            anchors.topMargin: VLCStyle.dp(25, VLCStyle.scale)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: VLCStyle.dp(24, VLCStyle.scale)
            contentHeight: contentColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            Column {
                id: contentColumn
                width: contentFlick.width
                spacing: VLCStyle.dp(11, VLCStyle.scale)

                SettingsAppearance {
                    id: appearance
                    width: parent.width
                    visible: root.selectedCategory === "general"
                             && (searchField.text.length === 0
                                 || qsTr("appearance theme accent language").toLowerCase()
                                       .includes(searchField.text.toLowerCase()))
                }

                SettingsExtensions {
                    id: extensions
                    width: parent.width
                    visible: root.selectedCategory === "extensions" && !searchField.text.length
                    settingsModel: config
                }
                SettingsSkin {
                    width: parent.width
                    visible: root.selectedCategory === "interface" && !searchField.text.length
                    settingsModel: config
                }

                SettingsShortcuts {
                    width: parent.width
                    visible: root.selectedCategory === "controls" && !searchField.text.length
                    onEditRequested: shortcutsDialog.open()
                    onResetRequested: shortcutsDialog.openReset()
                }

                SettingsOptionList {
                    id: optionList
                    windowState: windowSettings
                    visible: !extensions.visible && !(root.selectedCategory === "audio" && !searchField.text.length)
                    width: parent.width
                    settingsModel: config
                    category: root.selectedCategory
                    search: searchField.text
                    filterMode: searchField.text.length ? "all" : "basic"
                    sectionFilter: (root.selectedCategory === "video"
                                    || root.selectedCategory === "audio") && !searchField.text.length
                                   ? qsTr("Output")
                                   : root.selectedCategory === "general" && !searchField.text.length
                                     ? qsTr("Startup") : ""
                }

                SettingsCapabilities {
                    width: parent.width
                    settingsModel: config
                    category: root.selectedCategory
                    visible: !searchField.text.length && root.selectedCategory === "performance"
                }

                SettingsOptionRow {
                    width: parent.width
                    visible: root.selectedCategory === "general" && !searchField.text.length && !config.hasOption("qt-updates-notif")
                    settingKey: "updates-unavailable"
                    label: qsTr("Check for updates automatically")
                    settingType: "boolean"
                    settingValue: false
                    enabled: false
                    help: qsTr("This VLC build does not include the automatic updater")
                }

                SettingsDeveloperMode {
                    id: developerMode
                    width: parent.width
                    visible: root.selectedCategory === "general"
                             && (!searchField.text.length
                                 || qsTr("developer mode diagnostics")
                                    .includes(searchField.text.toLowerCase()))
                }

                SettingsOptionList {
                    id: generalMoreOptions
                    width: parent.width
                    visible: root.selectedCategory === "general" && !searchField.text.length
                    settingsModel: config
                    category: root.selectedCategory
                    filterMode: "basic"
                    excludedSection: qsTr("Startup")
                    hideSectionHeadings: true
                }

                SettingsAudioOutput {
                    id: audioOutput
                    settingsModel: config
                    width: parent.width
                    visible: root.selectedCategory === "audio" && !searchField.text.length
                }

                SettingsOptionList {
                    width: parent.width
                    visible: root.selectedCategory === "audio" && !searchField.text.length
                    settingsModel: config
                    category: root.selectedCategory
                    filterMode: "basic"
                    excludedSection: qsTr("Output")
                    audioEffects: inlineEffects.audioBridge
                }

                SettingsInlineEffects {
                    id: inlineEffects
                    settingsModel: config
                    width: parent.width
                    category: root.selectedCategory
                    searchActive: searchField.text.length > 0
                }

                SettingsOptionList {
                    id: videoMoreOptions
                    width: parent.width
                    visible: root.selectedCategory === "video" && !searchField.text.length
                    settingsModel: config
                    category: root.selectedCategory
                    filterMode: "basic"
                    excludedSection: qsTr("Output")
                }

                SettingsLastfm {
                    id: lastfm
                    width: parent.width
                    settingsModel: config
                    visible: (!searchField.text.length && root.selectedCategory === "privacy")
                             || (searchField.text.length > 0
                                 && qsTr("last.fm lastfm username password scrobbler")
                                    .includes(searchField.text.toLowerCase()))
                }

                Label {
                    visible: optionList.availableCount === 0 && !appearance.visible
                             && !developerMode.visible
                             && !lastfm.visible
                             && !inlineEffects.visible && !extensions.visible
                             && !welcomeSetupAction.visible
                    text: searchField.text.length > 0
                          ? qsTr("No matching settings")
                          : qsTr("No settings are available for this category on this VLC installation")
                    color: root.dark ? "#777777" : "#555555"
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    topPadding: 16
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Button {
                    id: advancedButton
                    objectName: "settingsAdvancedOptions"
                    visible: !searchField.text.length && (advancedOptions.availableCount > 0
                             || ["recording", "extensions"].includes(root.selectedCategory))
                    enabled: advancedOptions.availableCount > 0
                    ToolTip.text: qsTr("No additional options are available in this VLC build")
                    ToolTip.visible: !enabled && advancedHover.hovered
                    HoverHandler { id: advancedHover }
                    width: parent.width
                    height: VLCStyle.dp(38, VLCStyle.scale)
                    text: root.advancedExpanded ? qsTr("Advanced Options  ⌄")
                                                : qsTr("Advanced Options  ›")
                    onClicked: root.advancedExpanded = !root.advancedExpanded
                    background: Rectangle { color: root.dark ? "#1a1a1a" : "#e9e9e9"; radius: 3 }
                    contentItem: Label {
                        text: parent.text
                        color: root.dark ? "#999999" : "#444444"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    }
                }

                SettingsOptionList {
                    id: advancedOptions
                    width: parent.width
                    visible: advancedButton.visible && root.advancedExpanded
                             && !referenceAdvanced.supportedCategory
                             && (root.selectedCategory !== "general" || developerMode.selected)
                    settingsModel: config
                    category: root.selectedCategory
                    filterMode: "advanced"
                }

                SettingsAdvanced {
                    id: referenceAdvanced
                    width: parent.width
                    visible: advancedButton.visible && root.advancedExpanded && supportedCategory
                    settingsModel: config
                    category: root.selectedCategory
                    editingEnabled: root.selectedCategory !== "general" || developerMode.selected
                }

                SettingsOptionRow {
                    width: parent.width
                    visible: advancedOptions.visible && root.selectedCategory === "subtitles"
                             && config.hasOption("freetype-shadow-opacity")
                    settingKey: "freetype-shadow-opacity"
                    label: qsTr("Shadow opacity")
                    settingType: "integer"
                    editorKind: "opacity"
                    minimum: 0
                    maximum: 255
                    settingValue: { optionList.revision; return config.valueFor(settingKey) }
                    onCommit: value => config.setValue(settingKey, value)
                }

                PersonalizationActions {
                    width: Math.min(320, parent.width)
                    visible: root.selectedCategory === "interface" && !searchField.text.length
                    showProfiles: false
                    onCustomizeRequested: {
                        root.reject()
                        DialogsProvider.showToolbarEditorDialog()
                    }
                }
                ActionButton {
                    id: welcomeSetupAction
                    visible: root.selectedCategory === "general" && searchField.text.length > 0
                             && qsTr("Welcome setup").toLowerCase().includes(searchField.text.toLowerCase())
                    text: qsTr("Welcome setup")
                    onClicked: { root.reject(); DialogsProvider.firstRunDialog() }
                }


            }
        }

        Label {
            visible: config.error.length > 0 || audioOutput.error.length > 0 || root.profileError.length > 0 || inlineEffects.error.length > 0
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: VLCStyle.dp(24, VLCStyle.scale)
            text: root.profileError || audioOutput.error || inlineEffects.error || config.error
            color: VLCStyle.redesign.accent
            wrapMode: Text.WordWrap
            font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
            Accessible.role: Accessible.AlertMessage
        }
    }
}
