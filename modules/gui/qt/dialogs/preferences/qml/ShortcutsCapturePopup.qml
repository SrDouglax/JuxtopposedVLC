/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import VLC.Style

Popup {
    id: capturePopup
    property bool captureGlobal: false
    property string captureAction: ""
    property string conflictAction: ""
    property string errorText: ""
    readonly property bool dark: VLCStyle.palette.isDark
    signal keyCaptured(int key, int modifiers)
    signal clearRequested()
    signal replaceRequested()

    modal: true
    focus: true
    closePolicy: Popup.NoAutoClose
    height: VLCStyle.dp(205, VLCStyle.scale)
    onOpened: keyInput.forceActiveFocus(Qt.PopupFocusReason)
    background: Rectangle {
        color: capturePopup.dark ? "#1b1b1b" : "#f5f5f5"
        border.color: capturePopup.dark ? "#555555" : "#cccccc"
        radius: 6
    }
    contentItem: FocusScope {
        id: captureFocus
        focus: true
        TextInput {
            id: keyInput
            focus: true
            width: 1
            height: 1
            opacity: 0
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: (event) => {
                event.accepted = true
                if (capturePopup.conflictAction.length === 0)
                    capturePopup.keyCaptured(event.key, event.modifiers)
            }
        }
        Label {
            anchors.top: parent.top
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.leftMargin: 14
            text: capturePopup.captureGlobal ? qsTr("Global Hotkey") : qsTr("Hotkey")
            color: capturePopup.dark ? "#dddddd" : "#333333"
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
        }
        Label {
            anchors.top: parent.top
            anchors.topMargin: 52
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            text: capturePopup.conflictAction.length > 0
                  ? qsTr("This key is assigned to %1. Replace that assignment?").arg(capturePopup.conflictAction)
                  : qsTr("Press a key combination for %1").arg(capturePopup.captureAction)
            color: capturePopup.conflictAction.length > 0 ? "#df8950"
                  : (capturePopup.dark ? "#aaaaaa" : "#555555")
            wrapMode: Text.WordWrap
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }
        Label {
            visible: capturePopup.errorText.length > 0
                     && capturePopup.conflictAction.length === 0
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 61
            text: capturePopup.errorText
            color: "#df8950"
            elide: Text.ElideRight
            font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            spacing: 10
            ActionButton {
                text: qsTr("Unset")
                visible: capturePopup.conflictAction.length === 0
                onClicked: capturePopup.clearRequested()
            }
            ActionButton {
                text: qsTr("Cancel")
                onClicked: capturePopup.close()
            }
            ActionButton {
                text: qsTr("Replace")
                primary: true
                visible: capturePopup.conflictAction.length > 0
                onClicked: capturePopup.replaceRequested()
            }
        }
    }
}
