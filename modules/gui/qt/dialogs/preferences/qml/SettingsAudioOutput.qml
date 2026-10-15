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
    required property var settingsModel
    property int revision: 0
    property int selectedIndex: -1
    readonly property bool dirty: preview.dirty
    readonly property string error: preview.lastError
    spacing: 0

    function begin() {
        if (!preview.active && preview.begin()) selectedIndex = preview.currentIndex()
    }
    function canApply() { return preview.canCommit() }
    function apply() { return preview.commit() }
    function cancel() { return preview.cancel() }
    function reset() { if (preview.cancel()) begin() }

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
    Connections {
        target: root.settingsModel
        function onDataChanged() { ++root.revision }
        function onModelReset() { ++root.revision }
    }
    Label {
        Layout.fillWidth: true
        Layout.preferredHeight: VLCStyle.dp(28, VLCStyle.scale)
        text: qsTr("Output")
        color: VLCStyle.redesign.color("#d2d2d2", "#252525")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
    }
    SettingsOptionRow {
        Layout.fillWidth: true
        settingKey: "audio"
        label: qsTr("Enable audio")
        settingType: "boolean"
        settingValue: { root.revision; return root.settingsModel.valueFor("audio") }
        onCommit: value => root.settingsModel.setValue("audio", value)
    }
    RowLayout {
        Layout.preferredHeight: VLCStyle.dp(46, VLCStyle.scale)
        Layout.fillWidth: true
        Label {
            Layout.fillWidth: true
            text: qsTr("Output device")
            color: VLCStyle.redesign.color("#8F8F8F", "#7c7c7b")
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }
        ComboBox {
            id: deviceBox
            objectName: "settingsOutputDevice"
            Layout.preferredWidth: VLCStyle.dp(320, VLCStyle.scale)
            Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
            enabled: preview.active && deviceRows.count > 0
            model: Player.audioDevices
            textRole: "display"
            Binding { target: deviceBox; property: "currentIndex"; value: root.selectedIndex; when: !deviceBox.popup.visible }
            onActivated: (index) => {
                if (preview.preview(index, textAt(index))) root.selectedIndex = index
            }
            indicator: Image {
                x: deviceBox.width - width - 10
                y: (deviceBox.height - height) / 2
                width: VLCStyle.dp(18, VLCStyle.scale)
                height: width
                source: "qrc:///redesign/icons/chevron-down/default.png"
            }
            contentItem: Label {
                leftPadding: VLCStyle.dp(12, VLCStyle.scale)
                text: deviceRows.count === 0 ? qsTr("No selectable device available")
                      : root.selectedIndex < 0 ? qsTr("System default") : deviceBox.displayText
                color: VLCStyle.redesign.color("#969696", "#4d4d4d")
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }
            background: Rectangle {
                color: VLCStyle.redesign.color("#191919", "#ababaa")
                border.color: VLCStyle.redesign.color("#373737", "#8e8e8d")
                radius: 4
            }
            delegate: ItemDelegate {
                required property var model
                width: deviceBox.width
                text: model.display
                palette.text: VLCStyle.redesign.color("#EAEAEA", "#2e2e2e")
                background: Rectangle {
                    color: highlighted ? VLCStyle.redesign.color("#222222", "#9c9c9b")
                                       : VLCStyle.redesign.color("#191919", "#ababaa")
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
                    color: VLCStyle.redesign.color("#191919", "#ababaa")
                    border.color: VLCStyle.redesign.color("#373737", "#8e8e8d")
                }
            }
        }
    }
    SettingsOptionRow {
        Layout.fillWidth: true
        settingKey: "stereo-mode"
        label: qsTr("Speaker setup")
        settingType: "integer"
        settingValue: { root.revision; return root.settingsModel.valueFor("stereo-mode") }
        choices: root.settingsModel.optionFor("stereo-mode").choices || []
        onCommit: value => root.settingsModel.setValue("stereo-mode", value)
    }
}
