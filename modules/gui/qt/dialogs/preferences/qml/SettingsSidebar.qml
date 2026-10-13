/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import VLC.Style

Item {
    id: root
    property string category: "general"
    property var availableCategories: []
    readonly property bool dark: VLCStyle.palette.isDark
    signal selected(string category)

    readonly property var entries: [
        { kind: "heading", label: qsTr("App") },
        { key: "general", label: qsTr("General"), icon: VLCIcons.settings },
        { key: "interface", label: qsTr("Interface"), icon: VLCIcons.panel_left },
        { key: "privacy", label: qsTr("Privacy"), icon: VLCIcons.history },
        { key: "controls", label: qsTr("Controls"), icon: VLCIcons.effect_filter },
        { kind: "heading", label: qsTr("Media") },
        { key: "playback", label: qsTr("Playback"), icon: VLCIcons.play },
        { key: "video", label: qsTr("Video"), icon: VLCIcons.topbar_video },
        { key: "audio", label: qsTr("Audio"), icon: VLCIcons.volume_high },
        { key: "subtitles", label: qsTr("Subtitles"), icon: VLCIcons.audiosub },
        { key: "library", label: qsTr("Library"), icon: VLCIcons.playlist },
        { kind: "heading", label: qsTr("System") },
        { key: "network", label: qsTr("Network"), icon: VLCIcons.topbar_network },
        { key: "performance", label: qsTr("Performance"), icon: VLCIcons.faster },
        { key: "recording", label: qsTr("Recording"), icon: VLCIcons.record },
        { key: "extensions", label: qsTr("Extensions"), icon: VLCIcons.add }
    ]

    Rectangle {
        anchors.fill: parent
        color: root.dark ? "#151515" : "#f2f2f2"
        radius: 6
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 6
        contentHeight: categoryList.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: categoryList
            width: parent.width
            spacing: 2

            Repeater {
                model: root.entries
                delegate: Item {
                    required property var modelData
                    width: categoryList.width
                    height: modelData.kind === "heading" ? 46 : 46
                    visible: modelData.kind === "heading"
                             || modelData.key === "extensions"
                             || root.availableCategories.indexOf(modelData.key) >= 0

                    Label {
                        visible: modelData.kind === "heading"
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        text: modelData.label || ""
                        color: root.dark ? "#6d6d6d" : "#666666"
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    }

                    Button {
                        visible: modelData.kind !== "heading"
                        enabled: modelData.key === "extensions"
                                 || root.availableCategories.indexOf(modelData.key) >= 0
                        anchors.fill: parent
                        anchors.topMargin: 3
                        anchors.bottomMargin: 3
                        onClicked: root.selected(modelData.key)
                        background: Rectangle {
                            color: root.category === modelData.key
                                   ? (root.dark ? "#252525" : "#e3e3e3")
                                   : parent.hovered ? (root.dark ? "#1c1c1c" : "#eaeaea")
                                                    : "transparent"
                            radius: 3
                        }
                        contentItem: Row {
                            spacing: 12
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            Label {
                                text: modelData.icon || ""
                                color: root.category === modelData.key
                                       ? VLCStyle.redesign.accent
                                       : (root.dark ? "#888888" : "#666666")
                                font.family: VLCIcons.fontFamily
                                font.pixelSize: VLCStyle.dp(20, VLCStyle.scale)
                                width: 22
                            }
                            Label {
                                text: modelData.label || ""
                                color: root.category === modelData.key
                                       ? (root.dark ? "#e4e4e4" : "#222222")
                                       : (root.dark ? "#929292" : "#555555")
                                font.family: VLCStyle.redesign.fontFamily
                                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                            }
                        }
                    }
                }
            }
        }
    }
}
