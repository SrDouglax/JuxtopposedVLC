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

import VLC.MainInterface
import VLC.MediaLibrary
import VLC.Style
import VLC.Widgets as Widgets

Dialog {
    id: root
    objectName: "subtitleAssociationsDialog"

    property string targetKind: qsTr("To This File")
    readonly property bool readyToSave: {
        const rows = associations.sources
        if (associations.busy || onlinePanel.busy || rows.length === 0 || associations.destinations.length === 0)
            return false
        for (let i = 0; i < rows.length; ++i) {
            if (rows[i].destination < 0)
                return false
        }
        return true
    }
    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
        palette: VLCStyle.palette
    }

    modal: true
    z: 100
    focus: true
    property bool previousGlobalShortcuts: true
    onOpened: {
        previousGlobalShortcuts = MainCtx.useGlobalShortcuts
        MainCtx.useGlobalShortcuts = false
    }
    closePolicy: associations.busy ? Popup.NoAutoClose : Popup.CloseOnEscape
    width: Math.min(VLCStyle.dp(1048, VLCStyle.scale),
                    parent ? parent.width - VLCStyle.margin_normal * 2 : VLCStyle.dp(1048, VLCStyle.scale))
    height: Math.min(VLCStyle.dp(800, VLCStyle.scale),
                     parent ? parent.height - VLCStyle.margin_normal * 2 : VLCStyle.dp(800, VLCStyle.scale))
    anchors.centerIn: parent
    padding: 0
    font.family: VLCStyle.redesign.fontFamily
    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)

    background: Rectangle {
        color: VLCStyle.redesign.color("#0e0e0e", "#c2c2c1")
        border.color: "#242424"
        radius: VLCStyle.dp(8, VLCStyle.scale)
    }

    function openFor(itemId) {
        const serialized = itemId.toString()
        targetKind = serialized.startsWith("VLC_ML_PARENT_FOLDER") ? qsTr("To This Folder")
                   : serialized.startsWith("VLC_ML_PARENT_PLAYLIST") ? qsTr("To This Playlist")
                   : qsTr("To This File")
        associations.open(itemId)
        open()
    }

    function openForUrl(url) {
        targetKind = qsTr("To This File")
        associations.openUrl(url)
        open()
    }

    onRejected: associations.cancel()
    onClosed: {
        associations.cancel()
        onlinePanel.clearCredentials()
        MainCtx.useGlobalShortcuts = previousGlobalShortcuts
    }

    MLSubtitleAssociations {
        id: associations
        ml: MediaLib
        onSaved: root.close()
    }

    header: Rectangle {
        color: VLCStyle.redesign.color("#0e0e0e", "#c2c2c1")
        implicitHeight: VLCStyle.dp(42, VLCStyle.scale)

        Label {
            anchors.left: parent.left
            anchors.leftMargin: VLCStyle.dp(24, VLCStyle.scale)
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Add Subtitles")
            color: VLCStyle.redesign.color("#8f8f8f", "#7c7c7b")
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }

        Button {
            objectName: "subtitleCloseButton"
            anchors.right: parent.right
            anchors.rightMargin: VLCStyle.dp(16, VLCStyle.scale)
            anchors.verticalCenter: parent.verticalCenter
            width: VLCStyle.dp(24, VLCStyle.scale)
            height: width
            text: "×"
            enabled: !associations.busy
            onClicked: root.reject()
            background: Item {}
            contentItem: Label {
                text: parent.text
                color: parent.enabled ? VLCStyle.redesign.color("#8f8f8f", "#7c7c7b") : "#4c4c4c"
                font.pixelSize: VLCStyle.dp(24, VLCStyle.scale)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    contentItem: ColumnLayout {
        readonly property ColorContext colorContext: ColorContext {
            palette: VLCStyle.palette
            colorSet: ColorContext.Window
        }
        spacing: 0

        SubtitleSourceControls {
            id: sourceControls
            Layout.fillWidth: true
            Layout.leftMargin: VLCStyle.dp(24, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(24, VLCStyle.scale)
            Layout.topMargin: VLCStyle.dp(12, VLCStyle.scale)
            associations: associations
            initialTargetLabel: root.targetKind
        }

        OpenSubtitlesPanel {
            id: onlinePanel
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: VLCStyle.dp(24, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(24, VLCStyle.scale)
            Layout.topMargin: VLCStyle.dp(20, VLCStyle.scale)
            visible: sourceControls.online
            associations: associations
            onDownloadReady: sourceControls.originIndex = 0
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !sourceControls.online
            Layout.topMargin: VLCStyle.dp(30, VLCStyle.scale)
            Layout.leftMargin: VLCStyle.dp(24, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(24, VLCStyle.scale)
            clip: true

            ListView {
                model: associations.sources
                spacing: VLCStyle.dp(8, VLCStyle.scale)
                delegate: ColumnLayout {
                    id: sourceRow
                    required property int index
                    required property var modelData
                    width: ListView.view.width
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: VLCStyle.dp(40, VLCStyle.scale)
                        spacing: VLCStyle.dp(12, VLCStyle.scale)

                        Image {
                            Layout.preferredWidth: VLCStyle.dp(24, VLCStyle.scale)
                            Layout.preferredHeight: width
                            source: "qrc:///redesign/video.svg"
                            fillMode: Image.PreserveAspectFit
                        }

                        Widgets.ComboBoxExt {
                            colorContext.palette: theme.palette
                            objectName: "subtitleDestinationSelector"
                            Layout.preferredWidth: Math.min(VLCStyle.dp(280, VLCStyle.scale), root.width * 0.28)
                            Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
                            model: associations.destinations
                            textRole: "label"
                            currentIndex: modelData.destination
                            enabled: !associations.busy
                            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                            displayText: currentIndex < 0 ? qsTr("Choose media") : currentText
                            background: Rectangle {
                                color: parent.hovered || parent.activeFocus ? VLCStyle.redesign.color("#151515", "#dedede") : "transparent"
                                radius: VLCStyle.dp(4, VLCStyle.scale)
                            }
                            contentItem: Label {
                                text: parent.displayText
                                color: VLCStyle.redesign.color("#8f8f8f", "#7c7c7b")
                                font: parent.font
                                elide: Text.ElideMiddle
                                verticalAlignment: Text.AlignVCenter
                            }
                            onActivated: (destinationIndex) => associations.assign(sourceRow.index, destinationIndex)
                        }

                        Canvas {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 2
                            onWidthChanged: requestPaint()
                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                ctx.strokeStyle = "#454545"
                                ctx.setLineDash([6, 6])
                                ctx.beginPath()
                                ctx.moveTo(0, 1)
                                ctx.lineTo(width, 1)
                                ctx.stroke()
                            }
                        }

                        Image {
                            Layout.preferredWidth: VLCStyle.dp(24, VLCStyle.scale)
                            Layout.preferredHeight: width
                            source: "qrc:///redesign/subtitle-file.png"
                            fillMode: Image.PreserveAspectFit
                        }

                        Label {
                            Layout.preferredWidth: Math.min(VLCStyle.dp(280, VLCStyle.scale), root.width * 0.28)
                            text: modelData.label
                            color: VLCStyle.redesign.color("#d0d0d0", "#2e2e2e")
                            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                            elide: Text.ElideMiddle
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: VLCStyle.dp(36, VLCStyle.scale)
                        visible: modelData.issue.length > 0
                        text: modelData.issue
                        color: "#a87b52"
                        font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            Layout.leftMargin: VLCStyle.dp(24, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(24, VLCStyle.scale)
            visible: associations.error.length > 0 || associations.sources.length === 0
            text: associations.error.length > 0 ? associations.error :
                  sourceControls.originIndex === 1 ? qsTr("Enter a direct subtitle link above.") :
                  qsTr("Choose subtitle files from your computer.")
            color: associations.error.length > 0 ? "#d37918" : VLCStyle.redesign.color("#8f8f8f", "#7c7c7b")
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
            elide: Text.ElideRight
        }
    }

    footer: RowLayout {
        spacing: VLCStyle.dp(12, VLCStyle.scale)
        implicitHeight: VLCStyle.dp(68, VLCStyle.scale)

        Item { Layout.preferredWidth: VLCStyle.dp(24, VLCStyle.scale) }
        Button {
            objectName: "subtitleCancelButton"
            text: qsTr("Cancel")
            enabled: !associations.busy
            onClicked: root.reject()
            background: Item {}
            contentItem: Label {
                text: parent.text
                color: parent.enabled ? VLCStyle.redesign.color("#8f8f8f", "#7c7c7b") : "#4c4c4c"
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                verticalAlignment: Text.AlignVCenter
            }
        }

        Item { Layout.fillWidth: true }

        Button {
            objectName: "subtitleSaveButton"
            text: qsTr("Save")
            enabled: root.readyToSave
            onClicked: associations.save()
            Layout.preferredWidth: VLCStyle.dp(112, VLCStyle.scale)
            Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
            contentItem: Label {
                text: parent.text
                color: parent.enabled ? "#d37918" : "#73512f"
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.enabled ? "#371f06" : "#211a13"
                radius: VLCStyle.dp(4, VLCStyle.scale)
            }
        }
        Item { Layout.preferredWidth: VLCStyle.dp(24, VLCStyle.scale) }
    }
}
