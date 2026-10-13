/*****************************************************************************
 * Copyright (C) 2025 VLC authors and VideoLAN
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


import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Util

T.ItemDelegate {
    id: control

    // Properties

    property string iconTxt: ""
    property string referenceIconName: ""
    property var navigationUri: []
    property int navigationDepth: 0

    readonly property url imageSource: {
        if (referenceIconName.length > 0)
            return "qrc:///redesign/" + referenceIconName + ".svg"
        const icons = {}
        icons[VLCIcons.home] = "home"
        icons[VLCIcons.topbar_video] = "video"
        icons[VLCIcons.topbar_music] = "music"
        icons[VLCIcons.topbar_network] = "network"
        icons[VLCIcons.settings] = "settings"
        return icons[iconTxt] ? "qrc:///redesign/" + icons[iconTxt] + ".svg" : ""
    }

    property bool showText: true

    property real radius: VLCStyle.redesign.controlRadius

    // Settings

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: VLCStyle.margin_xxsmall

    leftInset: implicitLeftInset
    rightInset: implicitRightInset

    topInset: implicitTopInset
    bottomInset: implicitBottomInset

    property real implicitLeftInset: VLCStyle.margin_xxsmall
    property real implicitRightInset: VLCStyle.margin_xxsmall

    property real implicitTopInset: VLCStyle.margin_xxxsmall
    property real implicitBottomInset: VLCStyle.margin_xxxsmall

    // Accessible

    Accessible.onPressAction: control.clicked()
    AccessibleCompat.id: {
        if (navigationDepth !== 0 || navigationUri.length === 0) return "";
        const navBarIds = {
            "home": "homeNavBar",
            "video": "videoNavBar",
            "music": "musicNavBar",
            "network": "browseNavBar",
            "discover": "discoverNavBar"
        }
        const id = navBarIds[navigationUri[0]]
        if (id !== undefined)
            return id
        else
            return ""
    }

    // Tooltip

    T.ToolTip.visible: (showText === false && T.ToolTip.text && (hovered || visualFocus))

    T.ToolTip.delay: VLCStyle.delayToolTipAppear

    T.ToolTip.text: text

    // Childs

    ColorContext {
        id: theme
        colorSet: ColorContext.TabButton

        focused: control.visualFocus
        hovered: control.hovered
        pressed: control.down
        enabled: control.enabled
    }

    background: Widgets.AnimatedBackground {
        enabled: theme.initialized
        color: VLCStyle.redesign.color(control.down || control.checked ? VLCStyle.redesign.selectionBackground
                                                                       : control.hovered ? VLCStyle.redesign.controlHoverBackground
                                                                                         : "transparent", theme.bg.primary)
        border.color: visualFocus ? VLCStyle.redesign.color(VLCStyle.redesign.focusColor, theme.visualFocus) : "transparent"

        radius: control.radius

        Widgets.CurrentIndicator {
            anchors {
                left: parent.left
                leftMargin: VLCStyle.margin_xxxsmall
                verticalCenter: parent.verticalCenter
            }
            implicitHeight: parent.height / 2
            visible: control.checked && !VLCStyle.palette.isDark

            radius: control.radius / 2
        }
    }

    contentItem: RowLayout {
        spacing: VLCStyle.margin_xsmall

        Item {
            Layout.preferredWidth: VLCStyle.redesign.iconSize
            Layout.fillHeight: true

            Image {
                id: referenceIcon
                anchors.centerIn: parent
                width: VLCStyle.redesign.iconSize
                height: width
                sourceSize: Qt.size(width, height)
                source: control.imageSource
                visible: VLCStyle.palette.isDark && source.toString().length > 0 && status === Image.Ready
                opacity: control.enabled ? 1.0 : 0.4
                fillMode: Image.PreserveAspectFit
            }

            Widgets.IconLabel {
                id: iconLabel

                visible: text.length > 0 && !referenceIcon.visible

                anchors.centerIn: parent

                text: control.iconTxt

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                color: VLCStyle.redesign.color(!control.enabled ? VLCStyle.redesign.textDisabled
                                                               : control.checked ? VLCStyle.redesign.accent
                                                                                 : VLCStyle.redesign.textMuted,
                                             (control.highlighted || control.checked) ? theme.accent : theme.fg.primary)

                font.pixelSize: VLCStyle.redesign.iconSize
            }
        }

        T.Label {
            id: label

            Layout.fillWidth: true
            Layout.fillHeight: true

            text: control.text

            verticalAlignment: Text.AlignVCenter

            color: VLCStyle.redesign.color(!control.enabled ? VLCStyle.redesign.textDisabled
                                                           : control.checked ? VLCStyle.redesign.textPrimary
                                                                             : VLCStyle.redesign.textMuted,
                                           control.checked ? theme.fg.secondary : theme.fg.primary)

            elide: Text.ElideRight

            visible: control.showText

            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.redesign.fontNormal

            font.weight: Font.Normal

            //button text is already exposed
            Accessible.ignored: true

            Behavior on color {
                enabled: theme.initialized

                ColorAnimation {
                    duration: VLCStyle.duration_short
                }
            }
        }
    }
}
