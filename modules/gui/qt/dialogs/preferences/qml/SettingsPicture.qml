/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import VLC.Style

ColumnLayout {
    id: root
    required property var effects
    readonly property var adjustments: [
        { id: "hue", title: qsTr("Hue") },
        { id: "brightness", title: qsTr("Brightness") },
        { id: "contrast", title: qsTr("Contrast") },
        { id: "saturation", title: qsTr("Saturation") },
        { id: "gamma", title: qsTr("Gamma") }
    ]
    readonly property var parameters: { effects.revision; return effects.parameters("adjust") }
    spacing: VLCStyle.dp(8, VLCStyle.scale)
    visible: effects.filterAvailable("adjust")

    RowLayout {
        Layout.fillWidth: true
        Label {
            Layout.fillWidth: true
            text: qsTr("Picture")
            color: VLCStyle.redesign.color("#EAEAEA", "#2e2e2e")
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
        }

    }
    Repeater {
        model: root.adjustments
        RowLayout {
            id: row
            required property var modelData
            Layout.fillWidth: true
            Layout.minimumHeight: VLCStyle.dp(34, VLCStyle.scale)
            Layout.preferredHeight: Layout.minimumHeight
            readonly property var parameter: root.parameters.find(p => p.id === modelData.id)
            Label {
                Layout.fillWidth: true
                text: row.modelData.title
                color: VLCStyle.redesign.color("#8F8F8F", "#7c7c7b")
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }
            Slider {
                id: adjustmentSlider
                objectName: "settingsPicture-" + row.modelData.id
                Layout.preferredWidth: VLCStyle.dp(319, VLCStyle.scale)
                from: row.parameter && row.parameter.minimum !== undefined ? row.parameter.minimum : 0
                to: row.parameter && row.parameter.maximum !== undefined ? row.parameter.maximum : 1
                enabled: !!row.parameter
                Binding on value {
                    when: !adjustmentSlider.pressed
                    value: { root.effects.revision; return Number(root.effects.parameterValue(row.modelData.id)) }
                }
                onMoved: if (root.effects.setFilterEnabled("adjust", true)) root.effects.setParameter(row.modelData.id, value)
                background: Rectangle {
                    x: adjustmentSlider.leftPadding
                    y: adjustmentSlider.topPadding + (adjustmentSlider.availableHeight - height) / 2
                    width: adjustmentSlider.availableWidth
                    height: VLCStyle.dp(12, VLCStyle.scale)
                    radius: height / 2
                    color: VLCStyle.redesign.color("#090909", "#ababaa")
                    Rectangle {
                        width: adjustmentSlider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: VLCStyle.redesign.accentBackground
                    }
                }
                handle: Rectangle {
                    x: adjustmentSlider.leftPadding + adjustmentSlider.visualPosition
                       * (adjustmentSlider.availableWidth - width)
                    y: adjustmentSlider.topPadding + (adjustmentSlider.availableHeight - height) / 2
                    width: VLCStyle.dp(8, VLCStyle.scale)
                    height: VLCStyle.dp(22, VLCStyle.scale)
                    radius: 4
                    color: VLCStyle.redesign.accent
                }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Label {
            Layout.fillWidth: true
            text: qsTr("Reset picture")
            color: VLCStyle.redesign.color("#8F8F8F", "#7c7c7b")
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }
        Button {
            text: qsTr("Reset")
            Layout.preferredWidth: VLCStyle.dp(100, VLCStyle.scale)
            Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
            onClicked: root.effects.resetDefaults("adjust")
            background: Rectangle { color: VLCStyle.redesign.color("#191919", "#ababaa"); radius: 4 }
            contentItem: Label {
                text: parent.text
                color: VLCStyle.redesign.color("#969696", "#4d4d4d")
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }
        }
    }
}
