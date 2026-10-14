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
    RowLayout {
        Layout.fillWidth: true
        implicitHeight: VLCStyle.dp(42, VLCStyle.scale)
        Label {
            Layout.fillWidth: true
            text: qsTr("Developer mode")
            color: VLCStyle.redesign.color("#8F8F8F", "#7c7c7b")
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }
        Switch {
            id: developerSwitch
            objectName: "settingsDeveloperMode"
            Binding on checked { when: !developerSwitch.pressed; value: root.selected }
            onClicked: root.selected = checked
            indicator: Rectangle {
                implicitWidth: VLCStyle.dp(40, VLCStyle.scale)
                implicitHeight: VLCStyle.dp(22, VLCStyle.scale)
                radius: height / 2
                color: developerSwitch.checked ? VLCStyle.redesign.accent : "#373737"
                Rectangle {
                    x: developerSwitch.checked ? parent.width - width - 3 : 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: VLCStyle.dp(16, VLCStyle.scale)
                    height: width
                    radius: width / 2
                    color: "#eaeaea"
                }
            }
        }
    }
}
