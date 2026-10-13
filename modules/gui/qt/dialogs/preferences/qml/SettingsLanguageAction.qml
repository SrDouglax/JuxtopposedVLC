/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import VLC.Dialogs
import VLC.MainInterface
import VLC.Style

Item {
    id: root
    objectName: "interfaceLanguageAction"
    implicitHeight: VLCStyle.dp(58, VLCStyle.scale)
    readonly property bool isWindows: MainCtx.osName === MainCtx.Windows
    readonly property bool dark: VLCStyle.palette.isDark

    Label {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 7
        text: qsTr("Interface language")
        color: root.dark ? "#969696" : "#444444"
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    }

    Button {
        id: languageButton
        objectName: "nativeLanguagePreferences"
        visible: root.isWindows
        anchors.right: parent.right
        anchors.top: parent.top
        width: VLCStyle.dp(320, VLCStyle.scale)
        height: VLCStyle.dp(34, VLCStyle.scale)
        text: qsTr("Choose in Preferences")
        onClicked: DialogsProvider.nativePrefsDialog()
        background: Rectangle {
            color: root.dark ? "#181818" : "#eeeeee"
            border.color: root.dark ? "#2b2b2b" : "#cccccc"
            radius: 4
        }
        contentItem: Label {
            text: parent.text
            color: root.dark ? "#aaaaaa" : "#444444"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }
    }

    Label {
        visible: !root.isWindows
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 7
        text: qsTr("System language (%1)").arg(Qt.locale().name)
        color: root.dark ? "#8c8c8c" : "#555555"
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    }

    Label {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        text: root.isWindows
              ? qsTr("Restart VLC after changing the interface language.")
              : qsTr("VLC follows the system language. Restart VLC after changing your system language.")
        color: root.dark ? "#696969" : "#666666"
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
        elide: Text.ElideRight
    }
}
