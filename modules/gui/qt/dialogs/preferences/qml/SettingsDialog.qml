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
    readonly property bool dark: VLCStyle.palette.isDark
    readonly property bool appearanceDirty: appearance.dirty
    readonly property bool hasChanges: config.dirty || appearanceDirty

    readonly property var titles: ({
        extensions: qsTr("VLC Addons"),
        general: qsTr("Global Settings"), interface: qsTr("Interface Settings"),
        privacy: qsTr("Privacy Settings"), controls: qsTr("Controls Settings"),
        playback: qsTr("Playback Settings"), video: qsTr("Video Settings"),
        audio: qsTr("Audio Settings"), subtitles: qsTr("Subtitles Settings"),
        library: qsTr("Library Settings"), network: qsTr("Network Connections & Security"),
        performance: qsTr("Performance Settings"), recording: qsTr("Recording Settings")
    })

    function openSettings(category) {
        selectedCategory = category || "general"
        searchField.text = ""
        open()
    }

    function saveSettings() {
        if (!config.apply())
            return
        appearance.save()
        saved = true
        close()
    }

    onOpened: {
        saved = false
        previousGlobalShortcuts = MainCtx.useGlobalShortcuts
        MainCtx.useGlobalShortcuts = false
        config.reload()
        appearance.begin()
    }
    onClosed: {
        if (!saved) {
            config.cancel()
            appearance.cancel()
        }
        MainCtx.useGlobalShortcuts = previousGlobalShortcuts
    }

    ShortcutsDialog { id: shortcutsDialog; parent: root.parent }

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
                    anchors.leftMargin: 12
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
                    leftPadding: 42
                    rightPadding: 10
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
                anchors.rightMargin: 15
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                onClicked: root.reject()
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
            anchors.topMargin: VLCStyle.dp(29, VLCStyle.scale)
            anchors.bottom: footer.top
            anchors.bottomMargin: 8
            contentHeight: contentColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            Column {
                id: contentColumn
                width: contentFlick.width - (contentFlick.contentHeight > contentFlick.height ? 12 : 0)
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
                SettingsOptionList {
                    id: optionList
                    visible: !extensions.visible
                    width: parent.width
                    settingsModel: config
                    category: root.selectedCategory
                    search: searchField.text
                }

                Label {
                    visible: optionList.count === 0 && !appearance.visible
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
                    width: parent.width
                    height: VLCStyle.dp(38, VLCStyle.scale)
                    text: qsTr("Advanced Options  ›")
                    onClicked: DialogsProvider.nativePrefsDialog()
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

                PersonalizationActions {
                    width: Math.min(320, parent.width)
                    visible: root.selectedCategory === "interface" && !searchField.text.length
                }
                ActionButton {
                    visible: root.selectedCategory === "general" && !searchField.text.length
                    text: qsTr("Welcome setup")
                    onClicked: { root.reject(); DialogsProvider.firstRunDialog() }
                }

                ActionButton {
                    visible: root.selectedCategory === "audio" || root.selectedCategory === "video"
                    width: parent.width
                    text: qsTr("Adjustments and Effects")
                    onClicked: {
                        root.reject()
                        if (root.selectedCategory === "video") DialogsProvider.nativeEffectsDialog(1)
                        else DialogsProvider.extendedDialog()
                    }
                }
                ActionButton {
                    visible: root.selectedCategory === "controls"
                    width: parent.width
                    text: qsTr("Keyboard shortcuts")
                    onClicked: shortcutsDialog.open()
                }
            }
        }

        Rectangle {
            id: footer
            anchors.left: sidebar.right
            anchors.leftMargin: VLCStyle.dp(32, VLCStyle.scale)
            anchors.right: parent.right
            anchors.rightMargin: VLCStyle.dp(24, VLCStyle.scale)
            anchors.bottom: parent.bottom
            height: VLCStyle.dp(63, VLCStyle.scale)
            color: "transparent"
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; height: 1; color: root.dark ? "#242424" : "#d6d6d6" }

            Label {
                id: errorLabel
                visible: config.error.length > 0
                anchors.left: resetButton.right
                anchors.leftMargin: 10
                anchors.right: cancelButton.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: config.error
                color: "#e7a466"
                elide: Text.ElideRight
                font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
            }

            Button {
                id: resetButton
                objectName: "settingsReset"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Reset category")
                enabled: !searchField.text.length && root.selectedCategory !== "extensions"
                onClicked: {
                    config.resetCategory()
                    if (root.selectedCategory === "general")
                        appearance.resetDefaults()
                }
                background: Rectangle { color: root.dark ? "#1a1a1a" : "#e9e9e9"; radius: 3 }
                contentItem: Label { text: parent.text; color: root.dark ? "#999999" : "#444444"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
            Button {
                id: applyButton
                objectName: "settingsApply"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: VLCStyle.dp(88, VLCStyle.scale)
                text: qsTr("Apply")
                enabled: root.hasChanges
                onClicked: root.saveSettings()
                background: Rectangle {
                    color: applyButton.enabled ? (root.dark ? "#371f06" : "#f7e2c9")
                                               : (root.dark ? "#242424" : "#eeeeee")
                    radius: 3
                }
                contentItem: Label {
                    text: parent.text
                    color: applyButton.enabled ? VLCStyle.redesign.accent
                                               : (root.dark ? "#666666" : "#999999")
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                }
            }
            Button {
                id: cancelButton
                objectName: "settingsCancel"
                anchors.right: applyButton.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Cancel")
                onClicked: root.reject()
                background: Rectangle { color: root.dark ? "#1a1a1a" : "#e9e9e9"; radius: 3 }
                contentItem: Label {
                    text: parent.text
                    color: root.dark ? "#aaaaaa" : "#444444"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                }
            }
        }
    }
}
