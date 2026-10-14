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
        Switch {
            id: enabledSwitch
            objectName: "settingsEqualizerEnabled"
            Accessible.name: qsTr("Equalizer")
            Binding on checked {
                when: !enabledSwitch.pressed
                value: { root.effects.bands; return root.effects.filterEnabled("equalizer") }
            }
            onClicked: root.effects.setFilterEnabled("equalizer", checked)
            indicator: Rectangle {
                implicitWidth: VLCStyle.dp(40, VLCStyle.scale)
                implicitHeight: VLCStyle.dp(22, VLCStyle.scale)
                radius: height / 2
                color: enabledSwitch.checked ? VLCStyle.redesign.accent : "#373737"
                Rectangle {
                    x: enabledSwitch.checked ? parent.width - width - 3 : 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: VLCStyle.dp(16, VLCStyle.scale)
                    height: width
                    radius: width / 2
                    color: "#eaeaea"
                }
            }
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
            model: root.effects.presets
            textRole: "name"
            valueRole: "id"
            currentIndex: {
                const index = root.effects.presets.findIndex(p => p.id === root.effects.preset)
                return index
            }
            onActivated: (index) => root.effects.setPreset(root.effects.presets[index].id)
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
                        spacing: VLCStyle.dp(6, VLCStyle.scale)
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
                                color: "#0e0e0e"
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: bandSlider.visualPosition * parent.height
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
                                  : Math.round(Number(root.effects.frequencies[index - 1] || 0)) + qsTr(" Hz")
                            color: VLCStyle.redesign.color("#8F8F8F", "#7c7c7b")
                            font.pixelSize: VLCStyle.dp(10, VLCStyle.scale)
                        }
                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: Number(currentBand).toFixed(1) + qsTr(" dB")
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
        Switch {
            id: twoPassSwitch
            Binding on checked { when: !twoPassSwitch.pressed; value: root.effects.twoPass }
            onClicked: root.effects.setTwoPass(checked)
            indicator: Rectangle {
                implicitWidth: VLCStyle.dp(40, VLCStyle.scale)
                implicitHeight: VLCStyle.dp(22, VLCStyle.scale)
                radius: height / 2
                color: twoPassSwitch.checked ? VLCStyle.redesign.accent : "#373737"
                Rectangle {
                    x: twoPassSwitch.checked ? parent.width - width - 3 : 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: VLCStyle.dp(16, VLCStyle.scale)
                    height: width
                    radius: width / 2
                    color: "#eaeaea"
                }
            }
        }
    }
}
