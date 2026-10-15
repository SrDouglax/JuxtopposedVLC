/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 or later.
 *****************************************************************************/
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import VLC.Style
import VLC.Player

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
            color: VLCStyle.redesign.color("#EAEAEA", "#2e2e2e")
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
            font.weight: Font.Medium
        }
        PanelToggle {
            id: enabledCheck
            objectName: "fxEnabled-" + root.filterId
            Accessible.name: qsTr("Enable %1").arg(root.title)
            checked: { root.revision; return root.effects.filterEnabled(root.filterId) }
            enabled: root.effects.activeAudio
            onClicked: if (root.effects.begin()) root.effects.setFilterEnabled(root.filterId, checked)
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
