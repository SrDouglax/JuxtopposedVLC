/*****************************************************************************
 * Copyright (C) 2020 VLC authors and VideoLAN
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
import QtQuick.Window

import VLC.MainInterface
import VLC.Player
import VLC.Style

Row {
    id: root
    spacing: 0
    padding: 0
    width: implicitWidth

    property color color: theme.fg.primary
    property color hoverColor: theme.bg.primary.alpha(0.5)

    readonly property bool buttonHovered: {
        for (let i = 0; i < repeater.count; ++i) {
            const group = repeater.itemAt(i)
            if (group.buttonHovered) return true
        }
        return false
    }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    Repeater {
        id: repeater
        model: MainCtx.csdButtonModel.windowCSDButtons

        Row {
            required property var modelData
            height: root.height
            readonly property bool buttonHovered: windowButton.hovered || windowButton.showHovered || fullscreenButton.hovered

            CSDWindowButton {
                id: windowButton
                height: root.height
                showHovered: modelData.showHovered
                externalPressed: modelData.externalPressed
                color: root.color
                hoverColor: modelData.type === CSDButton.Close ? "#c42b1c" : root.hoverColor
                isThemeDark: theme.palette.isDark
                iconSource: {
                    switch (modelData.type) {
                    case CSDButton.Minimize: return "qrc:///redesign/minimize.svg"
                    case CSDButton.MaximizeRestore: return "qrc:///redesign/maximize.svg"
                    case CSDButton.Close: return "qrc:///redesign/close.svg"
                    }
                    return ""
                }
                description: {
                    switch (modelData.type) {
                    case CSDButton.Minimize: return qsTr("Minimize")
                    case CSDButton.MaximizeRestore:
                        return MainCtx.intfMainWindow.visibility === Window.Maximized ? qsTr("Restore") : qsTr("Maximize")
                    case CSDButton.Close: return qsTr("Close")
                    }
                    return ""
                }
                onClicked: modelData.click()

                // Preserve the native Windows hit-test/snap rectangles.
                onWidthChanged: Qt.callLater(updateRect)
                onHeightChanged: Qt.callLater(updateRect)
                onXChanged: Qt.callLater(updateRect)
                Component.onCompleted: Qt.callLater(updateRect)
                Connections {
                    target: VLCStyle
                    function onAppWidthChanged() { Qt.callLater(windowButton.updateRect) }
                    function onAppHeightChanged() { Qt.callLater(windowButton.updateRect) }
                }
                function updateRect() {
                    const point = mapToItem(null, 0, 0)
                    modelData.rect = Qt.rect(point.x, point.y, width, height)
                }
            }

            CSDWindowButton {
                id: fullscreenButton
                height: root.height
                visible: modelData.type === CSDButton.MaximizeRestore
                color: root.color
                hoverColor: root.hoverColor
                isThemeDark: theme.palette.isDark
                iconSource: "qrc:///redesign/fullscreen.svg"
                description: qsTr("Fullscreen")
                onClicked: {
                    if (Player.hasVideoOutput)
                        Player.fullscreen = !Player.fullscreen
                    else
                        MainCtx.toggleInterfaceFullScreen()
                }
            }
        }
    }
}
