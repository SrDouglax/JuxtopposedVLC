/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 or later.
 *****************************************************************************/
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls

import VLC.Style
import VLC.Widgets as Widgets

ColumnLayout {
    id: root
    required property var associations
    required property string initialTargetLabel
    property alias onlineSearchHost: onlineHost
    property bool onlineBusy: false
    property bool audioTracks: false
    property int originIndex: 0
    readonly property string sourceDirectory: {
        const urls = associations.sources.map(source => source.url.toString())
        if (!urls.length) return ""
        const folders = urls.map(url => url.slice(0, url.lastIndexOf("/")))
        if (folders.some(folder => folder !== folders[0])) return qsTr("Multiple folders")
        return decodeURIComponent(folders[0].replace(/^file:\/\//, ""))
            .split("/").filter(part => part.length > 0).join(" / ")
    }
    readonly property bool online: originIndex === 2
    spacing: VLCStyle.dp(10, VLCStyle.scale)
    onOriginIndexChanged: originPicker.currentIndex = originIndex
    Connections {
        target: root.associations
        function onTargetsChanged() { targetPicker.currentIndex = root.associations.selectedTarget }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: VLCStyle.dp(12, VLCStyle.scale)

        Widgets.ComboBoxExt {
            id: targetPicker
            objectName: "subtitleTargetPicker"
            Layout.minimumWidth: VLCStyle.dp(140, VLCStyle.scale)
            Layout.preferredWidth: VLCStyle.dp(200, VLCStyle.scale)
            Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
            model: root.associations.targets
            textRole: "label"
            currentIndex: root.associations.selectedTarget
            enabled: !root.associations.busy && !root.onlineBusy
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            displayText: currentIndex === 0 ? root.initialTargetLabel :
                         currentIndex >= 0 ? model[currentIndex].kind + ": " + currentText : ""
            onActivated: (index) => root.associations.selectTarget(index)
            background: Rectangle { color: VLCStyle.redesign.color("#151515", "#dedede"); radius: VLCStyle.dp(4, VLCStyle.scale) }
            contentItem: Controls.Label {
                text: parent.displayText
                color: VLCStyle.redesign.color("#d0d0d0", "#2e2e2e")
                font: parent.font
                leftPadding: VLCStyle.dp(12, VLCStyle.scale)
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }

        Widgets.ComboBoxExt {
            id: originPicker
            objectName: "subtitleOriginPicker"
            Layout.minimumWidth: VLCStyle.dp(140, VLCStyle.scale)
            Layout.preferredWidth: VLCStyle.dp(200, VLCStyle.scale)
            Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
            model: root.audioTracks ? [qsTr("From Computer")] : [qsTr("From Computer"), qsTr("From Link"), qsTr("From OpenSubtitles")]
            currentIndex: root.originIndex
            enabled: !root.associations.busy && !root.onlineBusy
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            onActivated: (index) => root.originIndex = index
            background: Rectangle { color: VLCStyle.redesign.color("#151515", "#dedede"); radius: VLCStyle.dp(4, VLCStyle.scale) }
            contentItem: Controls.Label {
                text: parent.displayText
                color: VLCStyle.redesign.color("#d0d0d0", "#2e2e2e")
                font: parent.font
                leftPadding: VLCStyle.dp(12, VLCStyle.scale)
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }

        Item {
            id: onlineHost
            visible: root.online
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
        }

        Controls.Button {
            objectName: "subtitleChooseFilesButton"
            visible: root.originIndex === 0
            Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
            Layout.fillWidth: true
            text: root.sourceDirectory.length ? root.sourceDirectory : qsTr("Choose files")
            enabled: !root.associations.busy && !root.onlineBusy
            onClicked: root.associations.chooseFiles()
            background: Rectangle {
                color: parent.hovered ? VLCStyle.redesign.color("#252525", "#929291") : VLCStyle.redesign.color("#151515", "#dedede")
                radius: VLCStyle.dp(4, VLCStyle.scale)
            }
            contentItem: RowLayout {
                spacing: VLCStyle.dp(12, VLCStyle.scale)
                Image {
                    Layout.preferredWidth: VLCStyle.dp(24, VLCStyle.scale)
                    Layout.preferredHeight: width
                    source: "qrc:///redesign/folder.svg"
                }
                Controls.Label {
                    Layout.fillWidth: true
                    text: root.sourceDirectory.length ? root.sourceDirectory : qsTr("Choose files")
                    color: VLCStyle.redesign.textMuted
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    elide: Text.ElideMiddle
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.originIndex === 1
        spacing: VLCStyle.dp(12, VLCStyle.scale)
        Controls.TextField {
            id: linkField
            objectName: "subtitleLinkField"
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
            placeholderText: qsTr("Direct HTTPS link to a subtitle file")
            placeholderTextColor: VLCStyle.redesign.color("#969696", "#4d4d4d")
            color: VLCStyle.redesign.color("#d0d0d0", "#2e2e2e")
            selectByMouse: true
            onAccepted: if (addButton.enabled) addButton.clicked()
            background: Rectangle {
                color: VLCStyle.redesign.color("#151515", "#dedede")
                border.color: linkField.activeFocus ? VLCStyle.redesign.accent : VLCStyle.redesign.color("#252525", "#929291")
                radius: VLCStyle.dp(4, VLCStyle.scale)
            }
        }
        Controls.Button {
            id: addButton
            objectName: "subtitleAddLinkButton"
            text: qsTr("Add link")
            enabled: !root.associations.busy && !root.onlineBusy && linkField.text.trim().length > 0
            onClicked: root.associations.addLink(linkField.text.trim())
            background: Rectangle {
                color: parent.hovered ? VLCStyle.redesign.color("#252525", "#929291") : VLCStyle.redesign.color("#151515", "#dedede")
                radius: VLCStyle.dp(4, VLCStyle.scale)
            }
            contentItem: Controls.Label {
                text: parent.text
                color: parent.enabled ? VLCStyle.redesign.color("#d0d0d0", "#2e2e2e") : VLCStyle.redesign.color("#676767", "#7c7c7b")
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    RowLayout {
        visible: root.associations.busy
        spacing: VLCStyle.dp(8, VLCStyle.scale)
        Controls.BusyIndicator {
            Layout.preferredWidth: VLCStyle.dp(22, VLCStyle.scale)
            Layout.preferredHeight: Layout.preferredWidth
            running: visible
        }
        Controls.Label {
            text: qsTr("Working on subtitles…")
            color: VLCStyle.redesign.color("#8f8f8f", "#7c7c7b")
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
        }
    }
}
