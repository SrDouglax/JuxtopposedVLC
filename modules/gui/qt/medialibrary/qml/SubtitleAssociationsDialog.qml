/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *****************************************************************************/
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import VLC.MediaLibrary
import VLC.Widgets as Widgets
import VLC.Style
import VLC.MainInterface

Dialog {
    id: root
    objectName: "subtitleAssociationsDialog"

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
        palette: VLCStyle.palette
    }

    title: qsTr("Add subtitles")
    modal: true
    focus: true
    property bool previousGlobalShortcuts: true
    onOpened: {
        previousGlobalShortcuts = MainCtx.useGlobalShortcuts
        MainCtx.useGlobalShortcuts = false
    }
    closePolicy: associations.busy ? Popup.NoAutoClose : Popup.CloseOnEscape
    width: Math.min(VLCStyle.dp(620, VLCStyle.scale),
                    parent ? parent.width - VLCStyle.margin_normal * 2 : 620)
    height: Math.min(VLCStyle.dp(460, VLCStyle.scale),
                     parent ? parent.height - VLCStyle.margin_normal * 2 : 460)
    anchors.centerIn: parent
    padding: VLCStyle.margin_normal
    font.family: VLCStyle.redesign.fontFamily
    font.pixelSize: VLCStyle.fontSize_normal

    background: Rectangle {
        color: VLCStyle.redesign.color(VLCStyle.redesign.sidebarBackground, theme.bg.primary)
        border.color: theme.border
        radius: VLCStyle.dp(12, VLCStyle.scale)
    }

    function openFor(itemId) {
        associations.open(itemId)
        open()
    }

    function openForUrl(url) {
        associations.openUrl(url)
        open()
    }

    onRejected: associations.cancel()
    onClosed: {
        associations.cancel()
        MainCtx.useGlobalShortcuts = previousGlobalShortcuts
    }

    MLSubtitleAssociations {
        id: associations
        ml: MediaLib
        onSaved: root.close()
    }

    header: Label {
        text: root.title
        color: theme.fg.primary
        font.family: VLCStyle.redesign.fontFamily
        font.weight: Font.DemiBold
        padding: VLCStyle.margin_normal
        background: Rectangle { color: VLCStyle.redesign.color(VLCStyle.redesign.sidebarBackground, theme.bg.primary) }
    }

    contentItem: ColumnLayout {
        spacing: 12

        Label {
            Layout.fillWidth: true
            text: qsTr("Choose subtitle files, then check the media assigned to each one.")
            wrapMode: Text.WordWrap
            color: theme.fg.primary
        }

        Widgets.ButtonExt {
            colorContext.palette: theme.palette
            objectName: "subtitleChooseFilesButton"
            text: qsTr("Choose subtitle files…")
            enabled: !associations.busy
            onClicked: {
                const previous = MainCtx.useGlobalShortcuts
                MainCtx.useGlobalShortcuts = false
                try { associations.chooseFiles() }
                finally { MainCtx.useGlobalShortcuts = previous }
            }
        }

        Label {
            Layout.fillWidth: true
            visible: associations.destinations.length === 0 && !associations.busy
            text: qsTr("Select a media file, folder, or playlist to add subtitles.")
            wrapMode: Text.WordWrap
            color: theme.fg.secondary
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                model: associations.sources
                spacing: 8
                delegate: RowLayout {
                    id: sourceRow
                    required property int index
                    required property var modelData
                    width: ListView.view.width
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        Label {
                            Layout.fillWidth: true
                            text: modelData.label
                            elide: Text.ElideMiddle
                            color: theme.fg.primary
                        }
                        Label {
                            Layout.fillWidth: true
                            visible: modelData.issue.length > 0
                            text: modelData.issue
                            wrapMode: Text.WordWrap
                            color: theme.fg.secondary
                        }
                    }

                    Widgets.ComboBoxExt {
                        colorContext.palette: theme.palette
                        objectName: "subtitleDestinationSelector"
                        Layout.preferredWidth: 220
                        model: associations.destinations
                        textRole: "label"
                        currentIndex: modelData.destination
                        enabled: !associations.busy
                        displayText: currentIndex < 0 ? qsTr("Choose media") : currentText
                        onActivated: (destinationIndex) => associations.assign(sourceRow.index, destinationIndex)
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            visible: associations.error.length > 0
            text: associations.error
            wrapMode: Text.WordWrap
            color: theme.fg.primary
        }
    }

    footer: RowLayout {
        spacing: 8
        Item { Layout.fillWidth: true }
        Widgets.ButtonExt {
            colorContext.palette: theme.palette
            objectName: "subtitleCancelButton"
            text: qsTr("Cancel")
            enabled: !associations.busy
            onClicked: root.reject()
        }
        Widgets.ButtonExt {
            colorContext.palette: theme.palette
            objectName: "subtitleSaveButton"
            text: qsTr("Save associations")
            enabled: !associations.busy && associations.sources.length > 0
            onClicked: associations.save()
        }
    }
}
