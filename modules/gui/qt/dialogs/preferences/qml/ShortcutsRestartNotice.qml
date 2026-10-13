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
    background: Rectangle { color: VLCStyle.palette.isDark ? "#1b1b1b" : "#f4f4f4"; radius: 6; border.color: "#555555" }
    header: Label {
        text: root.title
        color: VLCStyle.palette.isDark ? "#eaeaea" : "#333333"
        padding: 16
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
    }
    footer: ActionButton {
        text: qsTr("OK")
        primary: true
        onClicked: root.accept()
    }
    width: VLCStyle.dp(420, VLCStyle.scale)
    contentItem: Label {
        text: qsTr("Restart VLC to use the new keyboard shortcuts.")
        color: VLCStyle.palette.isDark ? "#dddddd" : "#333333"
        wrapMode: Text.WordWrap
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    }
}
