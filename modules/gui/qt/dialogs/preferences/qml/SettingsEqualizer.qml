/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import VLC.Style
import VLC.Player

ColumnLayout {
    id: root
    required property var effects
    property bool expanded: true
    spacing: VLCStyle.dp(12, VLCStyle.scale)
    visible: effects.filterAvailable("equalizer")

    RowLayout {
        Layout.fillWidth: true
        Label {
            Layout.fillWidth: true
            text: qsTr("Equalizer")
            color: VLCStyle.redesign.color("#8F8F8F", "#7c7c7b")
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }
        PanelToggle {
            id: enabledSwitch
            objectName: "settingsEqualizerEnabled"
            Accessible.name: qsTr("Equalizer")
            checked: { root.effects.bands; return root.effects.filterEnabled("equalizer") }
            onClicked: if (root.effects.begin()) root.effects.setFilterEnabled("equalizer", checked)
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Label {
            Layout.fillWidth: true
            text: qsTr("Equalizer preset")
            color: VLCStyle.redesign.color("#8F8F8F", "#7c7c7b")
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }
        ComboBox {
            id: presetBox
            objectName: "settingsEqualizerPreset"
            Layout.preferredWidth: VLCStyle.dp(319, VLCStyle.scale)
            model: [{id: "", name: qsTr("None")}, {id: "__custom__", name: qsTr("Custom")}].concat(root.effects.presets)
            textRole: "name"
            valueRole: "id"
            currentIndex: {
                root.effects.bands
                if (!root.effects.filterEnabled("equalizer")) return 0
                if (!root.effects.preset) return 1
                return Math.max(1, model.findIndex(p => p.id === root.effects.preset))
            }
            onActivated: index => {
                if (!root.effects.begin()) return
                if (index === 0) root.effects.setFilterEnabled("equalizer", false)
                else if (index === 1 || root.effects.setPreset(model[index].id)) root.effects.setFilterEnabled("equalizer", true)
            }
            indicator: Image {
                x: presetBox.width - width - 10
                y: (presetBox.height - height) / 2
                width: VLCStyle.dp(18, VLCStyle.scale)
                height: width
                source: "qrc:///redesign/icons/chevron-down/default.png"
            }
            contentItem: Label {
                leftPadding: 12
                text: presetBox.displayText || qsTr("Custom")
                color: VLCStyle.redesign.color("#EAEAEA", "#2e2e2e")
                verticalAlignment: Text.AlignVCenter
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }
            background: Rectangle { color: VLCStyle.redesign.color("#191919", "#ababaa"); radius: 4 }
            delegate: ItemDelegate {
                width: presetBox.width
                text: modelData.name
                palette.text: VLCStyle.redesign.color("#EAEAEA", "#2e2e2e")
                background: Rectangle { color: highlighted ? VLCStyle.redesign.color("#222222", "#9c9c9b")
                                                      : VLCStyle.redesign.color("#191919", "#ababaa") }
            }
            popup: Popup {
                y: presetBox.height
                width: presetBox.width
                implicitHeight: Math.min(contentItem.implicitHeight, VLCStyle.dp(280, VLCStyle.scale))
                padding: 0
                contentItem: ListView { clip: true; implicitHeight: contentHeight; model: presetBox.popup.visible ? presetBox.delegateModel : null; currentIndex: presetBox.highlightedIndex }
                background: Rectangle { color: VLCStyle.redesign.color("#191919", "#ababaa"); border.color: VLCStyle.redesign.color("#373737", "#8e8e8d") }
            }
        }
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: root.expanded ? VLCStyle.dp(480, VLCStyle.scale) : VLCStyle.dp(42, VLCStyle.scale)
        color: VLCStyle.redesign.color("#1b1b1b", VLCStyle.palette.lightGrey200)
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: VLCStyle.dp(16, VLCStyle.scale)
            spacing: VLCStyle.dp(12, VLCStyle.scale)
            Button {
                Layout.alignment: Qt.AlignHCenter
                text: root.expanded ? qsTr("Close Equalizer") : qsTr("Open Equalizer")
                onClicked: root.expanded = !root.expanded
                background: Item {}
                contentItem: Label { text: parent.text; color: VLCStyle.redesign.color("#8F8F8F", "#7c7c7b"); font.pixelSize: VLCStyle.dp(14, VLCStyle.scale) }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.expanded
                spacing: VLCStyle.dp(5, VLCStyle.scale)
                Repeater {
                    model: 11
                    ColumnLayout {
                        id: bandColumn
                        required property int index
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: VLCStyle.dp(16, VLCStyle.scale)
                        readonly property real currentBand: index === 0 ? root.effects.preamp
                                                             : Number(root.effects.bands[index - 1] || 0)
                        Slider {
                            id: bandSlider
                            objectName: index === 0 ? "settingsEqualizerPreamp" : "settingsEqualizerBand" + (index - 1)
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillHeight: true
                            orientation: Qt.Vertical
                            from: -20
                            to: 20
                            Binding on value { when: !bandSlider.pressed; value: bandColumn.currentBand }
                            onMoved: {
                                if (index === 0) root.effects.setPreamp(value)
                                else root.effects.setBand(index - 1, value)
                            }
                            background: Rectangle {
                                x: (bandSlider.width - width) / 2
                                width: VLCStyle.dp(14, VLCStyle.scale)
                                height: bandSlider.height
                                radius: width / 2
                                color: VLCStyle.redesign.color("#090909", "#dedede")
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: (1 - bandSlider.visualPosition) * parent.height
                                    color: Qt.colorEqual(VLCStyle.redesign.accent, "#D37918")
                                           ? "#54300c" : Qt.darker(VLCStyle.redesign.accent, 2.5)
                                    radius: parent.radius
                                }
                            }
                            handle: Rectangle {
                                x: (bandSlider.width - width) / 2
                                y: bandSlider.topPadding + bandSlider.visualPosition * (bandSlider.availableHeight - height)
                                width: VLCStyle.dp(22, VLCStyle.scale)
                                height: VLCStyle.dp(7, VLCStyle.scale)
                                radius: 4
                                color: VLCStyle.redesign.accent
                            }
                        }
                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: index === 0 ? qsTr("Preamp")
                                  : Number(root.effects.frequencies[index - 1]) >= 1000
                                    ? (Number(root.effects.frequencies[index - 1]) / 1000) + " kHz"
                                    : Math.round(Number(root.effects.frequencies[index - 1] || 0)) + " Hz"
                            color: VLCStyle.redesign.color("#8F8F8F", "#7c7c7b")
                            font.family: VLCStyle.redesign.fontFamily
                            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                        }
                        TextField {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: VLCStyle.dp(61, VLCStyle.scale)
                            Layout.preferredHeight: VLCStyle.dp(32, VLCStyle.scale)
                            text: Number(currentBand).toFixed(1) + qsTr(" dB")
                            selectByMouse: true
                            horizontalAlignment: Text.AlignHCenter
                            onEditingFinished: {
                                const value = parseFloat(text)
                                if (Number.isFinite(value) && value >= -20 && value <= 20) {
                                    if (index === 0) root.effects.setPreamp(value)
                                    else root.effects.setBand(index - 1, value)
                                }
                            }
                            background: Rectangle { color: VLCStyle.redesign.color("#090909", "#dedede"); radius: 4 }
                            color: VLCStyle.redesign.color("#969696", "#4d4d4d")
                            font.pixelSize: VLCStyle.dp(10, VLCStyle.scale)
                        }
                    }
                }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Label { Layout.fillWidth: true; text: qsTr("Two-pass"); color: VLCStyle.redesign.color("#8F8F8F", "#7c7c7b"); font.pixelSize: VLCStyle.dp(14, VLCStyle.scale) }
        PanelToggle {
            id: twoPassSwitch
            checked: root.effects.twoPass
            onClicked: root.effects.setTwoPass(checked)
        }
    }
}
