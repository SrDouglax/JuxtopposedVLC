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
        colorSet: ColorContext.Window
    }

    // Private

    property bool _showTopBar: (pinControls === false || showToolbar === false)

    property bool _showCenterText: showToolbar === false

    readonly property int _sideMargin: VLCStyle.margin_small + sideMargin

    // Aliases

    property alias resumeVisible: resumeDialog.visible

    property alias playlistVisible: playlistButton.checked

    // Signals

    signal togglePlaylistVisibility()
    signal requestLockUnlockAutoHide(bool lock)
    signal backRequested()

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

    on_ShowTopBarChanged: _layout()
    on_ShowCenterTextChanged: _layout()

    // Functions

    // FIXME: Imperative layouting in QML is stupid, this needs to be gone.
    function _layoutLine(c1, c2, offset)
    {
        let c1Height = c1?.implicitHeight ?? 0
        let c2Height = c2?.implicitHeight ?? 0

        if (c2 === csdDecorations) {
            //csdDecorations.implicitHeight gets overwritten when the height is set,
            //VLCStyle.icon_normal is its initial value
            c2Height = VLCStyle.icon_normal
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
            //VLCStyle.icon_normal is its initial value
            const lineHeight = Math.max(VLCStyle.redesign.topbarHeight, logoOrResume.implicitHeight, playlistGroup.implicitHeight)

            centerTitleText.y = topMargin
            centerTitleText.height = lineHeight

            csdDecorations.height  = lineHeight
            csdDecorations.anchors.topMargin = topMargin

            logoOrResume.height = lineHeight
            logoOrResume.anchors.topMargin = topMargin

            playlistGroup.height = lineHeight
            playlistGroup.anchors.topMargin = topMargin
            playlistGroup.extraRightMargin = Qt.binding(function() { return width - csdDecorations.x })


            implicitHeight = lineHeight
            offset += lineHeight

        } else {
            playlistGroup.extraRightMargin = 0

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

            if (_showTopBar)
                right = playlistGroup
            else
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
        color: VLCStyle.redesign.color(VLCStyle.redesign.playerTopbarBackground, theme.bg.primary, (theme.palette?.isDark ?? VLCStyle.darkPalette.isDark))
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

        implicitWidth: resumeVisible ? resumeDialog.implicitWidth
                                     : logoGroup.implicitWidth

        implicitHeight: {
            if (root.resumeVisible) {
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

            visible: (root._showTopBar && root.resumeVisible === false)

            implicitHeight: VLCStyle.redesign.topbarHeight
            implicitWidth: backBtn.implicitWidth + logo.implicitWidth + VLCStyle.margin_xxsmall

            Widgets.IconToolButton {
                id: backBtn
                color: VLCStyle.redesign.color(enabled ? VLCStyle.redesign.textMuted : VLCStyle.redesign.textDisabled,
                                               colorContext.fg.primary, (colorContext.palette?.isDark ?? VLCStyle.darkPalette.isDark))
                backgroundColor: VLCStyle.redesign.color(hovered || down ? VLCStyle.redesign.controlHoverBackground : "transparent",
                                                         colorContext.bg.primary, (colorContext.palette?.isDark ?? VLCStyle.darkPalette.isDark))
                radius: VLCStyle.redesign.controlRadius

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left

                objectName: "IconToolButton"
                font.pixelSize: VLCStyle.redesign.iconSize
                text: VLCIcons.back
                description: qsTr("Back")

                AccessibleCompat.id: "topBarBackButton"

                focus: true

                Navigation.parentItem: root
                Navigation.rightItem: menuSelector
                onClicked: root.backRequested()

                onHoveredChanged: root.requestLockUnlockAutoHide(hovered)
            }

            Widgets.BannerCone {
                id: logo
                source: "qrc:///redesign/logo.svg"

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: backBtn.right
                anchors.leftMargin: VLCStyle.margin_xxsmall

                color: VLCStyle.redesign.logoColor
            }
        }

        ResumeDialog {
            id: resumeDialog

            anchors.fill: parent
            //add aditional margin so it align with menubar text when visible (see MenuBar.qml)
            anchors.leftMargin: VLCStyle.margin_xsmall

            maxWidth: ((root.showCSD && !root.pinControls) ? csdDecorations : playlistGroup).x
                - VLCStyle.applicationHorizontalMargin
                - VLCStyle.margin_large

            colorContext.palette: theme.palette

            Navigation.parentItem: rootPlayer

            onHidden: {
                if (activeFocus) {
                    backBtn.forceActiveFocus()
                }
            }

            onVisibleChanged: {
                root.requestLockUnlockAutoHide(visible)
            }
        }
    }

    Title {
        id: centerTitleText
        centerWithinBounds: true
        leftLimit: logoOrResume.x + logoOrResume.width
        rightLimit: playlistGroup.x
        visible: root._showCenterText && !root.resumeVisible
        enabled: visible
        text: qsTr("VLC Media Player")
        Accessible.name: root.title || text
        colorContext.palette: theme.palette
    }

    Title {
        id: leftTitleText
        anchors.left: parent.left
        anchors.top: logoOrResume.bottom
        anchors.leftMargin: root._sideMargin
        width: root.textWidth - VLCStyle.margin_normal
        visible: !root.pinControls && !root._showCenterText
        enabled: visible
        topPadding: VLCStyle.margin_large
        leftPadding: logo.x
        text: root.title
        colorContext.palette: theme.palette
    }

    Loader {
        id: csdDecorations

        anchors.top: parent.top
        anchors.right: parent.right

        focus: false
        height: VLCStyle.icon_normal
        active: root.showCSD
        enabled: root.showCSD
        visible: root.showCSD
        source:  VLCStyle.palette.hasCSDImage
            ? "qrc:///qt/qml/VLC/Widgets/CSDThemeButtonSet.qml"
            : "qrc:///qt/qml/VLC/Widgets/CSDWindowButtonSet.qml"

        Connections {
            target: csdDecorations.item
            enabled: csdDecorations.status === Loader.Ready
            function onButtonHoveredChanged() { root.requestLockUnlockAutoHide(csdDecorations.item.buttonHovered) }
        }
    }

    Row {
        id: playlistGroup

        property int extraRightMargin: 0

        focus: true
        spacing: VLCStyle.margin_xxsmall

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: root._sideMargin + extraRightMargin

        visible: root._showTopBar

        Widgets.IconToolButton {
            id: menuSelector
            color: VLCStyle.redesign.color(enabled ? VLCStyle.redesign.textMuted : VLCStyle.redesign.textDisabled,
                                           colorContext.fg.primary, (colorContext.palette?.isDark ?? VLCStyle.darkPalette.isDark))
            backgroundColor: VLCStyle.redesign.color(hovered || down ? VLCStyle.redesign.controlHoverBackground : "transparent",
                                                     colorContext.bg.primary, (colorContext.palette?.isDark ?? VLCStyle.darkPalette.isDark))
            radius: VLCStyle.redesign.controlRadius
            contentItem: Image {
                source: "qrc:///redesign/menu.svg"
                sourceSize: Qt.size(VLCStyle.redesign.iconSize, VLCStyle.redesign.iconSize)
                fillMode: Image.PreserveAspectFit
            }

            anchors.verticalCenter: parent.verticalCenter
            visible: !root.showToolbar
            enabled: visible
            focus: visible
            font.pixelSize: VLCStyle.redesign.iconSize

            width: VLCStyle.bannerButton_width
            height: VLCStyle.bannerButton_height

            text: VLCIcons.more
            description: qsTr("Menu")

            AccessibleCompat.id: "topBarMenuButton"

            checked: contextMenu.shown

            Navigation.parentItem: root
            Navigation.leftItem: backBtn
            Navigation.rightItem: playlistButton

            onClicked: contextMenu.popup(this.mapToGlobal(0, height))

            onHoveredChanged: root.requestLockUnlockAutoHide(hovered)

            Menus.QmlGlobalMenu {
                id: contextMenu

                ctx: MainCtx

                onAboutToShow: root.requestLockUnlockAutoHide(true)
                onAboutToHide: root.requestLockUnlockAutoHide(false)
            }

            Connections {
                target: root

                function onForceUnlock() {
                    contextMenu.close()
                }
            }
        }

        PlaylistPane.PlaylistToggleButton {
            id: playlistButton
            color: VLCStyle.redesign.color(enabled ? VLCStyle.redesign.textMuted : VLCStyle.redesign.textDisabled,
                                           colorContext.fg.primary, (colorContext.palette?.isDark ?? VLCStyle.darkPalette.isDark))
            backgroundColor: VLCStyle.redesign.color(hovered || down ? VLCStyle.redesign.controlHoverBackground : "transparent",
                                                     colorContext.bg.primary, (colorContext.palette?.isDark ?? VLCStyle.darkPalette.isDark))
            radius: VLCStyle.redesign.controlRadius

            anchors.verticalCenter: parent.verticalCenter
            objectName: ControlListModel.PLAYLIST_BUTTON
            font.pixelSize: VLCStyle.redesign.iconSize
            text: VLCIcons.playlist
            description: qsTr("Play Queue")

            AccessibleCompat.id: "topBarPlayqueueButton"

            focus: root.showToolbar

            width: VLCStyle.bannerButton_width
            height: VLCStyle.bannerButton_height

            plListView: root.plListView
            
            Navigation.parentItem: root
            Navigation.leftItem: menuSelector.visible ? menuSelector : backBtn

            onClicked: togglePlaylistVisibility()

            Accessible.onToggleAction:togglePlaylistVisibility()

            onHoveredChanged: root.requestLockUnlockAutoHide(hovered)
        }
    }
}
