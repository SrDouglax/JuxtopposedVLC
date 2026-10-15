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
        { key: "general", label: qsTr("General"), icon: "preferences" },
        { key: "interface", label: qsTr("Interface"), icon: "interface" },
        { key: "privacy", label: qsTr("Privacy"), icon: "privacy" },
        { key: "controls", label: qsTr("Controls"), icon: "hotkeys" },
        { kind: "heading", label: qsTr("Media") },
        { key: "playback", label: qsTr("Playback"), icon: "playback" },
        { key: "video", label: qsTr("Video"), icon: "video" },
        { key: "audio", label: qsTr("Audio"), icon: "audio" },
        { key: "subtitles", label: qsTr("Subtitles"), icon: "subtitles" },
        { key: "library", label: qsTr("Library"), icon: "folder" },
        { kind: "heading", label: qsTr("System") },
        { key: "network", label: qsTr("Network"), icon: "streaming" },
        { key: "performance", label: qsTr("Performance"), icon: "preferences" },
        { key: "recording", label: qsTr("Recording"), icon: "record" },
        { key: "extensions", label: qsTr("Extensions"), icon: "plugins" }
    ]

    Rectangle {
        anchors.fill: parent
        color: root.dark ? "#191919" : "#f2f2f2"
        radius: 6
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: VLCStyle.dp(6, VLCStyle.scale)
        contentHeight: categoryList.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: categoryList
            width: parent.width
            spacing: VLCStyle.dp(2, VLCStyle.scale)

            Repeater {
                model: root.entries
                delegate: Item {
                    required property int index
                    required property var modelData
                    width: categoryList.width
                    height: VLCStyle.dp(modelData.kind === "heading" && index > 0 ? 34 : 46, VLCStyle.scale)
                    visible: modelData.kind === "heading"
                             || modelData.key === "extensions"
                             || root.availableCategories.indexOf(modelData.key) >= 0

                    Label {
                        visible: modelData.kind === "heading"
                        anchors.left: parent.left
                        anchors.leftMargin: VLCStyle.dp(10, VLCStyle.scale)
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: VLCStyle.dp(10, VLCStyle.scale)
                        text: modelData.label || ""
                        color: root.dark ? "#6d6d6d" : "#666666"
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    }

                    Button {
                        objectName: "settingsCategory_" + modelData.key
                        visible: modelData.kind !== "heading"
                        enabled: modelData.key === "extensions"
                                 || root.availableCategories.indexOf(modelData.key) >= 0
                        anchors.fill: parent
                        anchors.topMargin: VLCStyle.dp(3, VLCStyle.scale)
                        anchors.bottomMargin: VLCStyle.dp(3, VLCStyle.scale)
                        onClicked: root.selected(modelData.key)
                        background: Rectangle {
                            color: root.category === modelData.key
                                   ? (root.dark ? "#252525" : "#e3e3e3")
                                   : parent.hovered ? (root.dark ? "#1c1c1c" : "#eaeaea")
                                                    : "transparent"
                            radius: 3
                        }
                        contentItem: Row {
                            spacing: VLCStyle.dp(12, VLCStyle.scale)
                            anchors.left: parent.left
                            anchors.leftMargin: VLCStyle.dp(10, VLCStyle.scale)
                            anchors.verticalCenter: parent.verticalCenter
                            Image {
                                width: VLCStyle.dp(24, VLCStyle.scale)
                                height: width
                                sourceSize: Qt.size(width, height)
                                fillMode: Image.PreserveAspectFit
                                source: !modelData.icon ? "" : "qrc:///redesign/icons/" + modelData.icon + "/"
                                        + (root.category === modelData.key ? "active" : "default") + ".png"
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
