/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Controls.Basic as Controls
import VLC.Dialogs
import VLC.MainInterface
import VLC.Style
Controls.Popup {
    id: root
    objectName: "hdrOutputDialog"
    property bool previousShortcuts: true
    width: Math.min(VLCStyle.dp(400, VLCStyle.scale), parent.width - 32)
    height: Math.min(VLCStyle.dp(445, VLCStyle.scale), parent.height - 48)
    padding: VLCStyle.dp(20, VLCStyle.scale)
    focus: true
    closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside
    onOpened: { previousShortcuts = MainCtx.useGlobalShortcuts; MainCtx.useGlobalShortcuts = false }
    onClosed: MainCtx.useGlobalShortcuts = previousShortcuts
    HdrOutput { id: output; ctx: MainCtx }
    background: Rectangle { color: VLCStyle.redesign.color("#191919", "#c2c2c1"); radius: 6 }
    contentItem: Column {
        spacing: 8
        Text {
            text: output.selectedIndex >= 0 ? output.choices[output.selectedIndex].label : qsTr("HDR unavailable")
            height: VLCStyle.dp(40, VLCStyle.scale)
            color: VLCStyle.redesign.color("#969696", "#4d4d4d")
            font.family: VLCStyle.redesign.fontFamily; font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }
        Repeater {
            model: output.choices
            delegate: Controls.ItemDelegate {
                id: row
                required property int index
                required property var modelData
                width: root.availableWidth
                height: VLCStyle.dp(46, VLCStyle.scale)
                enabled: modelData.enabled
                onClicked: output.select(index)
                Controls.ToolTip.visible: hovered && modelData.reason.length > 0
                Controls.ToolTip.text: modelData.reason
                background: Rectangle {
                    radius: 4
                    color: row.hovered || output.selectedIndex === row.index ? VLCStyle.redesign.color("#222222", "#ababaa") : "transparent"
                    border.color: row.visualFocus ? VLCStyle.redesign.accent : "transparent"
                }
                contentItem: Row {
                    Text {
                        width: row.width - 54; height: parent.height
                        text: row.modelData.label; opacity: row.enabled ? 1 : 0.45
                        color: VLCStyle.redesign.color("#969696", "#4d4d4d")
                        font.family: VLCStyle.redesign.fontFamily; font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                        verticalAlignment: Text.AlignVCenter
                    }
                    Image { width: 24; height: 24; anchors.verticalCenter: parent.verticalCenter
                        source: "qrc:///redesign/icons/check/selected.png"; visible: output.selectedIndex === row.index }
                }
            }
        }
        Text {
            width: parent.width
            text: output.message
            wrapMode: Text.WordWrap
            color: VLCStyle.redesign.color("#969696", "#4d4d4d")
            font.family: VLCStyle.redesign.fontFamily; font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
        }
    }
}
