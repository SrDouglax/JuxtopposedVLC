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
import QtQuick.Controls.Basic as Controls
import QtQml.Models


import VLC.MainInterface
import VLC.Style
import VLC.Widgets as Widgets
import VLC.Util
import VLC.Player
import VLC.PlayerControls

Item {
    id: root

    // The editor remains the sole owner of its drag views. In the in-player
    // dialog, only their visual parent moves to the player's bottom strip.
    property Item previewHost: null
    property Item headerPreviewHost: null

    property bool dragActive: !!_viewThatContainsDrag || buttonDragItem.Drag.active

    property alias removeInfoRectVisible: buttonList.removeInfoRectVisible

    property EditorDNDView _viewThatContainsDrag: null

    signal dragStarted(int controlId)
    signal dragStopped(int controlId)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    ColumnLayout {
        id: editorColumn
        anchors.fill: parent
        spacing: 0

        Controls.TabBar {
            id: bar
            z: 1
            visible: !root.previewHost
            currentIndex: root.previewHost && !Player.hasVideoOutput ? 1 : 0

            background: Rectangle {
                color: VLCStyle.redesign.color("#0e0e0e", theme.bg.primary)
            }

            readonly property int currentIdentifier: root.previewHost
                ? (Player.hasVideoOutput ? PlayerControlbarModel.Videoplayer : PlayerControlbarModel.Audioplayer)
                : (currentItem ? currentItem.identifier : -1)

            Repeater {
                model: PlayerListModel.model

                delegate: EditorTabButton {
                    readonly property int identifier: modelData.identifier

                    selected: index === bar.currentIndex

                    implicitWidth: VLCStyle.button_width_large

                    text: {
                        const text = modelData.name

                        const profile = MainCtx.controlbarProfileModel.currentModel
                        if (profile && profile.getModel(identifier).dirty)
                            return text + " *"
                        else
                            return text
                    }

                    onDropEnterred: {
                        bar.currentIndex = index
                    }
                }
            }
        }

        Item {
            id: previewArea
            parent: root.previewHost ? root.previewHost : editorColumn
            anchors.fill: root.previewHost ? parent : undefined
            Layout.preferredHeight: root.previewHost ? -1 : VLCStyle.controlLayoutHeight * 1.5
            Layout.fillWidth: !root.previewHost

            TextMetrics {
                id: leftMetric
                text: qsTr("L   E   F   T")
                font.pixelSize: VLCStyle.fontSize_xxlarge
            }

            TextMetrics {
                id: centerMetric
                text: qsTr("C   E   N   T   E   R")
                font.pixelSize: VLCStyle.fontSize_xxlarge
            }

            TextMetrics {
                id: rightMetric
                text: qsTr("R   I   G   H   T")
                font.pixelSize: VLCStyle.fontSize_xxlarge
            }

            Repeater {
                model: PlayerListModel.model

                delegate: RowLayout {
                    id: layout
                    readonly property bool header: identifier === PlayerControlbarModel.VideoplayerHeader
                                                || identifier === PlayerControlbarModel.AudioplayerHeader
                    readonly property bool selected: bar.currentIdentifier === identifier
                        || (!!root.headerPreviewHost && identifier === (MainCtx.hasEmbededVideo
                            ? PlayerControlbarModel.VideoplayerHeader : PlayerControlbarModel.AudioplayerHeader))
                    parent: header && root.headerPreviewHost ? root.headerPreviewHost : previewArea

                    // can't use StackLayout or change visibility
                    // because there is a bug with the dragging
                    // that it doesn't work when the visibility
                    // is set to false, so instead use stacking
                    // and width/height to show the current view
                    clip: true
                    z: selected ? 0 : -1
                    width: selected ? parent.width : 0
                    height: selected ? parent.height : 0
                    visible: root.dragActive || selected

                    readonly property int identifier: modelData.identifier
                    readonly property PlayerControlbarModel model: {
                        if (!!MainCtx.controlbarProfileModel.currentModel)
                            return MainCtx.controlbarProfileModel.currentModel.getModel(identifier)
                        else
                            return null
                    }

                    spacing: VLCStyle.margin_small

                    Repeater {
                        id: repeater

                        model: 3 // left, center, and right

                        function getModel(index) {
                            if (!!layout.model) {
                                switch (index) {
                                case 0:
                                    return layout.model.left
                                case 1:
                                    return layout.model.center
                                case 2:
                                    return layout.model.right
                                default:
                                    return undefined
                                }
                            } else {
                                return undefined
                            }
                        }

                        function getMetric(index) {
                            switch (index) {
                            case 0:
                                return leftMetric
                            case 1:
                                return centerMetric
                            case 2:
                                return rightMetric
                            }
                        }

                        Loader {
                            id : playerBtnDND
                            active: !!repeater.getModel(index)

                            Layout.fillHeight: true
                            Layout.fillWidth: {
                                if (root.previewHost) return index === 1
                                if (count === 0) {
                                    for (let i = 0; i < repeater.count; ++i) {
                                        const item = repeater.itemAt(i)
                                        if (!!item && item.count > 0)
                                            return false
                                    }
                                }

                                return true
                            }

                            Layout.preferredWidth: root.previewHost && index !== 1 && item
                                ? Math.min(item.controlsWidth + VLCStyle.dp(16, VLCStyle.scale), layout.width * 0.45) : -1
                            Layout.minimumWidth: root.previewHost ? (index === 1 ? VLCStyle.dp(80, VLCStyle.scale) : 0)
                                : (!!item && item.visible && item.count <= 0) ? Math.max(leftMetric.width,
                                                                                                      centerMetric.width,
                                                                                                      rightMetric.width) * 1.25
                                                                                             : 0

                            readonly property int count: item ? item.count : 0

                            sourceComponent: Rectangle {
                                color: VLCStyle.redesign.color("#151515", theme.bg.primary)

                                border.color: VLCStyle.redesign.color("#373737", theme.border)
                                border.width: 0
                                border.pixelAligned: (radius < Number.EPSILON)

                                property alias count: dndView.count
                                readonly property real controlsWidth: dndView.controlsWidth

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: VLCStyle.dp(8, VLCStyle.scale)
                                    spacing: VLCStyle.dp(8, VLCStyle.scale)
                                    visible: !!root.previewHost && !layout.header && index === 1 && dndView.count === 0
                                    Text {
                                        text: VLCStyle.redesign.formatTime(Player.time)
                                        color: VLCStyle.redesign.textMuted
                                        font.family: VLCStyle.redesign.fontFamily
                                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                                    }
                                    SliderBar {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        redesign: true
                                        barHeight: VLCStyle.dp(32, VLCStyle.scale)
                                        value: Player.position
                                        enabled: false
                                    }
                                    Text {
                                        text: VLCStyle.redesign.formatTime(Player.length)
                                        color: VLCStyle.redesign.textMuted
                                        font.family: VLCStyle.redesign.fontFamily
                                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                                    }
                                }

                                Connections {
                                    target: root
                                    enabled: dndView.model === layout.model.center

                                    function onDragStarted(controlId) {
                                        // extending spacer widget should not be placed in the
                                        // central alignment view
                                        if (controlId === ControlListModel.WIDGET_SPACER_EXTEND)
                                            visible = false
                                    }

                                    function onDragStopped(controlId) {
                                        if (controlId === ControlListModel.WIDGET_SPACER_EXTEND)
                                            visible = true
                                    }
                                }

                                EditorDNDView {
                                    id: dndView
                                    anchors.fill: parent
                                    anchors.leftMargin: spacing
                                    anchors.rightMargin: spacing

                                    model: repeater.getModel(index)
                                    centered: !!root.previewHost && index === 1
                                    compactHeader: layout.header
                                    spacing: layout.header ? VLCStyle.dp(12, VLCStyle.scale) : VLCStyle.margin_xsmall

                                    // controls in the center view can not have
                                    // extra width
                                    extraWidthAvailable: model !== layout.model.center

                                    onContainsDragChanged: {
                                        if (containsDrag)
                                            _viewThatContainsDrag = this
                                        else if (_viewThatContainsDrag === this)
                                            _viewThatContainsDrag = null
                                    }

                                    Text {
                                        anchors.fill: parent

                                        text: root.previewHost ? "" : repeater.getMetric(index).text
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: VLCStyle.fontSize_xxlarge
                                        color: VLCStyle.redesign.color("#969696", theme.fg.secondary)
                                        horizontalAlignment: Text.AlignHCenter
                                        visible: (count === 0)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.topMargin: root.previewHost ? VLCStyle.dp(20, VLCStyle.scale) : VLCStyle.margin_xxsmall

            color: VLCStyle.redesign.color("#0e0e0e", buttonList.colorContext.bg.primary)
            border.color: VLCStyle.redesign.color("#222222", theme.border)
            border.width: 0
            border.pixelAligned: (radius < Number.EPSILON)

            ColumnLayout {
                anchors.fill: parent

                Widgets.MenuCaption {
                    Layout.margins: VLCStyle.margin_xxsmall
                    visible: false
                    text: ""
                    color: VLCStyle.redesign.color("#969696", buttonList.colorContext.fg.primary)
                }

                ToolbarEditorButtonList {
                    id: buttonList

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: root.previewHost ? 0 : VLCStyle.margin_xxsmall

                    Component.onCompleted: {
                        controlDragStarted.connect(root.dragStarted)
                        controlDragStopped.connect(root.dragStopped)
                    }
                }
            }
        }
    }

    EditorDummyButton {
        id: buttonDragItem
        property url iconSource: ""
        Drag.hotSpot: Qt.point(-VLCStyle.dragDelta, -VLCStyle.dragDelta)

        visible: Drag.active
        color: iconSource.toString().length ? "transparent" : theme.fg.primary
        opacity: 0.75
        Image {
            anchors.centerIn: parent
            width: VLCStyle.dp(24, VLCStyle.scale)
            height: width
            source: buttonDragItem.iconSource
            visible: source.toString().length > 0
        }

        x: -1
        y: -1

        Drag.onActiveChanged: {
            dragAutoScrollHandler.dragItem = Drag.active ? this : null
        }
    }

    ViewDragAutoScrollHandler {
        id: dragAutoScrollHandler

        view: _viewThatContainsDrag ? _viewThatContainsDrag : null
    }
}
