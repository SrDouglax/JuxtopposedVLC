/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Controls.Basic as C
import VLC.Player
import VLC.Dialogs
import VLC.MainInterface
import VLC.Style

Item {
    C.Label {
        anchors {
            top: parent.top
            right: parent.right
            margins: 56
        }
        visible: MainCtx.playerView && Player.isStarted && PlayerPanelState.showStatistics
        padding: VLCStyle.dp(16, VLCStyle.scale)
        color: "#eaeaea"
        text: qsTr("Decoded video: %1\nDisplayed frames: %2\nLost frames: %3\nDecoded audio: %4\nInput bitrate: %5 kbit/s").arg(PlayerPanelState.statistics.decodedVideo ?? 0).arg(PlayerPanelState.statistics.displayedVideo ?? 0).arg(PlayerPanelState.statistics.lostVideo ?? 0).arg(PlayerPanelState.statistics.decodedAudio ?? 0).arg(Number(PlayerPanelState.statistics.bitrate ?? 0).toFixed(0))
        background: Rectangle {
            color: "#cc0e0e0e"
            radius: VLCStyle.dp(6, VLCStyle.scale)
        }
    }
}
