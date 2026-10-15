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
    property bool expanded: false
    property bool embedded: false
    spacing: 0

    T.Button {
        id: accordion
        Layout.fillWidth: true
        implicitHeight: VLCStyle.dp(48, VLCStyle.scale)
        leftPadding: VLCStyle.dp(16, VLCStyle.scale)
        rightPadding: VLCStyle.dp(16, VLCStyle.scale)
        focusPolicy: Qt.StrongFocus
        Accessible.name: root.expanded ? qsTr("Collapse equalizer settings") : qsTr("Expand equalizer settings")
        onClicked: root.expanded = !root.expanded
        background: Rectangle {
            color: VLCStyle.redesign.color(root.expanded ? "#1B1B1B" : "#090909", "#dedede")
            radius: VLCStyle.dp(6, VLCStyle.scale)
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: root.expanded ? parent.radius : 0; color: parent.color }
        }
        contentItem: RowLayout {
            anchors.leftMargin: VLCStyle.dp(16, VLCStyle.scale)
            anchors.rightMargin: VLCStyle.dp(16, VLCStyle.scale)
            Text {
                Layout.fillWidth: true
                text: root.expanded ? qsTr("Collapse Settings") : qsTr("Expand Settings")
                color: VLCStyle.redesign.textMuted
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }
            Image {
                source: root.expanded ? "qrc:///redesign/icons/chevron-down/default.png"
                                      : "qrc:///redesign/icons/chevron-right/default.png"
                sourceSize.width: VLCStyle.dp(16, VLCStyle.scale)
                sourceSize.height: VLCStyle.dp(16, VLCStyle.scale)
                Layout.preferredWidth: sourceSize.width
                Layout.preferredHeight: sourceSize.height
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: settings.implicitHeight + VLCStyle.dp(32, VLCStyle.scale)
        radius: VLCStyle.dp(6, VLCStyle.scale)
        color: VLCStyle.redesign.color("#1B1B1B", "#dedede")
        visible: root.expanded
        Rectangle { anchors.top: parent.top; width: parent.width; height: parent.radius; color: parent.color }

        ColumnLayout {
            id: settings
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: VLCStyle.dp(16, VLCStyle.scale)
            spacing: VLCStyle.dp(28, VLCStyle.scale)

            T.Button {
                id: presetButton
                visible: !root.embedded
                Layout.fillWidth: true
                implicitHeight: VLCStyle.dp(42, VLCStyle.scale)
                leftPadding: VLCStyle.dp(12, VLCStyle.scale)
                rightPadding: VLCStyle.dp(12, VLCStyle.scale)
                focusPolicy: Qt.StrongFocus
                Accessible.name: qsTr("Equalizer preset")
                onClicked: presetsPopup.open()
                background: Rectangle { color: VLCStyle.redesign.color("#090909", "#eeeeee"); radius: VLCStyle.dp(5, VLCStyle.scale) }
                contentItem: RowLayout {
                    anchors.leftMargin: VLCStyle.dp(12, VLCStyle.scale)
                    anchors.rightMargin: VLCStyle.dp(12, VLCStyle.scale)
                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (!root.effects.preset) return qsTr("Custom")
                            const match = root.effects.presets.find(p => p.id === root.effects.preset)
                            return match ? match.name : root.effects.preset
                        }
                        color: VLCStyle.redesign.textSecondary
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    }
                    Image {
                        source: "qrc:///redesign/icons/chevron-down/default.png"
                        sourceSize.width: VLCStyle.dp(16, VLCStyle.scale)
                        sourceSize.height: VLCStyle.dp(16, VLCStyle.scale)
                        Layout.preferredWidth: sourceSize.width
                        Layout.preferredHeight: sourceSize.height
                    }
                }
            }

            ValueSlider {
                Layout.fillWidth: true
                label: qsTr("Preamp")
                unit: qsTr("dB")
                from: -20
                to: 20
                modelValue: root.effects.preamp
                editable: true
                onEdited: (value) => root.effects.setPreamp(value)
            }

            Repeater {
                model: 10
                ValueSlider {
                    required property int index
                    Layout.fillWidth: true
                    readonly property real hz: root.effects.frequencies[index] || 0
                    label: hz >= 1000 ? (hz / 1000).toLocaleString(Qt.locale(), 'f', hz % 1000 ? 1 : 0) + " kHz"
                                      : Math.round(hz) + " Hz"
                    unit: qsTr("dB")
                    from: -20
                    to: 20
                    modelValue: root.effects.bands[index] || 0
                    editable: true
                    onEdited: (value) => root.effects.setBand(index, value)
                }
            }

            RowLayout {
                visible: !root.embedded
                Layout.fillWidth: true
                T.CheckBox {
                    id: twoPass
                    text: qsTr("Two-pass equalizer")
                    Binding on checked {
                        when: !twoPass.pressed
                        value: root.effects.twoPass
                    }
                    onClicked: root.effects.setTwoPass(checked)
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    indicator: Rectangle {
                        implicitWidth: VLCStyle.dp(18, VLCStyle.scale)
                        implicitHeight: implicitWidth
                        radius: VLCStyle.dp(3, VLCStyle.scale)
                        color: twoPass.checked ? VLCStyle.redesign.accent : "#0E0E0E"
                        border.color: twoPass.checked ? VLCStyle.redesign.accent : VLCStyle.redesign.border
                        Image {
                            anchors.centerIn: parent
                            source: "qrc:///redesign/icons/check/selected.png"
                            visible: twoPass.checked
                            sourceSize.width: VLCStyle.dp(14, VLCStyle.scale)
                            sourceSize.height: VLCStyle.dp(14, VLCStyle.scale)
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                T.Button {
                    text: qsTr("Reset")
                    onClicked: root.effects.resetDefaults("equalizer")
                    contentItem: Text {
                        text: parent.text
                        color: VLCStyle.redesign.accent
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    }
                    background: Item {}
                }
            }
        }
    }

    T.Popup {
        id: presetsPopup
        parent: presetButton
        y: presetButton.height + VLCStyle.dp(4, VLCStyle.scale)
        width: presetButton.width
        height: Math.min(VLCStyle.dp(350, VLCStyle.scale), presetList.implicitHeight)
        padding: VLCStyle.dp(8, VLCStyle.scale)
        closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside
        background: Rectangle { color: "#1B1B1B"; radius: VLCStyle.dp(6, VLCStyle.scale) }
        contentItem: ListView {
            id: presetList
            implicitHeight: contentHeight
            clip: true
            model: root.effects.presets
            delegate: T.Button {
                id: presetChoice
                required property var modelData
                width: presetList.width
                height: VLCStyle.dp(38, VLCStyle.scale)
                text: modelData.name
                focusPolicy: Qt.StrongFocus
                onClicked: {
                    if (root.effects.setPreset(modelData.id)) presetsPopup.close()
                }
                background: Rectangle {
                    color: parent.hovered ? VLCStyle.redesign.controlHoverBackground : "transparent"
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                }
                contentItem: RowLayout {
                    Text {
                        Layout.fillWidth: true
                        text: presetChoice.text
                        color: VLCStyle.redesign.textSecondary
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                        elide: Text.ElideRight
                    }
                    Canvas {
                        Layout.preferredWidth: VLCStyle.dp(72, VLCStyle.scale)
                        Layout.preferredHeight: VLCStyle.dp(24, VLCStyle.scale)
                        renderTarget: Canvas.Image
                        Accessible.role: Accessible.Graphic
                        Accessible.name: qsTr("%1 equalizer curve").arg(presetChoice.text)
                        onPaint: {
                            const gains = presetChoice.modelData.bands
                            if (!gains || gains.length !== 10) return
                            const paint = getContext("2d")
                            paint.clearRect(0, 0, width, height)
                            paint.strokeStyle = VLCStyle.redesign.border
                            paint.lineWidth = 1
                            paint.beginPath()
                            paint.moveTo(0, height / 2)
                            paint.lineTo(width, height / 2)
                            paint.stroke()
                            paint.strokeStyle = VLCStyle.redesign.accent
                            paint.lineWidth = 1.5
                            paint.beginPath()
                            for (let band = 0; band < gains.length; ++band) {
                                const gain = Math.max(-20, Math.min(20, Number(gains[band])))
                                const x = band * width / (gains.length - 1)
                                const y = (20 - gain) * height / 40
                                if (band === 0) paint.moveTo(x, y)
                                else paint.lineTo(x, y)
                            }
                            paint.stroke()
                        }
                    }
                    Image {
                        source: "qrc:///redesign/icons/check/selected.png"
                        visible: root.effects.preset === modelData.id
                        sourceSize.width: VLCStyle.dp(18, VLCStyle.scale)
                        sourceSize.height: VLCStyle.dp(18, VLCStyle.scale)
                        Layout.preferredWidth: sourceSize.width
                        Layout.preferredHeight: sourceSize.height
                    }
                }
            }
        }
    }
}
