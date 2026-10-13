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
    required property var option
    readonly property var currentValue: {
        effects.revision
        return effects.parameterValue(option.id)
    }
    spacing: VLCStyle.dp(8, VLCStyle.scale)

    ValueSlider {
        Layout.fillWidth: true
        visible: (option.type === "float" || option.type === "integer")
                 && option.minimum !== undefined && option.maximum !== undefined
        label: option.name
        from: option.minimum === undefined ? 0 : option.minimum
        to: option.maximum === undefined ? 1 : option.maximum
        modelValue: Number(root.currentValue)
        decimals: option.type === "integer" ? 0 : 2
        onEdited: (value) => root.effects.setParameter(option.id, option.type === "integer" ? Math.round(value) : value)
    }

    RowLayout {
        Layout.fillWidth: true
        visible: (root.option.type === "float" || root.option.type === "integer")
                 && root.option.minimum === undefined
        Text {
            Layout.fillWidth: true
            text: root.option.name
            color: VLCStyle.redesign.textMuted
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            elide: Text.ElideRight
        }
        Rectangle {
            width: VLCStyle.dp(116, VLCStyle.scale)
            height: VLCStyle.dp(32, VLCStyle.scale)
            radius: VLCStyle.dp(4, VLCStyle.scale)
            color: "#0E0E0E"
            TextInput {
                id: unboundedInput
                anchors.fill: parent
                anchors.leftMargin: VLCStyle.dp(10, VLCStyle.scale)
                verticalAlignment: TextInput.AlignVCenter
                color: VLCStyle.redesign.textSecondary
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                selectByMouse: true
                text: String(root.currentValue)
                Accessible.name: root.option.name
                onEditingFinished: {
                    const number = Number(text)
                    if (Number.isFinite(number) && (root.option.type !== "integer" || Number.isInteger(number)))
                        root.effects.setParameter(root.option.id, number)
                    text = String(root.effects.parameterValue(root.option.id))
                }
                Connections {
                    target: root.effects
                    function onStateChanged() {
                        if (!unboundedInput.activeFocus)
                            unboundedInput.text = String(root.currentValue)
                    }
                }
            }
        }
    }

    T.CheckBox {
        id: boolOption
        visible: option.type === "bool"
        text: option.name
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        Binding on checked { when: !boolOption.pressed; value: Boolean(root.currentValue) }
        onClicked: root.effects.setParameter(option.id, checked)
        indicator: Rectangle {
            implicitWidth: VLCStyle.dp(18, VLCStyle.scale)
            implicitHeight: implicitWidth
            radius: VLCStyle.dp(3, VLCStyle.scale)
            color: boolOption.checked ? VLCStyle.redesign.accent : "#0E0E0E"
            border.color: boolOption.checked ? VLCStyle.redesign.accent : VLCStyle.redesign.border
            Image {
                anchors.centerIn: parent
                source: "qrc:///redesign/icons/check/selected.png"
                visible: boolOption.checked
                sourceSize.width: VLCStyle.dp(14, VLCStyle.scale)
                sourceSize.height: VLCStyle.dp(14, VLCStyle.scale)
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: option.type === "color"
        Text {
            text: root.option.name
            Layout.fillWidth: true
            color: VLCStyle.redesign.textMuted
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }
        Rectangle {
            width: VLCStyle.dp(130, VLCStyle.scale)
            height: VLCStyle.dp(32, VLCStyle.scale)
            radius: VLCStyle.dp(4, VLCStyle.scale)
            color: "#0E0E0E"
            RowLayout {
                anchors.fill: parent
                anchors.margins: VLCStyle.dp(6, VLCStyle.scale)
                TextInput {
                    id: colorInput
                    Layout.fillWidth: true
                    text: "#" + Number(root.currentValue).toString(16).padStart(6, "0").toUpperCase()
                    color: VLCStyle.redesign.textSecondary
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                    selectByMouse: true
                    maximumLength: 7
                    onEditingFinished: {
                        if (/^#[0-9a-fA-F]{6}$/.test(text))
                            root.effects.setParameter(root.option.id, parseInt(text.slice(1), 16))
                        text = "#" + Number(root.effects.parameterValue(root.option.id)).toString(16).padStart(6, "0").toUpperCase()
                    }
                }
                Rectangle {
                    width: VLCStyle.dp(20, VLCStyle.scale)
                    height: width
                    radius: VLCStyle.dp(2, VLCStyle.scale)
                    color: "#" + Number(root.currentValue).toString(16).padStart(6, "0")
                }
            }
        }
    }

    T.Button {
        id: choiceButton
        Layout.fillWidth: true
        visible: option.type === "choice"
        implicitHeight: VLCStyle.dp(40, VLCStyle.scale)
        leftPadding: VLCStyle.dp(12, VLCStyle.scale)
        rightPadding: VLCStyle.dp(12, VLCStyle.scale)
        onClicked: choicePopup.open()
        Accessible.name: root.option.name
        background: Rectangle { color: "#0E0E0E"; radius: VLCStyle.dp(5, VLCStyle.scale) }
        contentItem: RowLayout {
            Text {
                Layout.fillWidth: true
                text: root.option.name + ": " + root.currentValue
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
        T.Popup {
            id: choicePopup
            parent: choiceButton
            y: choiceButton.height + VLCStyle.dp(4, VLCStyle.scale)
            width: choiceButton.width
            padding: VLCStyle.dp(6, VLCStyle.scale)
            closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside
            background: Rectangle { color: "#1B1B1B"; radius: VLCStyle.dp(6, VLCStyle.scale) }
            contentItem: ColumnLayout {
                Repeater {
                    model: root.effects.choices(root.option.id)
                    delegate: T.Button {
                        required property var modelData
                        Layout.fillWidth: true
                        text: modelData.name
                        implicitHeight: VLCStyle.dp(34, VLCStyle.scale)
                        onClicked: {
                            if (root.effects.setParameter(root.option.id, modelData.id)) choicePopup.close()
                        }
                        background: Rectangle { color: parent.hovered ? VLCStyle.redesign.controlHoverBackground : "transparent" }
                        contentItem: Text {
                            text: parent.text
                            color: VLCStyle.redesign.textSecondary
                            font.family: VLCStyle.redesign.fontFamily
                            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                        }
                    }
                }
            }
        }
    }
}
