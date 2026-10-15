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
    readonly property bool tickedSlider: useSlider && (["rate", "qt-max-volume", "sub-text-scale"].includes(settingKey) || editorKind === "opacity" || settingKey === "composite_hideafter")
    readonly property var tickValues: settingKey === "rate" ? [0.25,0.5,0.75,1,1.25,1.5,1.75,2] : [0,0.5,1]
    readonly property bool dark: VLCStyle.palette.isDark
    readonly property bool colorEditor: settingKey.endsWith("-color") || editorKind === "color"
    readonly property bool useSlider: (editorKind === "slider" || editorKind === "opacity")
                                      && choices.length === 0
                                      && (settingType === "integer" || settingType === "float")
                                      && minimum !== undefined && minimum !== null
                                      && maximum !== undefined && maximum !== null
                                      && Number(minimum) < Number(maximum)
    signal commit(var value)
    signal browseRequested()

    implicitHeight: VLCStyle.dp(tickedSlider ? 64 : 46, VLCStyle.scale)

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

    Image {
        x: Math.min(settingLabel.implicitWidth + VLCStyle.dp(8, VLCStyle.scale), settingLabel.width - width)
        anchors.verticalCenter: settingLabel.verticalCenter
        width: VLCStyle.dp(16, VLCStyle.scale)
        height: width
        visible: root.help.length > 0
        source: "qrc:///redesign/icons/info/default.png"
        HoverHandler { id: helpHover }
        ToolTip.visible: helpHover.hovered
        ToolTip.text: root.help
        ToolTip.delay: 450
    }

    Item {
        id: valueArea
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(VLCStyle.dp(320, VLCStyle.scale), root.width * 0.46)
        height: VLCStyle.dp(root.tickedSlider ? 50 : 34, VLCStyle.scale)

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
            visible: root.settingType !== "boolean" && root.choices.length > 0 && !root.colorEditor
            anchors.fill: parent
            editable: root.editorKind === "custom-choice"
            onAccepted: root.commit(editText)
            model: root.choices
            textRole: "label"
            function valueIndex() {
                for (let i = 0; i < root.choices.length; ++i)
                    if (String(root.choices[i].value) === String(root.settingValue))
                        return i
                return -1
            }
            currentIndex: valueIndex()
            onActivated: (index) => root.commit(root.choices[index].value)
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            leftPadding: 12
            rightPadding: 34
            contentItem: TextField {
                readOnly: !choiceControl.editable
                padding: 0
                background: Item {}
                onEditingFinished: if (choiceControl.editable && text !== choiceControl.displayText) root.commit(text)
                text: choiceControl.currentIndex < 0 ? String(root.settingValue || "") : choiceControl.displayText
                color: root.dark ? "#8f8f8f" : "#494949"
                font: choiceControl.font
                verticalAlignment: Text.AlignVCenter
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
                    color: root.dark ? "#8f8f8f" : "#494949"
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
            anchors.right: root.tickedSlider ? parent.right : rangeValue.left
            anchors.rightMargin: root.tickedSlider ? 0 : 8
            anchors.top: parent.top
            height: VLCStyle.dp(34, VLCStyle.scale)
            from: root.settingKey === "rate" ? 0.25 : root.settingKey === "qt-max-volume" ? 100 : Number(root.minimum || 0)
            to: root.settingKey === "rate" ? 2 : Number(root.maximum || 1)
            value: Number(root.settingValue)
            stepSize: root.settingKey === "rate" ? 0.25 : root.settingType === "integer" ? 1 : 0.01
            snapMode: Slider.SnapAlways
            onMoved: root.commit(root.settingType === "integer" ? Math.round(value) : value)
            background: Rectangle {
                x: rangeControl.leftPadding
                y: (rangeControl.height - height) / 2
                width: rangeControl.availableWidth
                height: VLCStyle.dp(6, VLCStyle.scale)
                radius: height / 2
                color: VLCStyle.redesign.color("#090909", "#ababaa")
                Rectangle {
                    width: rangeControl.visualPosition * parent.width
                    height: parent.height
                    radius: parent.radius
                    color: VLCStyle.redesign.accentBackground
                }
            }
            handle: Rectangle {
                x: rangeControl.leftPadding + rangeControl.visualPosition * (rangeControl.availableWidth - width)
                y: (rangeControl.height - height) / 2
                width: VLCStyle.dp(8, VLCStyle.scale)
                height: VLCStyle.dp(24, VLCStyle.scale)
                radius: VLCStyle.dp(4, VLCStyle.scale)
                color: VLCStyle.redesign.accent
                border.color: rangeControl.activeFocus ? VLCStyle.redesign.textPrimary : "transparent"
            }
        }
        Label {
            id: rangeValue
            visible: root.useSlider && !root.tickedSlider
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: VLCStyle.dp(44, VLCStyle.scale)
            text: root.editorKind === "opacity"
                  ? Math.round(100 * Number(root.settingValue) / Number(root.maximum)) + "%"
                  : root.settingType === "integer" ? String(root.settingValue)
                  : Number(root.settingValue).toFixed(2)
            color: root.dark ? "#999999" : "#555555"
            font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
            horizontalAlignment: Text.AlignRight
        }

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: VLCStyle.dp(14, VLCStyle.scale)
            visible: root.tickedSlider
            Repeater {
                model: root.tickValues
                Label {
                    required property var modelData
                    required property int index
                    readonly property real fraction: index / (root.tickValues.length - 1)
                    x: fraction * (parent.width - width)
                    text: root.settingKey === "rate" ? String(modelData)
                          : root.editorKind === "opacity" ? Math.round(modelData * 100) + "%"
                          : root.settingKey === "composite_hideafter" ? (modelData * 10) + " s"
                          : Math.round(rangeControl.from + modelData * (rangeControl.to - rangeControl.from)) + "%"
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
                    color: VLCStyle.redesign.color("#6b6b6b", "#777777")
                }
            }
        }

        TextField {
            id: textControl
            anchors.rightMargin: root.editorKind === "savefile" || root.editorKind === "directory" || root.editorKind === "skinfile"
                                 ? 94 : 0
            objectName: "settingInput_" + root.settingKey
            visible: root.settingType !== "boolean" && (root.choices.length === 0 || root.colorEditor)
                     && !root.useSlider
            anchors.fill: parent
            text: root.settingValue === undefined || root.settingValue === null
                  ? "" : root.colorEditor ? "#" + Number(root.settingValue).toString(16).padStart(6, "0").toUpperCase()
                  : root.settingType === "float"
                  ? String(Number(Number(root.settingValue).toFixed(6))) : String(root.settingValue)
            selectByMouse: true
            inputMethodHints: root.settingType === "integer" || root.settingType === "float"
                              ? Qt.ImhFormattedNumbersOnly : Qt.ImhNone
            echoMode: root.editorKind === "password" ? TextInput.Password : TextInput.Normal
            onEditingFinished: {
                if (root.colorEditor) {
                    if (/^#[0-9a-fA-F]{6}$/.test(text)) root.commit(parseInt(text.slice(1), 16))
                    return
                }
                if (text !== String(root.settingValue))
                    root.commit(text)
            }
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            color: root.dark ? "#8f8f8f" : "#494949"
            background: Rectangle {
                color: root.dark ? "#111111" : "#fafafa"
                border.color: textControl.activeFocus ? VLCStyle.redesign.accent
                                                      : (root.dark ? "#2c2c2c" : "#cccccc")
                radius: 4
            }
            leftPadding: 12
            rightPadding: root.colorEditor ? VLCStyle.dp(38, VLCStyle.scale) : 12
            Rectangle {
                visible: root.colorEditor
                anchors.right: parent.right
                anchors.rightMargin: VLCStyle.dp(6, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                width: VLCStyle.dp(20, VLCStyle.scale)
                height: width
                radius: VLCStyle.dp(2, VLCStyle.scale)
                color: "#" + Number(root.settingValue || 0).toString(16).padStart(6, "0")
            }
        }
        ActionButton {
            visible: root.editorKind === "savefile" || root.editorKind === "directory" || root.editorKind === "skinfile"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 88
            text: qsTr("Browse")
            onClicked: root.browseRequested()
        }
    }
}
