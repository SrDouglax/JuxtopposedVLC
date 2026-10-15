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
    required property string filterId
    property bool expanded: false
    property var items: []
    spacing: 0

    function refresh() { items = effects.parameters(filterId).filter(p => p.type === "float") }
    Component.onCompleted: refresh()
    Connections {
        target: root.effects
        function onStateChanged() { root.refresh() }
    }

    T.Button {
        Layout.fillWidth: true
        implicitHeight: VLCStyle.dp(48, VLCStyle.scale)
        leftPadding: VLCStyle.dp(16, VLCStyle.scale)
        rightPadding: VLCStyle.dp(16, VLCStyle.scale)
        focusPolicy: Qt.StrongFocus
        Accessible.name: root.expanded ? qsTr("Collapse settings") : qsTr("Expand settings")
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
                color: VLCStyle.redesign.color("#8F8F8F", "#7c7c7b")
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
            spacing: VLCStyle.dp(18, VLCStyle.scale)
            Repeater {
                model: root.items
                ValueSlider {
                    required property var modelData
                    Layout.fillWidth: true
                    label: modelData.name
                    from: modelData.minimum
                    to: modelData.maximum
                    modelValue: modelData.value
                    decimals: modelData.maximum <= 1 ? 2 : 1
                    onEdited: (value) => root.effects.setParameter(modelData.id, value)
                }
            }
            T.Button {
                Layout.alignment: Qt.AlignRight
                text: qsTr("Reset")
                onClicked: root.effects.resetDefaults(root.filterId)
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
