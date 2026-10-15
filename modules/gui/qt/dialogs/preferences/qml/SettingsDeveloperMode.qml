/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import VLC.MainInterface
import VLC.Style

ColumnLayout {
    id: root
    property bool selected: false
    property bool initial: false
    readonly property bool dirty: selected !== initial
    spacing: VLCStyle.dp(8, VLCStyle.scale)

    function begin() {
        initial = Boolean(MainCtx.settingValue("redesign/developer-mode", false))
        selected = initial
    }
    function cancel() { selected = initial }
    function resetDefaults() { selected = false }
    function save() {
        MainCtx.setSettingValue("redesign/developer-mode", selected)
        initial = selected
    }

    Label {
        Layout.fillWidth: true
        text: qsTr("Diagnostics")
        color: VLCStyle.redesign.color("#EAEAEA", "#2e2e2e")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
    }
    SettingsOptionRow {
        Layout.fillWidth: true
        settingKey: "developer-mode"
        label: qsTr("Developer mode")
        help: qsTr("Show advanced interface diagnostics")
        settingType: "boolean"
        settingValue: root.selected
        onCommit: value => root.selected = value
    }
}
