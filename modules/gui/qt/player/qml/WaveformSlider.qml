/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 or later.
 *****************************************************************************/
import QtQuick
import VLC.Player
import VLC.Style

SliderBar {
    id: root
    objectName: "waveformSlider"
    redesign: true
    barHeight: VLCStyle.dp(32, VLCStyle.scale)

    Waveform {
        id: analysis
        objectName: "waveformAnalysis"
        source: Player.videoTracks.count === 0 ? Player.url : ""
        durationSeconds: Player.length.toSeconds()
    }

    Canvas {
        id: graph
        anchors.fill: parent
        visible: analysis.ready
        renderTarget: Canvas.Image
        onVisibleChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: analysis
            function onBinsChanged() { graph.requestPaint() }
        }
        Connections {
            target: Player
            function onPositionChanged() { graph.requestPaint() }
        }
        Connections {
            target: VLCStyle.redesign
            function onAccentChanged() { graph.requestPaint() }
        }
        onPaint: {
            const bins = analysis.bins
            if (!analysis.ready || width <= 0 || height <= 0 || bins.length !== 512) return
            const paint = getContext("2d")
            paint.clearRect(0, 0, width, height)
            paint.fillStyle = VLCStyle.redesign.color(VLCStyle.redesign.playerControlBackground, "#ababaa")
            paint.fillRect(0, 0, width, height)
            const columns = Math.max(1, Math.min(512, Math.floor(width / 2)))
            let largest = 0
            for (let i = 0; i < bins.length; ++i) largest = Math.max(largest, Number(bins[i]))
            const scale = Math.max(largest, 0.05)
            const slot = width / columns
            const played = Math.max(0, Math.min(1, Number(Player.position)))
            for (let column = 0; column < columns; ++column) {
                const first = Math.floor(column * bins.length / columns)
                const last = Math.max(first + 1, Math.floor((column + 1) * bins.length / columns))
                let peak = 0
                for (let bin = first; bin < last; ++bin) peak = Math.max(peak, Number(bins[bin]))
                if (peak <= 0) continue
                const barHeight = Math.max(1, Math.min(height - 2, peak / scale * (height - 2)))
                paint.fillStyle = (column + 0.5) / columns <= played
                                  ? VLCStyle.redesign.accent : VLCStyle.redesign.textMuted
                paint.fillRect(column * slot, (height - barHeight) / 2,
                               Math.max(1, slot * 0.7), barHeight)
            }
            paint.fillStyle = VLCStyle.redesign.accent
            paint.fillRect(played * width - 1, 0, 2, height)
        }
    }
}
