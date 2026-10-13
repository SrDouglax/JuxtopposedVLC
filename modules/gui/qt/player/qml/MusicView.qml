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
import VLC.Player

FocusScope {
    id: audioFocusScope
    focus: true

    required property Item playerRoot
    required property Item topBarItem
    required property Item toggleControlBarItem
    required property Item controlBarItem
    property real topPadding
    property real bottomPadding
    property url coverSource

    readonly property bool lyricsMode: MainCtx.lyricsMode
    readonly property bool lyricsLayoutActive: lyricsMode && Player.hasLyrics
                                                    && centerContent.width > VLCStyle.colWidth(6)

    onLyricsModeChanged: {
        if (lyricsMode && centerContent.lyricsPanel.item)
            centerContent.lyricsPanel.item.lyricsSyncToPlayback = true
    }

    ArtworkBackdrop {
        id: blurredBackground
        coverItem: centerContent.coverImage
    }

    AudioContent {
        id: centerContent
        anchors.fill: parent
        anchors.topMargin: VLCStyle.margin_xsmall + audioFocusScope.topPadding
        anchors.bottomMargin: VLCStyle.margin_xsmall + audioFocusScope.bottomPadding
        musicView: audioFocusScope
        playerRoot: audioFocusScope.playerRoot
        topBarItem: audioFocusScope.topBarItem
        toggleControlBarItem: audioFocusScope.toggleControlBarItem
        controlBarItem: audioFocusScope.controlBarItem
        coverSource: audioFocusScope.coverSource
    }
}
