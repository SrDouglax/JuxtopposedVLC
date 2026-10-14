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
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Dialogs
import VLC.Style
import VLC.Widgets as Widgets
import VLC.Player
import VLC.PlayerControls
import VLC.Util

MouseArea {
    id: centerContent

    required property Item musicView
    required property Item playerRoot
    required property Item topBarItem
    required property Item toggleControlBarItem
    required property Item controlBarItem
    property url coverSource
    property alias coverImage: cover
    property alias lyricsPanel: lyricsLoader

    readonly property ColorContext colorContext: ColorContext {
        id: centerTheme
        colorSet: ColorContext.View
    }

    onWheel: (wheel) => {
        wheel.accepted = true
        wheelToVlc.qmlWheelEvent(wheel)
    }

    TouchWheelHandler {
        wheelToVLCConverter: wheelToVlc
    }

    WheelToVLCConverter {
        id: wheelToVlc

        onVlcWheelKey: (key) => MainCtx.sendVLCHotkey(key)
    }

    // ── Two-panel lyrics layout ────────────────────────
    Item {
        id: leftSideParent

        visible: (opacity > 0.0) || (width > 0.0)

        opacity: (lyricsLoader.item ? 1.0 : 0.0)

        Behavior on opacity {
            id: opacityBehavior

            enabled: false

            NumberAnimation {
                duration: VLCStyle.duration_long

                easing.type: Easing.InOutSine
            }

            Component.onCompleted: {
                // The animation should not be used at initialization:
                Qt.callLater(() => { opacityBehavior.enabled = true })
            }
        }

        anchors.top: parent.top
        anchors.topMargin: VLCStyle.margin_large
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        width: lyricsLoader.item ? (parent.width * 0.6) : 0.0

        Behavior on width {
            id: widthBehavior

            enabled: false

            NumberAnimation {
                duration: VLCStyle.duration_long

                easing.type: Easing.InOutSine
            }

            Component.onCompleted: {
                // The animation should not be used at initialization:
                Qt.callLater(() => { widthBehavior.enabled = true })
            }
        }

        Loader {
            id: lyricsLoader

            active: musicView.lyricsLayoutActive
            sourceComponent: T.Pane {
                // Swallow wheel events so scrolling the lyrics
                // does not bubble up to the player and change
                // the volume.
                wheelEnabled: true

                // Expose the inner Flickable's sync flag so the
                // Loader's `item.lyricsSyncToPlayback` reaches
                // through to LyricsFlickable in both directions.
                property alias lyricsSyncToPlayback: lyricsFlickable.lyricsSyncToPlayback

                implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                        implicitContentWidth + leftPadding + rightPadding)
                implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                         implicitContentHeight + topPadding + bottomPadding)

                contentItem: LyricsFlickable {
                    id: lyricsFlickable

                    onPlayerPositionChangeRequested: (time) => {
                        Player.setTime(time)
                        lyricsFlickable.lyricsSyncToPlayback = true
                    }
                }
            }
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            height: Math.min(implicitHeight, parent.height)
        }
    }

    Item {
        id: rightSideParent

        visible: leftSideParent.visible

        anchors.top: parent.top
        anchors.topMargin: VLCStyle.margin_large
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.left: leftSideParent.right
    }

    ColumnLayout {
        parent: leftSideParent.visible ? rightSideParent : centerContent

        anchors.centerIn: parent
        spacing: 0

        Item {
            id: coverItem
            readonly property real side: Math.max(0, Math.min(
                VLCStyle.dp(738, VLCStyle.scale),
                centerContent.height - VLCStyle.dp(170, VLCStyle.scale),
                (musicView.lyricsLayoutActive ? rightSideParent.width : centerContent.width)
                    - VLCStyle.dp(48, VLCStyle.scale)))
            Layout.preferredWidth: side
            Layout.preferredHeight: side
            Layout.alignment: Qt.AlignHCenter

            Widgets.ImageExt {
                id: cover
                anchors.fill: parent
                radius: VLCStyle.dp(20, VLCStyle.scale)
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
                sourceSize: Qt.size(Math.ceil(coverItem.side * eDPR), Math.ceil(coverItem.side * eDPR))
                readonly property real eDPR: MainCtx.effectiveDevicePixelRatio(Window.window) || 1
                readonly property real sar: paintedHeight > 0 ? paintedWidth / paintedHeight : 1
                readonly property url targetSource: VLCAccessImage.uri(centerContent.coverSource)
                source: targetSource
                onTargetSourceChanged: source = targetSource

                onStatusChanged: {
                    if (status === Image.Error)
                        source = VLCStyle.noArtAlbumCover
                }

                Accessible.role: Accessible.Graphic
                Accessible.name: qsTr("Cover")

                Widgets.RoundedRectangleShadow {
                    color: Qt.rgba(0, 0, 0, .18)
                    yOffset: VLCStyle.dp(24, VLCStyle.scale)
                    blurRadius: VLCStyle.dp(54, VLCStyle.scale)
                }
                Widgets.RoundedRectangleShadow {
                    color: Qt.rgba(0, 0, 0, .22)
                    yOffset: VLCStyle.dp(5, VLCStyle.scale)
                    blurRadius: VLCStyle.dp(14, VLCStyle.scale)
                }
            }

            Canvas {
                anchors.fill: parent
                visible: cover.GraphicsInfo.shaderType !== GraphicsInfo.RhiShader
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.fillStyle = VLCStyle.redesign.windowBackground
                    const points = [[0, 0, 0], [width, 0, 90],
                                    [width, height, 180], [0, height, 270]]
                    for (const point of points) {
                        const r = Math.min(cover.radius, width / 2, height / 2)
                        ctx.save()
                        ctx.translate(point[0], point[1])
                        ctx.rotate(point[2] * Math.PI / 180)
                        ctx.beginPath()
                        ctx.moveTo(0, 0)
                        ctx.lineTo(r, 0)
                        ctx.arcTo(0, 0, 0, r, r)
                        ctx.closePath()
                        ctx.fill()
                        ctx.restore()
                    }
                }
            }
        }

        Widgets.SubtitleLabel {
            id: albumLabel

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: VLCStyle.margin_xxlarge

            Binding on visible {
                delayed: true
                when: albumLabel.componentCompleted
                value: albumLabel.text.length > 0 && centerContent.height > (albumLabel.y + albumLabel.height)
            }

            text: Player.title && Player.artist ? Player.title + " - " + Player.artist : ""
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(24, VLCStyle.scale)
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            color: VLCStyle.redesign.color(VLCStyle.redesign.textSecondary, "#4d4d4d")
            Accessible.description: qsTr("Title and artist")

            property bool componentCompleted: false

            Component.onCompleted: {
                componentCompleted = true
            }
        }

        Widgets.MenuLabel {
            id: artistLabel

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: VLCStyle.margin_small

            Binding on visible {
                delayed: true
                when: artistLabel.componentCompleted
                value: artistLabel.text.length > 0 && centerContent.height > (artistLabel.y + artistLabel.height)
            }

            text: Player.album
            font.weight: Font.Normal
            horizontalAlignment: Text.AlignHCenter
            color: centerTheme.fg.primary
            Accessible.description: qsTr("Album")

            property bool componentCompleted: false

            Component.onCompleted: {
                componentCompleted = true
            }
        }

        Widgets.SubtitleLabel {
            id: lyricsLabel

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: VLCStyle.margin_large
            // Pin width and height so the surrounding centered
            // column does not shift when the current lyric
            // changes between empty / 1 line / 2 lines. Text
            // exceeding two lines wraps then elides on line 2.
            Layout.preferredWidth: parent.parent.width - VLCStyle.margin_xlarge * 2
            Layout.preferredHeight: (lyricsLabelTextMetrics.height * 2) + VLCStyle.margin_xxxsmall

            visible: false

            Binding on visible {
                delayed: true
                when: lyricsLabel.componentCompleted

                // Stay visible (reserving the 2-line slot) for the
                // entire track when it has any lyrics, so the
                // layout does not collapse between lyric lines.
                value: Player.hasLyrics && !musicView.lyricsLayoutActive &&
                       (centerContent.height > (lyricsLabel.y + lyricsLabel.height))
            }

            property bool componentCompleted: false

            Component.onCompleted: {
                componentCompleted = true
            }

            elide: Text.ElideRight

            text: Player.currentLyric.text
            font.pixelSize: VLCStyle.fontSize_xlarge
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            color: centerTheme.fg.primary

            // TODO: Do not use `Binding` when minimum Qt is 6.12:
            Binding {
                target: lyricsLabel
                property: "mutabilityGroup"
                when: (lyricsLabel.mutabilityGroup !== undefined)
                value: (Player.playingState === Player.PLAYING_STATE_PLAYING) ? Item.ModerateMutabilityGroup
                                                                              : Item.StaticMutabilityGroup
            }

            TextMetrics {
                id: lyricsLabelTextMetrics
                font: lyricsLabel.font
                text: "TEXT"
            }

            Accessible.role: Accessible.StaticText
            Accessible.name: qsTr("Lyrics")
            Accessible.description: text
        }

        Widgets.NavigableRow {
            id: audioControls

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: VLCStyle.margin_large

            Binding on visible {
                delayed: true
                when: audioControls.componentCompleted
                value: Player.videoTracks.count === 0 && centerContent.height > (audioControls.y + audioControls.height)
            }

            focus: true
            spacing: VLCStyle.margin_xxsmall
            Navigation.parentItem: playerRoot
            Navigation.upItem: topBarItem
            Navigation.downItem: syncToPlaybackCheckBox

            property bool componentCompleted: false

            Component.onCompleted: {
                componentCompleted = true
            }

            Widgets.IconToolButton {
                text: VLCIcons.skip_back
                font.pixelSize: VLCStyle.icon_audioPlayerButton
                onClicked: Player.jumpBwd()
                description: qsTr("Step back")

                AccessibleCompat.id: "audioStepBackButton"
            }

            Widgets.IconToolButton {
                text: VLCIcons.visualization
                font.pixelSize: VLCStyle.icon_audioPlayerButton
                onClicked: DialogsProvider.audioVisualizationDialog()
                description: qsTr("Visualization")

                AccessibleCompat.id: "audioVisualizationButton"
            }

            Widgets.IconToolButton {
                text: VLCIcons.topbar_music
                font.pixelSize: VLCStyle.icon_audioPlayerButton
                checked: MainCtx.lyricsMode
                onClicked: MainCtx.lyricsMode = !MainCtx.lyricsMode
                description: qsTr("Lyrics")

                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Toggle lyrics view")
                AccessibleCompat.id: "audioLyricsButton"
            }

            Widgets.IconToolButton{
                text: VLCIcons.skip_for
                font.pixelSize: VLCStyle.icon_audioPlayerButton
                onClicked: Player.jumpFwd()
                description: qsTr("Step forward")

                AccessibleCompat.id: "audioStepForwardButton"
            }
        }

        // "Sync to Playback" checkbox pinned to bottom of right panel
        Widgets.CheckBoxExt {
            id: syncToPlaybackCheckBox

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: VLCStyle.margin_small

            visible: false

            Binding on visible {
                delayed: true
                when: syncToPlaybackCheckBox.componentCompleted
                value: musicView.lyricsLayoutActive &&
                       centerContent.height > (syncToPlaybackCheckBox.y + syncToPlaybackCheckBox.height)
            }

            property bool componentCompleted: false

            Component.onCompleted: {
                componentCompleted = true
            }

            text: qsTr("Sync lyrics to playback")
            // Use a Binding element rather than an inline binding
            // so manual clicks (which write `checked` directly)
            // don't permanently break the source-of-truth link.
            Binding on checked {
                when: lyricsLoader.item
                value: lyricsLoader.item ? lyricsLoader.item.lyricsSyncToPlayback : true
                restoreMode: Binding.RestoreBindingOrValue
            }
            onClicked: {
                if (lyricsLoader.item)
                    lyricsLoader.item.lyricsSyncToPlayback = checked
            }

            Accessible.role: Accessible.CheckBox
            Accessible.name: qsTr("Sync lyrics to playback position")
            AccessibleCompat.id: "syncToPlaybackCheckBox"

            Navigation.parentItem: playerRoot
            Navigation.upItem: audioControls
            Navigation.downItem: Player.isInteractive ? toggleControlBarItem : controlBarItem
        }
    }

    Widgets.SubtitleLabel {
        id: labelVolume

        anchors.right: parent.right
        anchors.top: parent.top

        anchors.rightMargin: VLCStyle.margin_normal
        anchors.topMargin: VLCStyle.margin_xxsmall

        visible: false

        text: qsTr("Volume %1%").arg(Math.round(Player.volume * 100))

        color: centerTheme.fg.primary

        font.weight: Font.Normal

        Connections {
            target: Player

            function onVolumeChanged() {
                animationVolume.restart()
            }
        }

        SequentialAnimation {
            id: animationVolume

            PropertyAction { target: labelVolume; property: "visible"; value: true }

            PauseAnimation { duration: VLCStyle.duration_humanMoment }

            PropertyAction { target: labelVolume; property: "visible"; value: false }
        }
    }

}
