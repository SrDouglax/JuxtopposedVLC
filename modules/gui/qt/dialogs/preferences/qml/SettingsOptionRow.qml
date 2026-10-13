/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import VLC.Style

Item {
    id: root
    property string settingKey
    property string label
    property string help
    property string settingType
    property var settingValue
    property var choices: []
    property var minimum
    property var maximum
    property string editorKind: ""
    property bool dirty: false
    readonly property bool dark: VLCStyle.palette.isDark
    readonly property bool useSlider: editorKind === "slider" && choices.length === 0
                                      && (settingType === "integer" || settingType === "float")
                                      && minimum !== undefined && minimum !== null
                                      && maximum !== undefined && maximum !== null
                                      && Number(minimum) < Number(maximum)
    signal commit(var value)
    signal browseRequested()

    implicitHeight: VLCStyle.dp(46, VLCStyle.scale)

    Label {
        id: settingLabel
        anchors.left: parent.left
        anchors.right: valueArea.left
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        text: root.label + (root.dirty ? "  •" : "")
        color: root.dirty ? VLCStyle.redesign.accent
                          : (root.dark ? "#949494" : "#494949")
        elide: Text.ElideRight
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)

        HoverHandler { id: labelHover }
        ToolTip.visible: labelHover.hovered && root.help.length > 0
        ToolTip.text: root.help
        ToolTip.delay: 650
    }

    Item {
        id: valueArea
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(VLCStyle.dp(320, VLCStyle.scale), root.width * 0.46)
        height: VLCStyle.dp(34, VLCStyle.scale)

        Button {
            id: booleanControl
            objectName: "settingToggle_" + root.settingKey
            visible: root.settingType === "boolean"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: VLCStyle.dp(66, VLCStyle.scale)
            height: parent.height - 5
            onClicked: root.commit(!root.settingValue)
            Accessible.name: root.label
            background: Rectangle {
                color: root.dark ? "#191919" : "#eeeeee"
                border.color: root.dark ? "#292929" : "#cccccc"
                radius: 4
            }
            contentItem: Row {
                spacing: 3
                anchors.centerIn: parent
                Rectangle {
                    width: VLCStyle.dp(27, VLCStyle.scale)
                    height: VLCStyle.dp(24, VLCStyle.scale)
                    radius: 3
                    color: root.settingValue ? VLCStyle.redesign.accentBackground : "#4b4b4b"
                    Label {
                        anchors.centerIn: parent
                        text: root.settingValue ? qsTr("ON") : ""
                        color: VLCStyle.redesign.accent
                        font.pixelSize: VLCStyle.dp(10, VLCStyle.scale)
                    }
                }
                Rectangle {
                    width: VLCStyle.dp(27, VLCStyle.scale)
                    height: VLCStyle.dp(24, VLCStyle.scale)
                    radius: 3
                    color: root.settingValue ? VLCStyle.redesign.accentDim : (root.dark ? "#252525" : "#dddddd")
                    Label {
                        anchors.centerIn: parent
                        text: root.settingValue ? "" : qsTr("OFF")
                        color: "#858585"
                        font.pixelSize: VLCStyle.dp(10, VLCStyle.scale)
                    }
                }
            }
        }

        ComboBox {
            id: choiceControl
            objectName: "settingChoice_" + root.settingKey
            visible: root.settingType !== "boolean" && root.choices.length > 0
            anchors.fill: parent
            model: root.choices
            textRole: "label"
            function valueIndex() {
                for (let i = 0; i < root.choices.length; ++i)
                    if (root.choices[i].value === root.settingValue)
                        return i
                return -1
            }
            currentIndex: valueIndex()
            onActivated: (index) => root.commit(root.choices[index].value)
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            leftPadding: 12
            rightPadding: 34
            contentItem: Label {
                text: choiceControl.displayText
                color: root.dark ? "#d4d4d4" : "#292929"
                font: choiceControl.font
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            indicator: Image {
                x: choiceControl.width - width - 10
                y: (choiceControl.height - height) / 2
                width: 18
                height: 18
                source: "qrc:///redesign/icons/chevron-down/default.png"
            }
            background: Rectangle {
                color: root.dark ? "#171717" : "#f4f4f4"
                border.color: choiceControl.activeFocus ? VLCStyle.redesign.accent
                                                        : (root.dark ? "#2b2b2b" : "#cccccc")
                radius: 4
            }
            delegate: ItemDelegate {
                required property var modelData
                width: choiceControl.width
                height: VLCStyle.dp(34, VLCStyle.scale)
                contentItem: Label {
                    text: modelData.label
                    color: root.dark ? "#d4d4d4" : "#292929"
                    font: choiceControl.font
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                background: Rectangle {
                    color: parent.highlighted ? (root.dark ? "#303030" : "#e5e5e5")
                                              : (root.dark ? "#191919" : "#f7f7f7")
                }
            }
            popup: Popup {
                y: choiceControl.height
                width: choiceControl.width
                implicitHeight: Math.min(contentItem.implicitHeight,
                                         VLCStyle.dp(280, VLCStyle.scale))
                padding: 1
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: choiceControl.popup.visible ? choiceControl.delegateModel : null
                    currentIndex: choiceControl.highlightedIndex
                    ScrollIndicator.vertical: ScrollIndicator {}
                }
                background: Rectangle {
                    color: root.dark ? "#191919" : "#f7f7f7"
                    border.color: root.dark ? "#383838" : "#cccccc"
                    radius: 4
                }
            }
        }

        Slider {
            id: rangeControl
            objectName: "settingRange_" + root.settingKey
            visible: root.useSlider
            anchors.left: parent.left
            anchors.right: rangeValue.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            from: Number(root.minimum || 0)
            to: Number(root.maximum || 1)
            value: Number(root.settingValue)
            stepSize: root.settingType === "integer" ? 1 : 0.01
            snapMode: Slider.SnapAlways
            onMoved: root.commit(root.settingType === "integer" ? Math.round(value) : value)
        }
        Label {
            id: rangeValue
            visible: root.useSlider
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: VLCStyle.dp(44, VLCStyle.scale)
            text: root.settingType === "integer" ? String(root.settingValue)
                  : Number(root.settingValue).toFixed(2)
            color: root.dark ? "#999999" : "#555555"
            font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
            horizontalAlignment: Text.AlignRight
        }

        TextField {
            id: textControl
            anchors.rightMargin: root.editorKind === "savefile" ? 94 : 0
            objectName: "settingInput_" + root.settingKey
            visible: root.settingType !== "boolean" && root.choices.length === 0
                     && !root.useSlider
            anchors.fill: parent
            text: root.settingValue === undefined || root.settingValue === null
                  ? "" : String(root.settingValue)
            selectByMouse: true
            inputMethodHints: root.settingType === "integer" || root.settingType === "float"
                              ? Qt.ImhFormattedNumbersOnly : Qt.ImhNone
            onEditingFinished: {
                if (text !== String(root.settingValue))
                    root.commit(text)
            }
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            color: root.dark ? "#d4d4d4" : "#292929"
            background: Rectangle {
                color: root.dark ? "#111111" : "#fafafa"
                border.color: textControl.activeFocus ? VLCStyle.redesign.accent
                                                      : (root.dark ? "#2c2c2c" : "#cccccc")
                radius: 4
            }
            leftPadding: 12
            rightPadding: 12
        }
        ActionButton {
            visible: root.editorKind === "savefile"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 88
            text: qsTr("Browse")
            onClicked: root.browseRequested()
        }
    }
}
