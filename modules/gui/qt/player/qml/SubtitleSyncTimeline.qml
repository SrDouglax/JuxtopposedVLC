/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 or later.
 *****************************************************************************/
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls

import VLC.Util
import VLC.Player
import VLC.Style

ColumnLayout {
    id: root
    objectName: "subtitleSyncTimeline"
    property var presets: null
    property var reveal: null
    spacing: VLCStyle.dp(12, VLCStyle.scale)

    DelayEstimator {
        id: estimator
        onDelayChanged: Player.addSubtitleDelay(estimator.delay)
    }
    Connections {
        target: Player
        function onInputChanged() { estimator.reset() }
    }

    RowLayout {
        Layout.fillWidth: true
        Controls.Label {
            Layout.fillWidth: true
            text: qsTr("Subtitle timing")
            color: VLCStyle.redesign.textPrimary
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
        }
        Controls.Label {
            text: (Player.subtitleDelayMS >= 0 ? "+" : "") + Player.subtitleDelayMS + qsTr(" ms")
            color: VLCStyle.redesign.textSecondary
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
        }
    }

    Controls.Slider {
        id: timeline
        objectName: "subtitleTimingSlider"
        Layout.fillWidth: true
        from: -10000
        to: 10000
        stepSize: 50
        value: Player.subtitleDelayMS
        enabled: Player.isStarted
        Accessible.name: qsTr("Primary subtitle delay")
        onMoved: Player.subtitleDelayMS = value
        background: Rectangle {
            x: timeline.leftPadding
            y: timeline.topPadding + timeline.availableHeight / 2 - height / 2
            width: timeline.availableWidth
            height: VLCStyle.dp(4, VLCStyle.scale)
            radius: height / 2
            color: VLCStyle.redesign.seekBackground
            Rectangle {
                x: parent.width / 2
                width: VLCStyle.dp(1, VLCStyle.scale)
                height: VLCStyle.dp(12, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                color: VLCStyle.redesign.textSecondary
            }
        }
        handle: Rectangle {
            x: timeline.leftPadding + timeline.visualPosition * (timeline.availableWidth - width)
            y: timeline.topPadding + timeline.availableHeight / 2 - height / 2
            width: VLCStyle.dp(14, VLCStyle.scale)
            height: width
            radius: width / 2
            color: VLCStyle.redesign.accent
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: VLCStyle.dp(8, VLCStyle.scale)
        TimelineButton {
            objectName: "subtitleVoiceMark"
            text: estimator.isHeardTimeMarked ? qsTr("Voice marked") : qsTr("Mark voice heard")
            enabled: Player.isStarted
            onClicked: estimator.markHeardTime()
        }
        TimelineButton {
            objectName: "subtitleTextMark"
            text: estimator.isSpottedTimeMarked ? qsTr("Text marked") : qsTr("Mark text seen")
            enabled: Player.isStarted
            onClicked: estimator.markSpottedTime()
        }
        TimelineButton {
            objectName: "subtitleTimingReset"
            text: qsTr("Reset")
            enabled: Player.isStarted && Player.subtitleDelayMS !== 0
            onClicked: {
                Player.subtitleDelayMS = 0
                estimator.reset()
            }
        }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: VLCStyle.redesign.separator }

    RowLayout {
        Layout.fillWidth: true
        spacing: VLCStyle.dp(8, VLCStyle.scale)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: VLCStyle.dp(2, VLCStyle.scale)
            Controls.Label {
                text: qsTr("Series preset")
                color: VLCStyle.redesign.textPrimary
                font.family: VLCStyle.redesign.fontFamily
            }
            Controls.Label {
                Layout.fillWidth: true
                text: root.presets && root.presets.label ?
                      qsTr("Applies to episodes of %1").arg(root.presets.label) :
                      qsTr("Play a local episode to save its track and timing choices.")
                color: VLCStyle.redesign.textSecondary
                font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
                elide: Text.ElideRight
            }
        }
        TimelineButton {
            objectName: "subtitlePresetSave"
            text: qsTr("Save")
            enabled: root.presets && root.presets.seriesKey && Player.isStarted
            onClicked: root.presets.saveCurrent()
        }
        TimelineButton {
            objectName: "subtitlePresetClear"
            text: qsTr("Remove")
            enabled: root.presets && root.presets.preset
            onClicked: root.presets.clear()
        }
    }
    Controls.Label {
        Layout.fillWidth: true
        visible: root.presets && root.presets.status.length > 0
        text: root.presets ? root.presets.status : ""
        color: VLCStyle.redesign.textSecondary
        font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
        wrapMode: Text.WordWrap
    }

    component TimelineButton: Controls.Button {
        implicitHeight: VLCStyle.dp(34, VLCStyle.scale)
        focusPolicy: Qt.StrongFocus
        onActiveFocusChanged: if (activeFocus && root.reveal) root.reveal(this)
        background: Rectangle {
            color: parent.hovered || parent.activeFocus
                   ? VLCStyle.redesign.controlHoverBackground : VLCStyle.redesign.controlBackground
            border.color: parent.activeFocus ? VLCStyle.redesign.focusColor : VLCStyle.redesign.border
            radius: VLCStyle.dp(4, VLCStyle.scale)
        }
        contentItem: Controls.Label {
            text: parent.text
            color: parent.enabled ? VLCStyle.redesign.textPrimary : VLCStyle.redesign.textMuted
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            leftPadding: VLCStyle.dp(8, VLCStyle.scale)
            rightPadding: VLCStyle.dp(8, VLCStyle.scale)
        }
    }
}
