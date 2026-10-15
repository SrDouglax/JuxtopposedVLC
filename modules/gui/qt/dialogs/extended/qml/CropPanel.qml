/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 or later.
 *****************************************************************************/
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import VLC.Style

Rectangle {
    id: root
    required property var effects
    property bool verticalLinked: false
    property bool horizontalLinked: false
    implicitHeight: content.implicitHeight + VLCStyle.dp(32, VLCStyle.scale)
    color: VLCStyle.redesign.color("#1B1B1B", "#dedede")
    radius: VLCStyle.dp(6, VLCStyle.scale)

    function updateCrop(side, pixels) {
        if (!effects.setCrop(side, pixels)) return
        if (verticalLinked && side === "top") effects.setCrop("bottom", pixels)
        if (verticalLinked && side === "bottom") effects.setCrop("top", pixels)
        if (horizontalLinked && side === "left") effects.setCrop("right", pixels)
        if (horizontalLinked && side === "right") effects.setCrop("left", pixels)
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: VLCStyle.dp(16, VLCStyle.scale)
        spacing: VLCStyle.dp(12, VLCStyle.scale)

        RowLayout {
            Layout.fillWidth: true
            spacing: VLCStyle.dp(8, VLCStyle.scale)
            CropInput {
                Layout.fillWidth: true
                effects: root.effects
                side: "top"
                label: qsTr("Top")
                onEdited: (pixels) => root.updateCrop(side, pixels)
            }
            CropInput {
                Layout.fillWidth: true
                effects: root.effects
                side: "bottom"
                label: qsTr("Bottom")
                onEdited: (pixels) => root.updateCrop(side, pixels)
            }
            T.Button {
                objectName: "linkVerticalCrop"
                implicitWidth: VLCStyle.dp(26, VLCStyle.scale)
                implicitHeight: implicitWidth
                onClicked: root.verticalLinked = !root.verticalLinked
                Accessible.name: qsTr("Link top and bottom crop")
                background: Item {}
                contentItem: Image {
                    source: root.verticalLinked ? "qrc:///redesign/icons/link/active.png"
                                                : "qrc:///redesign/icons/link/default.png"
                    sourceSize.width: VLCStyle.dp(22, VLCStyle.scale)
                    sourceSize.height: VLCStyle.dp(22, VLCStyle.scale)
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: VLCStyle.dp(8, VLCStyle.scale)
            CropInput {
                Layout.fillWidth: true
                effects: root.effects
                side: "left"
                label: qsTr("Left")
                onEdited: (pixels) => root.updateCrop(side, pixels)
            }
            CropInput {
                Layout.fillWidth: true
                effects: root.effects
                side: "right"
                label: qsTr("Right")
                onEdited: (pixels) => root.updateCrop(side, pixels)
            }
            T.Button {
                objectName: "linkHorizontalCrop"
                implicitWidth: VLCStyle.dp(26, VLCStyle.scale)
                implicitHeight: implicitWidth
                onClicked: root.horizontalLinked = !root.horizontalLinked
                Accessible.name: qsTr("Link left and right crop")
                background: Item {}
                contentItem: Image {
                    source: root.horizontalLinked ? "qrc:///redesign/icons/link/active.png"
                                                  : "qrc:///redesign/icons/link/default.png"
                    sourceSize.width: VLCStyle.dp(22, VLCStyle.scale)
                    sourceSize.height: VLCStyle.dp(22, VLCStyle.scale)
                }
            }
        }
    }
}
