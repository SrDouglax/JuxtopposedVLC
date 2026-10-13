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
import QtQml.Models
import QtQuick.Window


import VLC.MainInterface
import VLC.Style
import VLC.Playlist
import VLC.Player
import VLC.Widgets as Widgets
import VLC.Menus as Menus
import VLC.Util

T.ToolBar {
    id: root

    Accessible.name: qsTr("Local top bar")
    AccessibleCompat.id: "localTopbar"

    property bool useAcrylic: true

    // For now, used for d&d functionality
    // Not strictly necessary to set
    property Item plListView

    property bool _showCSD: MainCtx.clientSideDecoration
        && !(MainCtx.intfMainWindow.visibility === Window.FullScreen)
        && !MainCtx.hasToolbarMenu

    //whether the navigation pannel is actually visible or not
    property alias navigationVisible: navigationVisibilty.checked
    property bool playqueueVisible: false

    property alias navigationButton: navigationVisibilty

    signal toggleNavigationVisibility()
    signal togglePlayqueueVisibility()

    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                             implicitContentWidth + leftPadding + rightPadding + (_showCSD ? csdButtons.implicitWidth : 0))

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    background:  Widgets.AcrylicBackground {
        enabled: root.useAcrylic
        tintColor: VLCStyle.redesign.color(VLCStyle.redesign.controlBackground, theme.bg.primary)
        alternativeColor: tintColor
    }

    contentItem: Item {

        implicitHeight: VLCStyle.redesign.topbarHeight
        implicitWidth: navigationButtons.implicitWidth
                     + VLCStyle.margin_xsmall * 2

        Item {
            id: navigationButtons

            implicitWidth: navigationButtonsRow.implicitWidth

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: VLCStyle.margin_xsmall
            }

            Navigation.parentItem: root

            Row {
                id: navigationButtonsRow

                anchors.verticalCenter: parent.verticalCenter
                spacing: VLCStyle.dp(7, VLCStyle.scale)

                Navigation.parentItem: root

                Widgets.IconToolButton {
                    id: navigationVisibilty
                    contentItem: Image {
                        source: "qrc:///redesign/sidebar.svg"
                        sourceSize: Qt.size(VLCStyle.redesign.iconSize, VLCStyle.redesign.iconSize)
                        fillMode: Image.PreserveAspectFit
                        opacity: parent.enabled ? 1.0 : 0.4
                    }
                    color: VLCStyle.redesign.color(enabled ? VLCStyle.redesign.textMuted : VLCStyle.redesign.textDisabled,
                                                   colorContext.fg.primary)
                    backgroundColor: VLCStyle.redesign.color(hovered || down ? VLCStyle.redesign.controlHoverBackground : "transparent",
                                                             colorContext.bg.primary)
                    radius: VLCStyle.redesign.controlRadius

                    focus: true

                    text: VLCIcons.panel_left
                    description: qsTr("Show navigation menu")

                    AccessibleCompat.id: "sidebarToggleButton"

                    font.pixelSize: VLCStyle.redesign.iconSize
                    height: VLCStyle.bannerButton_height
                    width: VLCStyle.bannerButton_width

                    onClicked: root.toggleNavigationVisibility()

                    Navigation.parentItem: navigationButtons
                    Navigation.rightItem: historyBack
                }

                Widgets.IconToolButton {
                    id: historyBack
                    color: VLCStyle.redesign.color(enabled ? VLCStyle.redesign.textMuted : VLCStyle.redesign.textDisabled,
                                                   colorContext.fg.primary)
                    backgroundColor: VLCStyle.redesign.color(hovered || down ? VLCStyle.redesign.controlHoverBackground : "transparent",
                                                             colorContext.bg.primary)
                    radius: VLCStyle.redesign.controlRadius

                    font.pixelSize: VLCStyle.redesign.iconSize
                    text: VLCIcons.back
                    description: qsTr("Previous")

                    AccessibleCompat.id: "historyBackButton"

                    height: VLCStyle.bannerButton_height
                    width: VLCStyle.bannerButton_width

                    onClicked: History.previous()
                    enabled: !History.previousEmpty

                    onEnabledChanged: {
                        if (historyBack.activeFocus)
                            navigationVisibilty.focus = true
                    }

                    Navigation.parentItem: navigationButtons
                    Navigation.leftItem: navigationVisibilty
                }

                Widgets.BannerCone {
                    id: logo
                    source: "qrc:///redesign/logo.svg"

                    sourceSize.width: VLCStyle.bannerButton_height
                    sourceSize.height: VLCStyle.bannerButton_height
                    color: VLCStyle.redesign.logoColor
                }
            }
        }

        Text {
            anchors.centerIn: parent
            width: Math.max(0, parent.width - 2 * Math.max(navigationButtons.width, root._showCSD ? csdButtons.width : 0)
                            - 2 * VLCStyle.margin_normal)
            text: Player.title || qsTr("VLC media player")
            color: VLCStyle.redesign.color(VLCStyle.redesign.textMuted, theme.fg.primary)
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.redesign.fontNormal
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            Accessible.ignored: true
        }

        Loader {
            z: -1

            anchors.fill: parent
            active: root._showCSD
            sourceComponent: Widgets.CSDTitlebarTapNDrapHandler {
            }
        }
    }

    Loader {
        id: csdButtons

        //csd button are
        parent:  root
        anchors {
            right: parent.right
            top: parent.top
        }

        height: VLCStyle.redesign.topbarHeight
        active: root._showCSD
        source: "qrc:///qt/qml/VLC/Widgets/CSDWindowButtonSet.qml"
    }
}
