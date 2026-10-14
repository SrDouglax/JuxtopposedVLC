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
    property int originIndex: 0
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
            Layout.preferredWidth: Math.min(VLCStyle.dp(220, VLCStyle.scale), root.width * .27)
            Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
            model: root.associations.targets
            textRole: "label"
            currentIndex: root.associations.selectedTarget
            enabled: !root.associations.busy
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            displayText: currentIndex === 0 ? root.initialTargetLabel :
                         currentIndex >= 0 ? model[currentIndex].kind + ": " + currentText : ""
            onActivated: (index) => root.associations.selectTarget(index)
            background: Rectangle { color: "#151515"; radius: VLCStyle.dp(4, VLCStyle.scale) }
            contentItem: Controls.Label {
                text: parent.displayText
                color: "#d0d0d0"
                font: parent.font
                leftPadding: VLCStyle.dp(12, VLCStyle.scale)
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }

        Widgets.ComboBoxExt {
            id: originPicker
            objectName: "subtitleOriginPicker"
            Layout.preferredWidth: Math.min(VLCStyle.dp(220, VLCStyle.scale), root.width * .27)
            Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
            model: [qsTr("From Computer"), qsTr("From Link"), qsTr("From OpenSubtitles")]
            currentIndex: root.originIndex
            enabled: !root.associations.busy
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            onActivated: (index) => root.originIndex = index
            background: Rectangle { color: "#151515"; radius: VLCStyle.dp(4, VLCStyle.scale) }
            contentItem: Controls.Label {
                text: parent.displayText
                color: "#d0d0d0"
                font: parent.font
                leftPadding: VLCStyle.dp(12, VLCStyle.scale)
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }

        Controls.Button {
            objectName: "subtitleChooseFilesButton"
            visible: root.originIndex === 0
            Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
            text: qsTr("Choose files")
            enabled: !root.associations.busy
            onClicked: root.associations.chooseFiles()
            background: Rectangle {
                color: parent.hovered ? "#252525" : "#151515"
                radius: VLCStyle.dp(4, VLCStyle.scale)
            }
            contentItem: Controls.Label {
                text: parent.text
                color: parent.enabled ? "#d0d0d0" : "#676767"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        Controls.Label {
            Layout.fillWidth: true
            visible: root.originIndex === 0
            text: root.associations.destinations.length === 1
                  ? root.associations.destinations[0].label
                  : qsTr("%1 media file", "%1 media files", root.associations.destinations.length)
                        .arg(root.associations.destinations.length)
            color: "#8f8f8f"
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            elide: Text.ElideMiddle
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
            color: "#d0d0d0"
            selectByMouse: true
            onAccepted: if (addButton.enabled) addButton.clicked()
            background: Rectangle {
                color: "#151515"
                border.color: linkField.activeFocus ? VLCStyle.redesign.accent : "#252525"
                radius: VLCStyle.dp(4, VLCStyle.scale)
            }
        }
        Controls.Button {
            id: addButton
            objectName: "subtitleAddLinkButton"
            text: qsTr("Add link")
            enabled: !root.associations.busy && linkField.text.trim().length > 0
            onClicked: root.associations.addLink(linkField.text.trim())
            background: Rectangle {
                color: parent.hovered ? "#252525" : "#151515"
                radius: VLCStyle.dp(4, VLCStyle.scale)
            }
            contentItem: Controls.Label {
                text: parent.text
                color: parent.enabled ? "#d0d0d0" : "#676767"
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
            color: "#8f8f8f"
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
        }
    }
}
