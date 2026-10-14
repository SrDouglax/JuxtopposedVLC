/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 or later.
 *****************************************************************************/
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import VLC.Dialogs
import VLC.MainInterface
import VLC.Style

T.Popup {
    id: root
    objectName: "audioEffectsDialog"
    property int currentTab: 0
    property bool previousGlobalShortcuts: true
    property string profileError: ""
    readonly property var filterTabs: [
        { id: "equalizer", title: qsTr("Equalizer") },
        { id: "compressor", title: qsTr("Compressor") },
        { id: "spatializer", title: qsTr("Spatializer") },
        { id: "stereo_widen", title: qsTr("Stereo Widener") }
    ]

    function openNative(page) {
        if (audioBridge.transactionActive && !audioBridge.cancel()) return
        if (videoEffects.transactionActive && !videoEffects.cancel()) return
        root.close()
        DialogsProvider.nativeEffectsDialog(page)
    }

    function switchTab(index) {
        if (currentTab === index) return
        if (currentTab === 0 && audioBridge.transactionActive && !audioBridge.cancel()) return
        if (currentTab === 1 && videoEffects.transactionActive && !videoEffects.cancel()) return
        currentTab = index
        if (index === 0) audioBridge.begin()
        else videoEffects.begin()
    }

    AudioEffects { id: audioBridge; ctx: MainCtx }
    VideoEffects { id: videoEffects; ctx: MainCtx }

    width: Math.min(VLCStyle.dp(400, VLCStyle.scale), parent ? parent.width : VLCStyle.dp(400, VLCStyle.scale))
    height: Math.min(VLCStyle.dp(780, VLCStyle.scale), parent ? Math.max(0, parent.height - VLCStyle.dp(48, VLCStyle.scale)) : VLCStyle.dp(780, VLCStyle.scale))
    padding: 0
    modal: true
    focus: true
    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside
    anchors.centerIn: T.Overlay.overlay

    onOpened: {
        profileError = ""
        previousGlobalShortcuts = MainCtx.useGlobalShortcuts
        MainCtx.useGlobalShortcuts = false
        if (currentTab === 0) audioBridge.begin()
        else videoEffects.begin()
        tabs.itemAt(currentTab).forceActiveFocus()
    }
    onClosed: {
        if (audioBridge.transactionActive) audioBridge.cancel()
        if (videoEffects.transactionActive) videoEffects.cancel()
        MainCtx.useGlobalShortcuts = previousGlobalShortcuts
    }

    background: Rectangle {
        color: VLCStyle.redesign.windowBackground
        radius: VLCStyle.dp(6, VLCStyle.scale)
        border.color: VLCStyle.redesign.separator
    }

    contentItem: ColumnLayout {
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(54, VLCStyle.scale)
            Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(12, VLCStyle.scale)
            Text {
                text: qsTr("Effects")
                Layout.fillWidth: true
                color: VLCStyle.redesign.textPrimary
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(18, VLCStyle.scale)
                font.weight: Font.Medium
            }
            T.Button {
                implicitWidth: 32
                implicitHeight: 32
                text: qsTr("Close")
                focusPolicy: Qt.StrongFocus
                onClicked: root.close()
                contentItem: Text {
                    text: parent.text
                    color: VLCStyle.redesign.textSecondary
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                }
                background: Item {}
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Repeater {
                id: tabs
                model: [qsTr("Audio"), qsTr("Video")]
                delegate: T.Button {
                    id: tabButton
                    required property int index
                    required property string modelData
                    objectName: index === 0 ? "effectsAudioTab" : "effectsVideoTab"
                    Layout.fillWidth: true
                    implicitHeight: VLCStyle.dp(45, VLCStyle.scale)
                    focusPolicy: Qt.StrongFocus
                    onClicked: root.switchTab(index)
                    background: Rectangle {
                        color: tabButton.hovered ? VLCStyle.redesign.controlHoverBackground : "transparent"
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width - VLCStyle.dp(32, VLCStyle.scale)
                            height: VLCStyle.dp(2, VLCStyle.scale)
                            color: root.currentTab === index ? VLCStyle.redesign.accent : "transparent"
                        }
                    }
                    contentItem: Text {
                        text: tabButton.modelData
                        color: root.currentTab === index ? VLCStyle.redesign.accent : VLCStyle.redesign.textMuted
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: VLCStyle.redesign.separator }

        Flickable {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: body.implicitHeight + VLCStyle.dp(32, VLCStyle.scale)
            boundsBehavior: Flickable.StopAtBounds
            T.ScrollBar.vertical: T.ScrollBar {}

            ColumnLayout {
                id: body
                width: scroll.width - VLCStyle.dp(32, VLCStyle.scale)
                x: VLCStyle.dp(16, VLCStyle.scale)
                y: VLCStyle.dp(16, VLCStyle.scale)
                spacing: VLCStyle.dp(20, VLCStyle.scale)

                Text {
                    Layout.fillWidth: true
                    visible: root.currentTab === 0 && !audioBridge.activeAudio
                    text: audioBridge.lastError || qsTr("Play audio to preview and edit audio effects.")
                    color: VLCStyle.redesign.textSecondary
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    wrapMode: Text.WordWrap
                }

                Repeater {
                    model: root.currentTab === 0 && audioBridge.transactionActive ? root.filterTabs : []
                    FilterSection {
                        required property var modelData
                        Layout.fillWidth: true
                        effects: audioBridge
                        filterId: modelData.id
                        title: modelData.title
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.currentTab === 1 && !videoEffects.activeVideo
                    text: videoEffects.lastError || qsTr("Play video to preview and edit effects.")
                    color: VLCStyle.redesign.textSecondary
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    wrapMode: Text.WordWrap
                }

                VideoEffectsPanel {
                    Layout.fillWidth: true
                    visible: root.currentTab === 1 && videoEffects.transactionActive
                    effects: videoEffects
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.currentTab === 1
                    spacing: VLCStyle.dp(16, VLCStyle.scale)
                    T.Button {
                        text: qsTr("Open synchronization")
                        Layout.fillWidth: true
                        implicitHeight: VLCStyle.dp(42, VLCStyle.scale)
                        onClicked: root.openNative(2)
                        background: Rectangle { color: VLCStyle.redesign.controlBackground; radius: VLCStyle.dp(6, VLCStyle.scale) }
                        contentItem: Text {
                            text: parent.text
                            color: VLCStyle.redesign.textPrimary
                            font.family: VLCStyle.redesign.fontFamily
                            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: VLCStyle.dp(16, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(16, VLCStyle.scale)
            visible: !!root.profileError
                     || (root.currentTab === 0 ? audioBridge.lastError.length > 0 && audioBridge.transactionActive
                                               : videoEffects.lastError.length > 0 && videoEffects.transactionActive)
            text: root.profileError || (root.currentTab === 0 ? audioBridge.lastError : videoEffects.lastError)
            color: "#FF8989"
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
            wrapMode: Text.WordWrap
            Accessible.role: Accessible.AlertMessage
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: VLCStyle.redesign.separator }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(60, VLCStyle.scale)
            Layout.leftMargin: VLCStyle.dp(16, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(16, VLCStyle.scale)
            spacing: VLCStyle.dp(8, VLCStyle.scale)
            T.Button {
                text: qsTr("Cancel")
                Layout.fillWidth: true
                implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
                onClicked: {
                    if (root.currentTab === 0 ? audioBridge.cancel() : videoEffects.cancel()) root.close()
                }
                background: Rectangle { color: VLCStyle.redesign.controlBackground; radius: VLCStyle.dp(5, VLCStyle.scale) }
                contentItem: Text {
                    text: parent.text
                    color: VLCStyle.redesign.textSecondary
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            T.Button {
                text: qsTr("Save")
                Layout.fillWidth: true
                implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
                enabled: !!root.profileError || (root.currentTab === 0 ? audioBridge.transactionActive : videoEffects.transactionActive)
                onClicked: {
                    if (!root.profileError && !(root.currentTab === 0 ? audioBridge.save() : videoEffects.save()))
                        return
                    if (!MainCtx.controlbarProfileModel.save()) {
                        root.profileError = MainCtx.controlbarProfileModel.lastError
                        return
                    }
                    root.profileError = ""
                    root.close()
                }
                background: Rectangle { color: parent.enabled ? VLCStyle.redesign.accent : VLCStyle.redesign.controlBackground; radius: VLCStyle.dp(5, VLCStyle.scale) }
                contentItem: Text {
                    text: parent.text
                    color: parent.enabled ? "#0E0E0E" : VLCStyle.redesign.textDisabled
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
