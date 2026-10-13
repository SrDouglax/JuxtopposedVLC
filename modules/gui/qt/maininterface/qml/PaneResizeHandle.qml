/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
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

import VLC.Style
import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Playlist
import VLC.Player

import VLC.Util
import VLC.Dialogs

Item {
    id: paneResizeHandle

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        palette: VLCStyle.palette
        colorSet: ColorContext.View
    }
    required property Item target
    required property QtObject panelObject
    property alias atRight: resizeHandle.atRight

    property alias visualBorder: visualBorder
    property alias resizeHandle: resizeHandle

    property alias minimumWidth: resizeHandle.minimumWidth
    property alias maximumWidth: resizeHandle.maximumWidth

    implicitWidth: resizeHandle.width

    Rectangle {
        id: visualBorder

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: resizeHandle.atRight ? undefined : parent.left
            right: resizeHandle.atRight ? parent.right: undefined
        }

        width: VLCStyle.border
        color: theme.separator
    }

    Widgets.HorizontalResizeHandle {
        id: resizeHandle

        property bool _inhibitMainInterfaceUpdate: false

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: resizeHandle.atRight ? undefined : parent.left
            right: resizeHandle.atRight ? parent.right: undefined
        }

        atRight: false
        currentWidth: target.width

        visible: !VLCStyle.isScreenSmall

        onRequestedWidthChanged: {
            if (!_inhibitMainInterfaceUpdate)
                paneResizeHandle.panelObject.width = requestedWidth
        }

        Component.onCompleted:  _updateFromMainInterface()

        function _updateFromMainInterface() {
            if (requestedWidth === paneResizeHandle.panelObject.width)
                return

            _inhibitMainInterfaceUpdate = true
            requestedWidth = paneResizeHandle.panelObject.width
            _inhibitMainInterfaceUpdate = false
        }

        Connections {
            target: paneResizeHandle.panelObject

            function onWidthChanged() {
                resizeHandle._updateFromMainInterface()
            }
        }
    }
}

