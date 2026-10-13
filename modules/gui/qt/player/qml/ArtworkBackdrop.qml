/*****************************************************************************
 * Copyright (C) 2024 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
import QtQuick

import VLC.MainInterface
import VLC.Style
import VLC.Widgets as Widgets

Widgets.DualKawaseBlur {
    id: blurredBackground

    property Item coverItem
    readonly property real dar: parent && parent.height > 0 ? parent.width / parent.height : 1
    readonly property real sar: coverItem && coverItem.sar > 0 ? coverItem.sar : 1

    mode: Widgets.DualKawaseBlur.Mode.SixPass
    radius: 2
    live: true
    anchors.centerIn: parent
    width: (sar < dar) ? parent.width : parent.height * sar
    height: (sar < dar) ? parent.width / sar : parent.height
    source: coverItem ? coverItem.sourceTextureProviderItem : null
    postprocess: true
    tint: bgtheme.palette.isDark ? "black" : "white"
    tintStrength: 0.5
    backgroundColor: bgtheme.bg.primary
    viewportRect: Qt.rect((width - parent.width) / 2,
                          (height - parent.height) / 2, parent.width, parent.height)

    readonly property ColorContext colorContext: ColorContext {
        id: bgtheme
        colorSet: ColorContext.View
    }

    sourceTextureProviderObserver.onTextureChanged: liveTimer.transientTurnOnLive()

    Connections {
        target: blurredBackground.coverItem
        function onSourceChanged() { liveTimer.transientTurnOnLive() }
    }

    Component.onCompleted: {
        widthChanged.connect(liveTimer, liveTimer.transientTurnOnLive)
        heightChanged.connect(liveTimer, liveTimer.transientTurnOnLive)
        liveTimer.transientTurnOnLive()
    }

    Timer {
        id: liveTimer
        repeat: false
        interval: VLCStyle.duration_humanMoment

        function transientTurnOnLive() {
            if (!blurredBackground.sourceTextureIsValid)
                return
            blurredBackground.live = true
            liveTimer.restart()
        }
        onTriggered: blurredBackground.live = false
    }
}
