/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as C
import VLC.Style

ColumnLayout {
    id: root
    property string label
    property real value: 0
    property real minimum: -10
    property real maximum: 10
    property real step: 0.05
    property string suffix: " s"
    property var ticks: [minimum, (minimum+maximum)/2, maximum]
    signal edited(real number)
    spacing: VLCStyle.dp(12, VLCStyle.scale)
    PanelField {
        Layout.fillWidth: true
        label: root.label
        controlWidth: VLCStyle.dp(138, VLCStyle.scale)
        controlHeight: VLCStyle.dp(32, VLCStyle.scale)
        PanelNumber {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            value: root.value
            minimum: root.minimum
            maximum: root.maximum
            suffix: root.suffix
            onEdited: number => root.edited(number)
        }
    }
    C.Slider {
        id: slider
        Layout.fillWidth: true
        from: root.minimum
        to: root.maximum
        stepSize: root.step
        value: root.value
        onMoved: root.edited(value)
        implicitHeight: VLCStyle.dp(16, VLCStyle.scale)
        background: Rectangle {
            x: slider.leftPadding
            y: (slider.height - height) / 2
            width: slider.availableWidth
            height: VLCStyle.dp(12, VLCStyle.scale)
            radius: VLCStyle.dp(4, VLCStyle.scale)
            color: VLCStyle.redesign.color("#090909", "#dedede")
            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: VLCStyle.dp(4, VLCStyle.scale)
                color: VLCStyle.redesign.accentBackground
            }
        }
        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: (slider.height - height) / 2
            width: VLCStyle.dp(6, VLCStyle.scale)
            height: VLCStyle.dp(24, VLCStyle.scale)
            radius: VLCStyle.dp(3, VLCStyle.scale)
            color: VLCStyle.redesign.accent
        }
    }
    RowLayout {
        visible: root.ticks.length > 0
        Layout.fillWidth: true
        Repeater {
            model: root.ticks
            Text {
                Layout.fillWidth: true
                text: modelData + (root.suffix === "x" ? "" : root.suffix)
                horizontalAlignment: index === 0 ? Text.AlignLeft : index === root.ticks.length-1 ? Text.AlignRight : Text.AlignHCenter
                color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
                font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
            }
        }
    }
}
