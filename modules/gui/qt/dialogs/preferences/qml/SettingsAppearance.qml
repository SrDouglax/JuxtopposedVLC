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
    implicitHeight: VLCStyle.dp(210, VLCStyle.scale)
    property int selectedTheme: 0
    property int initialTheme: 0
    property color selectedAccent: VLCStyle.redesign.accent
    property color initialAccent: VLCStyle.redesign.accent
    readonly property bool dark: VLCStyle.palette.isDark
    readonly property bool dirty: selectedTheme !== initialTheme
                                  || selectedAccent.toString() !== initialAccent.toString()

    readonly property var themeChoices: [
        { text: qsTr("Dark"), index: 2 },
        { text: qsTr("Light"), index: 1 },
        { text: qsTr("System"), index: 0 }
    ]
    readonly property var accentChoices: VLCStyle.redesign.accentChoices

    OnboardingController { id: themeBridge; ctx: MainCtx }

    function begin() {
        themeBridge.begin()
        initialTheme = themeBridge.themeIndex
        selectedTheme = initialTheme
        initialAccent = VLCStyle.redesign.accent
        selectedAccent = initialAccent
    }

    function chooseTheme(index) {
        selectedTheme = index
        themeBridge.previewTheme(index)
    }

    function chooseAccent(color) {
        selectedAccent = color
        VLCStyle.redesign.accent = color
    }

    function resetDefaults() {
        chooseTheme(0)
        chooseAccent("#D37918")
    }

    function cancel() {
        themeBridge.cancel()
        selectedTheme = initialTheme
        selectedAccent = initialAccent
        VLCStyle.redesign.accent = initialAccent
    }

    function save() {
        themeBridge.acceptTheme()
        MainCtx.setSettingValue("redesign/accent", selectedAccent.toString())
        initialTheme = selectedTheme
        initialAccent = selectedAccent
    }

    Label {
        text: qsTr("Appearance")
        color: root.dark ? "#d2d2d2" : "#222222"
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
        anchors.top: parent.top
    }

    SettingsLanguageAction {
        width: parent.width
        y: VLCStyle.dp(34, VLCStyle.scale)
    }

    Label {
        text: qsTr("Theme")
        color: root.dark ? "#999999" : "#494949"
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        anchors.top: parent.top
        anchors.topMargin: VLCStyle.dp(119, VLCStyle.scale)
    }

    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: VLCStyle.dp(105, VLCStyle.scale)
        spacing: 2
        Repeater {
            model: root.themeChoices
            delegate: Button {
                required property var modelData
                width: VLCStyle.dp(103, VLCStyle.scale)
                height: VLCStyle.dp(34, VLCStyle.scale)
                text: modelData.text
                onClicked: root.chooseTheme(modelData.index)
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                background: Rectangle {
                    color: root.selectedTheme === modelData.index
                           ? (root.dark ? "#371f06" : "#f7e2c9")
                           : (root.dark ? "#191919" : "#eeeeee")
                    border.color: root.dark ? "#232323" : "#cccccc"
                    radius: 3
                }
                contentItem: Label {
                    text: parent.text
                    color: root.selectedTheme === modelData.index
                           ? VLCStyle.redesign.accent : (root.dark ? "#858585" : "#555555")
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font: parent.font
                }
            }
        }
    }

    Label {
        text: qsTr("Accent color")
        color: root.dark ? "#999999" : "#494949"
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        anchors.top: parent.top
        anchors.topMargin: VLCStyle.dp(164, VLCStyle.scale)
    }

    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: VLCStyle.dp(156, VLCStyle.scale)
        spacing: 7
        Repeater {
            model: root.accentChoices
            delegate: Button {
                required property var modelData
                width: VLCStyle.dp(30, VLCStyle.scale)
                height: VLCStyle.dp(34, VLCStyle.scale)
                onClicked: root.chooseAccent(modelData)
                Accessible.name: qsTr("Accent color %1").arg(modelData)
                background: Rectangle {
                    color: root.selectedAccent.toString().toLowerCase() === modelData.toLowerCase()
                           ? "#382208" : "transparent"
                    radius: 3
                }
                contentItem: Rectangle {
                    anchors.centerIn: parent
                    width: VLCStyle.dp(20, VLCStyle.scale)
                    height: VLCStyle.dp(20, VLCStyle.scale)
                    color: modelData
                    radius: 1
                }
            }
        }
    }
}
