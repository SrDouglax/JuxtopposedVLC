/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Controls.Basic as C
import QtQuick.Layouts
import VLC.Style

ColumnLayout {
    id: root
    signal editRequested()
    signal resetRequested()
    spacing: VLCStyle.dp(12, VLCStyle.scale)
    C.Label {
        text: qsTr("Keyboard Shortcuts")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
        color: VLCStyle.redesign.color("#d2d2d2", "#333333")
        Layout.bottomMargin: VLCStyle.dp(12, VLCStyle.scale)
    }
    Repeater {
        model: [qsTr("Defaults"), qsTr("Reset all shortcuts")]
        RowLayout {
            required property string modelData
            required property int index
            Layout.fillWidth: true
            C.Label {
                Layout.fillWidth: true
                text: modelData
                color: VLCStyle.redesign.color("#949494", "#494949")
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }
            ActionButton {
                objectName: index === 0 ? "settingsEditShortcuts" : "settingsResetShortcuts"
                Layout.preferredWidth: Math.min(VLCStyle.dp(318, VLCStyle.scale), root.width * 0.46)
                text: index === 0 ? qsTr("Edit Keyboard Shortcuts") : qsTr("Reset")
                onClicked: index === 0 ? root.editRequested() : root.resetRequested()
            }
        }
    }
}
