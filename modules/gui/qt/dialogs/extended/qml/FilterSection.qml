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
    required property string title
    property int revision: 0
    spacing: VLCStyle.dp(8, VLCStyle.scale)
    visible: effects.filterAvailable(filterId)

    Connections {
        target: root.effects
        function onStateChanged() { root.revision++ }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: VLCStyle.dp(4, VLCStyle.scale)
        Text {
            Layout.fillWidth: true
            text: root.title
            color: VLCStyle.redesign.textPrimary
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
            font.weight: Font.Medium
        }
        T.CheckBox {
            id: enabledCheck
            objectName: "fxEnabled-" + root.filterId
            focusPolicy: Qt.StrongFocus
            Accessible.name: qsTr("Enable %1").arg(root.title)
            Binding on checked {
                when: !enabledCheck.pressed
                value: { root.revision; return root.effects.filterEnabled(root.filterId) }
            }
            onClicked: root.effects.setFilterEnabled(root.filterId, checked)
            indicator: Rectangle {
                implicitWidth: VLCStyle.dp(36, VLCStyle.scale)
                implicitHeight: VLCStyle.dp(20, VLCStyle.scale)
                radius: height / 2
                color: enabledCheck.checked ? VLCStyle.redesign.accent : "#373737"
                Rectangle {
                    x: enabledCheck.checked ? parent.width - width - VLCStyle.dp(3, VLCStyle.scale) : VLCStyle.dp(3, VLCStyle.scale)
                    anchors.verticalCenter: parent.verticalCenter
                    width: VLCStyle.dp(14, VLCStyle.scale)
                    height: width
                    radius: width / 2
                    color: "#EAEAEA"
                }
            }
        }
    }

    Loader {
        id: panel
        Layout.fillWidth: true
        sourceComponent: root.filterId === "equalizer" ? equalizerComponent : genericComponent
        Component {
            id: equalizerComponent
            EqualizerPanel { effects: root.effects }
        }
        Component {
            id: genericComponent
            FilterPanel { effects: root.effects; filterId: root.filterId }
        }
    }
}
