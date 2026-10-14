/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import VLC.Dialogs
import VLC.Player
import VLC.Style

Canvas {
    id: root
    visible: PlayerPanelState.showSubtitleTimeline && PlayerPanelState.timelineAvailable
    onVisibleChanged: requestPaint()
    onWidthChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        if (!visible || Player.length.toSeconds() <= 0)
            return;
        const duration = Player.length.toSeconds(), delay = Player.subtitleDelayMS / 1000;
        const cues = PlayerPanelState.cues;
        ctx.fillStyle = VLCStyle.redesign.accentBackground;
        for (const cue of cues) {
            const start = Math.max(0, Math.min(width, (cue.start + delay) / duration * width));
            const end = Math.max(0, Math.min(width, (cue.end + delay) / duration * width));
            if (end > start)
                ctx.fillRect(start, 0, Math.max(1, end - start - 1), height);
        }
    }
    Connections {
        target: PlayerPanelState
        function onChanged() {
            root.requestPaint();
        }
    }
    Connections {
        target: Player
        function onLengthChanged() {
            root.requestPaint();
        }
        function onSubtitleDelayChanged() {
            root.requestPaint();
        }
    }
}
