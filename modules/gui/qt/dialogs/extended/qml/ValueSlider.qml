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
    property string label
    property string unit
    property real from: 0
    property real to: 1
    property real modelValue: 0
    property int decimals: 1
    property bool editable: false
    signal edited(real value)

    function formatted(value) {
        return Number(value).toFixed(decimals) + (unit.length ? " " + unit : "")
    }

    spacing: VLCStyle.dp(10, VLCStyle.scale)

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: root.label
            color: VLCStyle.redesign.textMuted
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
        Rectangle {
            width: VLCStyle.dp(136, VLCStyle.scale)
            height: VLCStyle.dp(32, VLCStyle.scale)
            radius: VLCStyle.dp(4, VLCStyle.scale)
            color: "#0E0E0E"
            visible: root.editable
            TextInput {
                id: numericInput
                anchors.fill: parent
                anchors.leftMargin: VLCStyle.dp(12, VLCStyle.scale)
                anchors.rightMargin: VLCStyle.dp(8, VLCStyle.scale)
                verticalAlignment: TextInput.AlignVCenter
                color: VLCStyle.redesign.textSecondary
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                selectByMouse: true
                text: root.formatted(root.modelValue)
                onEditingFinished: {
                    const number = Number(text.replace(root.unit, "").trim().replace(",", "."))
                    if (Number.isFinite(number) && number >= root.from && number <= root.to)
                        root.edited(number)
                    text = root.formatted(root.modelValue)
                }
                Connections {
                    target: root
                    function onModelValueChanged() { if (!numericInput.activeFocus) numericInput.text = root.formatted(root.modelValue) }
                }
            }
        }
        Text {
            visible: !root.editable
            text: root.formatted(root.modelValue)
            color: VLCStyle.redesign.textMuted
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }
    }

    T.Slider {
        id: slider
        Layout.fillWidth: true
        implicitHeight: VLCStyle.dp(20, VLCStyle.scale)
        from: root.from
        to: root.to
        stepSize: root.editable ? 0.1 : 0
        focusPolicy: Qt.StrongFocus
        Accessible.name: root.label
        Binding on value {
            when: !slider.pressed
            value: root.modelValue
        }
        onMoved: root.edited(value)
        background: Rectangle {
            x: slider.leftPadding
            y: (slider.height - height) / 2
            width: slider.availableWidth
            height: VLCStyle.dp(16, VLCStyle.scale)
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: "#090909"
            Rectangle {
                width: Math.max(0, slider.visualPosition * parent.width)
                height: parent.height
                radius: parent.radius
                color: "#503012"
            }
        }
        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: (slider.height - height) / 2
            width: VLCStyle.dp(8, VLCStyle.scale)
            height: VLCStyle.dp(24, VLCStyle.scale)
            radius: VLCStyle.dp(4, VLCStyle.scale)
            color: VLCStyle.redesign.accent
        }
    }
}
