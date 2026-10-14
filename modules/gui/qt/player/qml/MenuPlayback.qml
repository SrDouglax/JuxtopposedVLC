/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as C
import VLC.Player
import VLC.Playlist
import VLC.Dialogs
import VLC.Style

ColumnLayout {
    id: root
    required property var menu
    spacing: VLCStyle.dp(12, VLCStyle.scale)
    PanelField {
        Layout.fillWidth: true
        label: qsTr("Show Subtitle Timeline on Seekbar")
        controlWidth: VLCStyle.dp(64, VLCStyle.scale)
        PanelToggle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            objectName: "playerSubtitleTimeline"
            checked: PlayerPanelState.showSubtitleTimeline
            enabled: PlayerPanelState.timelineAvailable
            onClicked: PlayerPanelState.showSubtitleTimeline = checked
            C.ToolTip.visible: hovered && !enabled
            C.ToolTip.text: qsTr("Available for a single external SRT subtitle source")
        }
    }
    PanelField {
        Layout.fillWidth: true
        label: qsTr("Show Statistics")
        controlWidth: VLCStyle.dp(64, VLCStyle.scale)
        PanelToggle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            objectName: "playerShowStatistics"
            checked: PlayerPanelState.showStatistics
            onClicked: PlayerPanelState.showStatistics = checked
        }
    }
    PanelField {
        Layout.fillWidth: true
        label: qsTr("Reverse")
        controlWidth: VLCStyle.dp(64, VLCStyle.scale)
        PanelToggle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: Player.rate < 0
            enabled: Player.ratechangable
            onClicked: Player.reverse()
        }
    }
    PanelField {
        Layout.fillWidth: true
        label: qsTr("Sleep Timer")
        PanelCombo {
            anchors.fill: parent
            model: [qsTr("Off"), qsTr("15 minutes"), qsTr("30 minutes"), qsTr("1 hour"), qsTr("2 hours")]
            currentIndex: root.menu.timerController?.active ? [900, 1800, 3600, 7200].findIndex(s => s >= root.menu.timerController.remainingSeconds) + 1 : 0
            onActivated: index => {
                if (index === 0)
                    root.menu.timerController.cancel();
                else
                    root.menu.timerController.start([0, 900, 1800, 3600, 7200][index], SleepTimerController.Stop);
            }
        }
    }
    PanelField {
        Layout.fillWidth: true
        label: qsTr("Audio Visualizer")
        PanelChoice {
            anchors.fill: parent
            model: Player.audioVisualization
        }
    }
    PanelRange {
        Layout.fillWidth: true
        objectName: "playerSpeedRange"
        ticks: [0.25,0.5,0.75,1,1.25,1.5,1.75,2]
        label: qsTr("Speed")
        minimum: 0.25
        maximum: 2
        step: 0.25
        suffix: "x"
        value: Math.abs(Player.rate)
        enabled: Player.ratechangable
        onEdited: number => Player.rate = (Player.rate < 0 ? -1 : 1) * number
    }
}
