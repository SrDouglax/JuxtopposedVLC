/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import VLC.Player
import VLC.Style

ColumnLayout {
    id: root
    property string currentDevice: ""
    spacing: VLCStyle.dp(4, VLCStyle.scale)

    Repeater {
        id: deviceRows
        model: Player.audioDevices
        Item {
            required property string display
            required property bool checked
            visible: false
            onCheckedChanged: { if (checked) root.currentDevice = display }
            Component.onCompleted: { if (checked) root.currentDevice = display }
        }
    }
    Connections {
        target: Player.audioDevices
        function onModelReset() { root.currentDevice = "" }
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
        Label {
            Layout.preferredWidth: VLCStyle.dp(319, VLCStyle.scale)
            text: deviceRows.count === 0 ? qsTr("No selectable device available")
                                         : root.currentDevice || qsTr("System default")
            elide: Text.ElideRight
            color: VLCStyle.redesign.textSecondary
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }
    }
    Label {
        Layout.fillWidth: true
        text: qsTr("Choose a playback device from the Audio menu while media plays. Device selection applies to the current output.")
        wrapMode: Text.WordWrap
        color: VLCStyle.redesign.textMuted
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
    }
}
