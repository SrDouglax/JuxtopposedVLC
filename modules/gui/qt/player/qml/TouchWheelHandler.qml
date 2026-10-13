/*****************************************************************************
 * Copyright (C) 2024 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *****************************************************************************/
import QtQuick

import VLC.MainInterface
import VLC.Util
import VLC.Style
import VLC.Player

DragHandler {
    id: touchDragHandler

    acceptedDevices: PointerDevice.TouchScreen
    minimumPointCount: 1
    maximumPointCount: 1
    target: null
    dragThreshold: VLCStyle.margin_normal

    property vector2d lastActiveTranslation
    readonly property Component wheelToVLCConverterComponent: Component { WheelToVLCConverter { } }
    property WheelToVLCConverter wheelToVLCConverter

    onActiveTranslationChanged: {
        if (!active)
            return

        console.assert(wheelToVLCConverter)
        const delta = Qt.point(activeTranslation.x - lastActiveTranslation.x,
                               activeTranslation.y - lastActiveTranslation.y)
        wheelToVLCConverter.customWheelEvent(delta, delta, Qt.NoButton, Qt.NoModifier, true)
        lastActiveTranslation = activeTranslation
    }

    onActiveChanged: {
        if (active) {
            if (!wheelToVLCConverter) {
                wheelToVLCConverter = wheelToVLCConverterComponent.createObject(touchDragHandler)
                wheelToVLCConverter.vlcWheelKey.connect(MainCtx, MainCtx.sendVLCHotkey)
            }
        } else {
            lastActiveTranslation = Qt.vector2d(0, 0)
        }
    }
}
