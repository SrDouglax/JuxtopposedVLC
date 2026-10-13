/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import VLC.Style

Dialog {
    id: root
    objectName: "shortcutsRestartNotice"
    modal: true
    focus: true
    closePolicy: Popup.NoAutoClose
    title: qsTr("Shortcuts saved")
    standardButtons: Dialog.Ok
    width: VLCStyle.dp(420, VLCStyle.scale)
    contentItem: Label {
        text: qsTr("Restart VLC to use the new keyboard shortcuts.")
        color: VLCStyle.palette.isDark ? "#dddddd" : "#333333"
        wrapMode: Text.WordWrap
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    }
}
