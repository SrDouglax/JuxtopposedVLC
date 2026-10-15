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
import QtQuick.Templates as T
import QtQuick.Layouts
import QtQuick.Window


import VLC.MainInterface
import VLC.Style
import VLC.PlayerControls
import VLC.Playlist
import VLC.Widgets as Widgets
import VLC.Menus as Menus
import VLC.Util
import VLC.Player

FocusScope{
    id: root

    // Properties

    required property int textWidth

    // For now, used for d&d functionality
    // Not strictly necessary to set
    property Item plListView

    property int reservedHeight: 0

    property int topMargin: 0
    property int sideMargin: 0

    property string title

    property bool showCSD: false
    property bool showToolbar: false
    property bool pinControls: false

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        palette: VLCStyle.palette
        colorSet: ColorContext.Window
    }

    // Private

    property bool _showTopBar: (pinControls === false || showToolbar === false)

    property bool _showCenterText: showToolbar === false

    readonly property int _sideMargin: VLCStyle.margin_small + sideMargin

    // Aliases

    property alias resumeVisible: resumeDialog.visible
    readonly property bool showResume: resumeVisible && !PlayerControlbarControls.editing

    property bool playlistVisible: false

    // Signals

    signal togglePlaylistVisibility()
    signal requestLockUnlockAutoHide(bool lock)
    signal backRequested()
    signal menuOpened(var menu)

    ///incomming signal to request all menu and popup to close
    signal forceUnlock()

    // Settings

    Accessible.role: Accessible.ToolBar
    Accessible.name: qsTr("Player topbar")
    AccessibleCompat.id: "playerTopBar"

    // Events

    Component.onCompleted: _layout()

    onShowCSDChanged: _layout()
    onPinControlsChanged: _layout()
    onShowToolbarChanged: _layout()
    onTopMarginChanged: _layout()
    onSideMarginChanged: _layout()

    on_ShowCenterTextChanged: _layout()

    // Functions

    // FIXME: Imperative layouting in QML is stupid, this needs to be gone.
    function _layoutLine(c1, c2, offset)
    {
        let c1Height = c1?.implicitHeight ?? 0
        let c2Height = c2?.implicitHeight ?? 0

        if (c2 === csdDecorations) {
            //csdDecorations.implicitHeight gets overwritten when the height is set,
            //VLCStyle.redesign.topbarHeight is its initial value
            c2Height = VLCStyle.redesign.topbarHeight
        }

        const lineHeight = Math.max(c1Height, c2Height)

        if (c1) {
            c1.height = lineHeight
            c1.anchors.topMargin = offset
        }

        if (c2) {
            c2.height = lineHeight
            c2.anchors.topMargin = offset
        }
        return lineHeight
    }

    // FIXME: Imperative layouting in QML is stupid, this needs to be gone.
    //FIXME: if CSD will be weirdly placed if application safe-area are used,
    //nota that if you need a safe area (kiosk mode), you probably don't need CSD
    function _layout() {
        let offset = topMargin

        if (_showCenterText) {
            //place everything on one line
            //csdDecorations.implicitHeight gets overwritten when the height is set,
            //VLCStyle.redesign.topbarHeight is its initial value
            const lineHeight = Math.max(VLCStyle.redesign.topbarHeight, logoOrResume.implicitHeight)

            headerControls.y = topMargin
            headerControls.height = lineHeight

            csdDecorations.height  = lineHeight
            csdDecorations.anchors.topMargin = topMargin

            logoOrResume.height = lineHeight
            logoOrResume.anchors.topMargin = topMargin


            implicitHeight = lineHeight
            offset += lineHeight

        } else {
            let left = undefined
            let right = undefined
            let logoPlaced = false

            if (showToolbar) {
                left = menubar
            }

            if (showCSD) {
                right = csdDecorations
                if (!left) {
                    left = logoOrResume
                    logoPlaced = true
                }
            }

            if (!!left || !!right) {
                offset += _layoutLine(left, right, offset)

                if (showCSD) {
                    tapNDrag.height = offset
                }
            }

            if (!logoPlaced) {
                left = logoOrResume
            } else {
                left = undefined
            }

            right = undefined

            offset += _layoutLine(left, right, offset)
        }

        implicitHeight = offset
        reservedHeight = offset
    }

    // Children

    Rectangle {
        anchors.fill: parent
        z: -0.5
        color: VLCStyle.redesign.color(VLCStyle.redesign.playerTopbarBackground, "#ababaa", VLCStyle.palette.isDark)
    }

    //drag and dbl click the titlebar in CSD mode
    Loader {
        id: tapNDrag

        anchors.fill: parent
        active: root.showCSD
        source: "qrc:///qt/qml/VLC/Widgets/CSDTitlebarTapNDrapHandler.qml"

        Connections {
            target: tapNDrag.item
            enabled: tapNDrag.status === Loader.Ready
            function onCsdMenuVisibleChanged() {
                root.requestLockUnlockAutoHide(tapNDrag.item.csdMenuVisible)
            }
        }
    }

    // Components -
    Menus.Menubar {
        id: menubar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: root.sideMargin
        anchors.right: root.showCSD ? csdDecorations.left : parent.right


        visible: root.showToolbar
        enabled: root.showToolbar

        onHoveredChanged: menu => root.requestLockUnlockAutoHide(hovered)
        onMenuOpenedChanged: menu => root.requestLockUnlockAutoHide(menuOpened)
        onImplicitHeightChanged: root._layout()
    }

    Item {
        id: logoOrResume

        anchors.left: root.left
        anchors.top: root.top
        anchors.leftMargin:  root._sideMargin

        implicitWidth: root.showResume ? resumeDialog.implicitWidth
                                     : logoGroup.implicitWidth

        implicitHeight: {
            if (root.showResume) {
                // Only if there are multiple lines use `resumeDialog`'s implicit height, otherwise the video
                // window may get resized by few pixels unnecessarily when `resumeDialog` is no longer visible.
                if (resumeDialog.implicitHeight >= (logoGroup.implicitHeight + resumeDialog.baselineOffset))
                    return resumeDialog.implicitHeight
                else
                    return logoGroup.implicitHeight
            } else if (_showTopBar)
                return logoGroup.implicitHeight
            else
                return 0
        }

        onImplicitHeightChanged: root._layout()

        Item {
            id: logoGroup

            anchors.fill: parent

            visible: (root._showTopBar && !root.showResume)

            implicitHeight: VLCStyle.redesign.topbarHeight
            implicitWidth: logo.implicitWidth

            Widgets.BannerCone {
                id: logo
                source: "qrc:///redesign/logo.svg"

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left

                color: VLCStyle.redesign.logoColor
            }

        }

        ResumeDialog {
            id: resumeDialog
            opacity: PlayerControlbarControls.editing ? 0 : 1
            enabled: !PlayerControlbarControls.editing

            anchors.fill: parent
            //add aditional margin so it align with menubar text when visible (see MenuBar.qml)
            anchors.leftMargin: VLCStyle.margin_xsmall

            maxWidth: (root.showCSD ? csdDecorations.x : root.width)
                - VLCStyle.applicationHorizontalMargin
                - VLCStyle.margin_large

            colorContext.palette: theme.palette

            Navigation.parentItem: rootPlayer

            onHidden: {
                if (activeFocus) {
                    headerControls.forceActiveFocus()
                }
            }

            onVisibleChanged: {
                root.requestLockUnlockAutoHide(visible)
            }
        }
    }

    Loader {
        id: headerControls
        objectName: "playerHeaderControls"
        anchors.left: logoOrResume.right
        anchors.leftMargin: VLCStyle.dp(16, VLCStyle.scale)
        anchors.right: root.showCSD ? csdDecorations.left : parent.right
        anchors.rightMargin: root._sideMargin
        visible: root._showTopBar && !root.showResume
        // The editor supplies its own editable header preview.
        active: !PlayerControlbarControls.editing
        sourceComponent: FocusScope {
            id: headerLayout
            readonly property PlayerControlbarModel model: MainCtx.controlbarProfileModel.currentModel
                ?.getModel(MainCtx.hasEmbededVideo ? PlayerControlbarModel.VideoplayerHeader
                                                  : PlayerControlbarModel.AudioplayerHeader) ?? null
            Navigation.parentItem: root
            Navigation.downItem: root.Navigation.downItem
            // Header controls are a simple row, without the footer's flexible
            // timeline layout. Keep each section's host stable across profiles.
            Repeater {
                model: 3
                Row {
                    id: section
                    required property int index
                    spacing: VLCStyle.dp(12, VLCStyle.scale)
                    readonly property real available: index === 1
                        ? Math.max(0, headerLayout.width - 2 * Math.max(leftWidth, rightWidth) - VLCStyle.dp(32, VLCStyle.scale))
                        : headerLayout.width * 0.4
                    readonly property real leftWidth: headerSections.itemAt(0)?.width ?? 0
                    readonly property real rightWidth: headerSections.itemAt(2)?.width ?? 0
                    width: Math.min(implicitWidth, available)
                    height: headerLayout.height
                    x: index === 0 ? 0 : index === 2 ? headerLayout.width - width
                       : root.width / 2 - headerControls.x - width / 2
                    clip: true
                    ControlRepeater {
                        id: headerRepeater
                        compactHeader: true
                        availableWidth: section.available
                        availableHeight: section.height
                        Navigation.parentItem: headerLayout
                        model: ControlListFilter {
                            sourceModel: section.index === 0 ? (headerLayout.model?.left ?? null)
                                       : section.index === 1 ? (headerLayout.model?.center ?? null)
                                                             : (headerLayout.model?.right ?? null)
                            player: Player
                            ctx: MainCtx
                        }
                        onRequestLockUnlockAutoHide: lock => root.requestLockUnlockAutoHide(lock)
                        onMenuOpened: menu => root.menuOpened(menu)
                        Component.onCompleted: root.forceUnlock.connect(headerRepeater.forceUnlock)
                    }
                }
                id: headerSections
            }
        }
    }

    Loader {
        id: csdDecorations

        anchors.top: parent.top
        anchors.right: parent.right

        focus: false
        height: VLCStyle.redesign.topbarHeight
        active: root.showCSD
        enabled: root.showCSD
        visible: root.showCSD
        source: "qrc:///qt/qml/VLC/Widgets/CSDWindowButtonSet.qml"

        Connections {
            target: csdDecorations.item
            enabled: csdDecorations.status === Loader.Ready
            function onButtonHoveredChanged() { root.requestLockUnlockAutoHide(csdDecorations.item.buttonHovered) }
        }
    }

}
