/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import VLC.Dialogs
import VLC.MainInterface
import VLC.Player
import VLC.Style

ColumnLayout {
    id: root
    property int selectedIndex: -1
    readonly property bool dirty: preview.dirty
    readonly property string error: preview.lastError
    spacing: VLCStyle.dp(5, VLCStyle.scale)

    function begin() { if (!preview.active) preview.begin() }
    function canApply() { return preview.canCommit() }
    function apply() { return preview.commit() }
    function cancel() { return preview.cancel() }
    function reset() { if (preview.cancel()) preview.begin() }

    AudioOutputPreview { id: preview; ctx: MainCtx }
    Repeater {
        id: deviceRows
        model: Player.audioDevices
        onCountChanged: {
            if (count > 0 && root.visible && !preview.active) root.begin()
            if (count === 0) root.selectedIndex = -1
        }
        Item {
            required property int index
            required property bool checked
            visible: false
            onCheckedChanged: { if (checked) root.selectedIndex = index }
            Component.onCompleted: { if (checked) root.selectedIndex = index }
        }
    }
    Connections {
        target: Player.audioDevices
        function onModelReset() { root.selectedIndex = -1 }
    }
    RowLayout {
        Layout.fillWidth: true
        Label {
            Layout.fillWidth: true
            text: qsTr("Current output device")
            color: VLCStyle.redesign.textMuted
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }
        ComboBox {
            id: deviceBox
            objectName: "settingsOutputDevice"
            Layout.preferredWidth: VLCStyle.dp(319, VLCStyle.scale)
            enabled: preview.active && deviceRows.count > 0
            model: Player.audioDevices
            textRole: "display"
            Binding { target: deviceBox; property: "currentIndex"; value: root.selectedIndex; when: !deviceBox.popup.visible }
            onActivated: (index) => preview.preview(index, textAt(index))
            contentItem: Label {
                leftPadding: VLCStyle.dp(12, VLCStyle.scale)
                text: deviceRows.count === 0 ? qsTr("No selectable device available")
                      : root.selectedIndex < 0 ? qsTr("System default") : deviceBox.displayText
                color: VLCStyle.redesign.textSecondary
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }
            background: Rectangle {
                color: VLCStyle.redesign.controlBackground
                border.color: VLCStyle.redesign.border
                radius: 4
            }
            delegate: ItemDelegate {
                required property string display
                width: deviceBox.width
                text: display
                palette.text: VLCStyle.redesign.textPrimary
                background: Rectangle {
                    color: highlighted ? VLCStyle.redesign.controlHoverBackground
                                       : VLCStyle.redesign.controlBackground
                }
            }
            popup: Popup {
                y: deviceBox.height
                width: deviceBox.width
                implicitHeight: Math.min(contentItem.implicitHeight, VLCStyle.dp(280, VLCStyle.scale))
                padding: 0
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: deviceBox.popup.visible ? deviceBox.delegateModel : null
                    currentIndex: deviceBox.highlightedIndex
                }
                background: Rectangle {
                    color: VLCStyle.redesign.controlBackground
                    border.color: VLCStyle.redesign.border
                }
            }
        }
    }
    Label {
        Layout.fillWidth: true
        text: qsTr("Device changes affect only the current audio output. Apply keeps this selection while it remains active.")
        wrapMode: Text.WordWrap
        color: VLCStyle.redesign.textMuted
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
    }
}
