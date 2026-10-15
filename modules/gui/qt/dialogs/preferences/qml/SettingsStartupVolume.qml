/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Controls.Basic as C
import VLC.Style

Item {
    id: root
    required property var settingsModel
    property int revision: 0
    readonly property bool remember: { revision; return Boolean(settingsModel.valueFor("volume-save")) }
    implicitHeight: VLCStyle.dp(90, VLCStyle.scale)
    Connections {
        target: root.settingsModel
        function onDataChanged() { ++root.revision }
        function onModelReset() { ++root.revision }
    }
    C.Label {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: qsTr("Startup volume")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        color: VLCStyle.redesign.color("#949494", "#494949")
    }
    Column {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(VLCStyle.dp(320, VLCStyle.scale), root.width * 0.46)
        spacing: 2
        C.Button {
            objectName: "startupVolumeRemember"
            width: parent.width
            height: VLCStyle.dp(36, VLCStyle.scale)
            onClicked: root.settingsModel.setValue("volume-save", true)
            background: Rectangle { radius: 4; color: root.remember ? VLCStyle.redesign.accentBackground : VLCStyle.redesign.color("#191919", "#eeeeee") }
            contentItem: C.Label {
                text: qsTr("Remember last volume")
                leftPadding: 12
                verticalAlignment: Text.AlignVCenter
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                color: root.remember ? VLCStyle.redesign.accent : VLCStyle.redesign.color("#6b6b6b", "#555555")
            }
        }
        Rectangle {
            width: parent.width
            height: VLCStyle.dp(36, VLCStyle.scale)
            radius: 4
            color: root.remember ? VLCStyle.redesign.color("#191919", "#eeeeee") : VLCStyle.redesign.accentBackground
            C.Button {
                objectName: "startupVolumeFixed"
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * 0.42
                onClicked: root.settingsModel.setValue("volume-save", false)
                background: Item {}
                contentItem: C.Label {
                    text: qsTr("Always starts at:")
                    leftPadding: 12
                    verticalAlignment: Text.AlignVCenter
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    color: !root.remember ? VLCStyle.redesign.accent : VLCStyle.redesign.color("#6b6b6b", "#555555")
                }
            }
            C.TextField {
                objectName: "startupVolumePercent"
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * 0.58
                text: { root.revision; return root.settingsModel.valueFor("qt-startup-volume") + "%" }
                selectByMouse: true
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                color: VLCStyle.redesign.color("#8f8f8f", "#494949")
                onEditingFinished: {
                    const value = parseInt(text)
                    if (Number.isFinite(value) && value >= 0 && value <= 300) {
                        root.settingsModel.setValue("qt-startup-volume", value)
                        root.settingsModel.setValue("volume-save", false)
                    }
                }
                background: Rectangle { radius: 4; color: VLCStyle.redesign.color("#090909", "#fafafa") }
            }
        }
    }
}
