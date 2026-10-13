/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 or later.
 *****************************************************************************/
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import VLC.Style

ColumnLayout {
    id: root
    required property var effects
    property int section: 0
    readonly property var essential: [
        { id: "adjust", title: qsTr("Image adjustment") },
        { id: "sharpen", title: qsTr("Sharpen") },
        { id: "gradfun", title: qsTr("Debanding") },
        { id: "grain", title: qsTr("Film grain") }
    ]
    readonly property var colors: [
        { id: "extract", title: qsTr("Color extraction") },
        { id: "colorthres", title: qsTr("Color threshold") },
        { id: "invert", title: qsTr("Negate colors") },
        { id: "posterize", title: qsTr("Posterize") },
        { id: "gradient", title: qsTr("Gradient") },
        { id: "sepia", title: qsTr("Sepia") }
    ]
    spacing: VLCStyle.dp(16, VLCStyle.scale)

    RowLayout {
        Layout.fillWidth: true
        spacing: 0
        Repeater {
            model: [qsTr("Essential"), qsTr("Crop"), qsTr("Colors")]
            delegate: T.Button {
                id: sectionButton
                required property int index
                required property string modelData
                objectName: "videoEffectsSection" + index
                Layout.fillWidth: true
                implicitHeight: VLCStyle.dp(42, VLCStyle.scale)
                focusPolicy: Qt.StrongFocus
                onClicked: root.section = index
                background: Rectangle {
                    color: sectionButton.hovered ? VLCStyle.redesign.controlHoverBackground : "transparent"
                    radius: VLCStyle.dp(5, VLCStyle.scale)
                }
                contentItem: Text {
                    text: sectionButton.modelData
                    color: root.section === sectionButton.index ? VLCStyle.redesign.accent : VLCStyle.redesign.textMuted
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    CropPanel {
        Layout.fillWidth: true
        visible: root.section === 1
        effects: root.effects
    }

    Repeater {
        model: root.section === 0 ? root.essential : root.section === 2 ? root.colors : []
        VideoFilterSection {
            required property var modelData
            Layout.fillWidth: true
            effects: root.effects
            filterId: modelData.id
            title: modelData.title
        }
    }
}
