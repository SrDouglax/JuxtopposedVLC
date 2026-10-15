
/*****************************************************************************
 * Copyright (C) 2022 VLC authors and VideoLAN
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
import QtQml
import QtQuick
import QtQuick.Controls.Basic as C
import VLC.Style

import VLC.MainInterface
import VLC.Menus

// @brief - a class that can be used to create native menus with support
// to asyncronously retreive data from MLBaseModel like model

QtObject {
    id: root

    /**
      actions - list of action to show

      each action is an Object and contains following keys
        "text" - (string) display text of the action

        "action" - (function(dataList, options, indexes)) a function that will be called when action is selected

        "visible" - (Boolean or function(dataList,options, indexes) -> Boolean) (optional) a boolean value or function which
                    controls whether the action is shown in the menu following 'popup' call

       e.g see MLContextMenu.qml
    **/

    property var actions: []
    property Item popupParent: typeof g_mainDisplay === "undefined" ? null : g_mainDisplay

    property alias visible: menu.visible

    readonly property int currentRequest: _currentRequest

    signal requestData(var requestID, var indexes)


    property var _options: null

    property var _indexes: []

    property var _dataList: null

    property int _currentRequest: 0

    property var _effectiveActions: []

    property point _popupPoint

    // requests data for '_indexes' and shows popup menu
    // with 'NativeMenu::actions' based on '_options'
    // returns unique request id
    function popup(_indexes, point, _options) {
        root._options = _options
        root._indexes = _indexes
        _dataList = null
        _popupPoint = point

        const requestID = ++_currentRequest
        requestData(requestID, _indexes)
        return requestID
    }

    function setData(id, data) {
        if (_currentRequest !== id)
            return;

        _dataList = data

        const effectiveActions = []
        for (let i in actions) {
            const action = actions[i]

            if (!action.hasOwnProperty("visible")
                    || (typeof action.visible === "boolean" && action.visible)
                    || (typeof action.visible === "function" && action.visible(_dataList, _options, _indexes))) {
                effectiveActions.push(action)
            }
        }

        _effectiveActions = effectiveActions
        if (!popupParent) return
        const pos = popupParent.mapFromGlobal(_popupPoint.x, _popupPoint.y)
        menu.x = Math.max(0, Math.min(pos.x, popupParent.width - menu.width))
        menu.y = Math.max(0, Math.min(pos.y, popupParent.height - menu.height))
        if (_effectiveActions.length) menu.open()
    }

    function _executeAction(index) {
        const action = root._effectiveActions[index]
        action.action(_dataList, _options, _indexes)
    }


    readonly property C.Menu _menu: C.Menu {
        id: menu
        objectName: "libraryContextMenu"
        parent: root.popupParent
        width: VLCStyle.dp(264, VLCStyle.scale)
        height: Math.min(root._effectiveActions.length * VLCStyle.dp(48, VLCStyle.scale) + padding * 2,
                         Math.max(0, (root.popupParent?.height ?? 0) - VLCStyle.dp(16, VLCStyle.scale)))
        padding: VLCStyle.dp(8, VLCStyle.scale)
        modal: false
        focus: true
        background: Rectangle {
            color: VLCStyle.redesign.color("#191919", "#eeeeee")
            radius: VLCStyle.dp(8, VLCStyle.scale)
        }
        Instantiator {
            model: root._effectiveActions || []
            delegate: C.MenuItem {
                required property var modelData
                required property int index
                implicitHeight: VLCStyle.dp(48, VLCStyle.scale)
                width: menu.availableWidth
                text: modelData.text
                onTriggered: root._executeAction(index)
                background: Rectangle {
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    color: parent.highlighted ? VLCStyle.redesign.color("#252525", "#d6d6d6") : "transparent"
                }
                contentItem: Item {
                    Image {
                        anchors.left: parent.left
                        anchors.leftMargin: VLCStyle.dp(12, VLCStyle.scale)
                        anchors.verticalCenter: parent.verticalCenter
                        width: VLCStyle.dp(24, VLCStyle.scale)
                        height: width
                        sourceSize: Qt.size(width, height)
                        source: modelData.icon ? "qrc:///redesign/icons/" + modelData.icon + "/default.png" : ""
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: VLCStyle.dp(modelData.icon ? 44 : 12, VLCStyle.scale)
                        anchors.right: parent.right
                        anchors.rightMargin: VLCStyle.dp(12, VLCStyle.scale)
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.text
                        elide: Text.ElideRight
                        color: VLCStyle.redesign.color("#8f8f8f", "#494949")
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    }
                }
            }
            onObjectAdded: (index, object) => menu.insertItem(index, object)
            onObjectRemoved: (index, object) => menu.removeItem(object)
        }
    }
}
