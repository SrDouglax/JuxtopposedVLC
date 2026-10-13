/*****************************************************************************
 * Copyright (C) 2021 VLC authors and VideoLAN
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
import QtQuick.Templates as T


import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Player
import VLC.Playlist
import VLC.Util

T.Control {
    id: root

    // Properties

    property bool paintOnly: false

    readonly property ColorContext colorContext: ColorContext {
        id: theme

        colorSet: ColorContext.ToolButton

        enabled: root.enabled || root.paintOnly
        focused: root.activeFocus
        hovered: root.cursorInside
        pressed: mouseArea.containsPress
    }

    property bool _keyOkPressed: false

    // Aliases

    property alias cursorInside: mouseArea.cursorInside

    // Settings

    implicitWidth: implicitBackgroundWidth + leftInset + rightInset
    implicitHeight: implicitBackgroundHeight + topInset + bottomInset

    scale: (_keyOkPressed || (mouseArea.pressed && cursorInside)) ? 0.95
                                                                  : 1.00

    Accessible.role: Accessible.Button
    Accessible.name: qsTr("Play/Pause")
    AccessibleCompat.id: "playButton"
    Accessible.checkable: true
    Accessible.checked: Player.playingState !== Player.PLAYING_STATE_PAUSED
                        && Player.playingState !== Player.PLAYING_STATE_STOPPED
    Accessible.onPressAction: MainPlaylistController.togglePlayPause()
    Accessible.onToggleAction: MainPlaylistController.togglePlayPause()

    // Tooltip

    T.ToolTip.visible: (hovered || visualFocus)
    T.ToolTip.delay: VLCStyle.delayToolTipAppear
    T.ToolTip.text: root.Accessible.name

    // Keys

    Keys.onPressed: (event) => {
        if (KeyHelper.matchOk(event) ) {
            if (!event.isAutoRepeat) {
                _keyOkPressed = true
                keyHoldTimer.restart()
                innerRectangle.state = "diminished"
            }
            event.accepted = true
        }
        Navigation.defaultKeyAction(event)
    }

    Keys.onReleased: (event) => {
        if (KeyHelper.matchOk(event)) {
            if (!event.isAutoRepeat) {
                _keyOkPressed = false
                keyHoldTimer.stop()
                innerRectangle.state = ""
                if (Player.playingState !== Player.PLAYING_STATE_STOPPED)
                    MainPlaylistController.togglePlayPause()
            }
            event.accepted = true
        }
    }

    // Functions

    function _pressAndHoldAction() {
        innerRectangle.state = ""
        _keyOkPressed = false
        MainPlaylistController.stop()
    }

    // Children

    Timer {
        id: keyHoldTimer

        interval: mouseArea.pressAndHoldInterval
        repeat: false

        Component.onCompleted: {
            triggered.connect(_pressAndHoldAction)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent

        hoverEnabled: true

        readonly property bool cursorInside: containsMouse

        onCursorInsideChanged: {
            if (pressed && !cursorInside) {
                // Press and hold action can no longer be done,
                // so reset the state in order to reset the
                // animation:
                innerRectangle.state = ""
            }
        }

        onPressed: (mouse) => {
            if (!cursorInside) {
                mouse.accepted = false
                return
            }

            root.forceActiveFocus(Qt.MouseFocusReason)
            innerRectangle.state = "diminished"
        }

        onReleased: {
            innerRectangle.state = ""
        }

        onClicked: (mouse) => {
            MainPlaylistController.togglePlayPause()
            mouse.accepted = true
        }

        onPressAndHold: (mouse) => {
            if (!cursorInside) {
                mouse.accepted = false
                return
            }

            _pressAndHoldAction()
            mouse.accepted = true
        }
    }

    contentItem: T.Label {
        text: {
            const state = Player.playingState

            if (!paintOnly
                    && state !== Player.PLAYING_STATE_PAUSED
                    && state !== Player.PLAYING_STATE_STOPPED)
                return VLCIcons.pause_filled
            else
                return ""
        }

        color: VLCStyle.redesign.color(VLCStyle.redesign.windowBackground, theme.fg.primary, theme.palette?.isDark ?? VLCStyle.darkPalette.isDark)

        font.pixelSize: VLCStyle.redesign.iconSize

        font.family: VLCIcons.fontFamily

        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

        Accessible.ignored: true

        Image {
            anchors.centerIn: parent
            source: "qrc:/redesign/play.svg"
            width: VLCStyle.redesign.iconSize
            height: VLCStyle.redesign.iconSize
            visible: root.paintOnly || Player.playingState === Player.PLAYING_STATE_PAUSED
                     || Player.playingState === Player.PLAYING_STATE_STOPPED
        }

        DelayedBehavior on color {
            delayedEnabled: theme.initialized

            ColorAnimation {
                duration: VLCStyle.duration_veryShort
                easing.type: Easing.InOutSine
            }
        }
    }

    background: Item {
        implicitWidth: VLCStyle.redesign.playWidth
        implicitHeight: VLCStyle.redesign.playHeight

        Widgets.AnimatedBackground {
            anchors.fill: parent
            radius: VLCStyle.redesign.controlRadius
            border.pixelAligned: false
            enabled: theme.initialized
            border.color: root.visualFocus ? theme.visualFocus : Qt.alpha(theme.visualFocus, 0.0)
        }

        Rectangle {
            id: innerRectangle
            anchors.fill: parent
            radius: VLCStyle.redesign.controlRadius
            color: VLCStyle.redesign.color(VLCStyle.redesign.accent, theme.accent, theme.palette?.isDark ?? VLCStyle.darkPalette.isDark)
            opacity: state === "diminished" ? 0.75 : 1
        }
    }
}
