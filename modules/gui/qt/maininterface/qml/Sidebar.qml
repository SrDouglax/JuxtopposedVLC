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

SideNavigationPane {
    id: sidebar

    required property Item mainDisplay
    required property Item view
    required property Item toolbar
    required property Item updatePane
    required property QtObject panels
    required property bool playqueueShown
    required property bool roundedCornerVisible
    readonly property bool transitioning: sidebarTransition.running

    readonly property var pageModel: [
        {
            name: "home",
            url: MainCtx.mediaLibraryAvailable ?
                 "qrc:///qt/qml/VLC/MediaLibrary/HomeDisplay.qml" :
                 "qrc:///qt/qml/VLC/MainInterface/NoMedialibHome.qml"
        }, {
            name: "video",
            url: "qrc:///qt/qml/VLC/MediaLibrary/VideoDisplay.qml"
        }, {
            name: "music",
            url: "qrc:///qt/qml/VLC/MediaLibrary/MusicDisplay.qml"
        }, {
            name: "network",
            url: "qrc:///qt/qml/VLC/Network/BrowseDisplay.qml"
        }, {
            name: "discover",
            url: "qrc:///qt/qml/VLC/Network/DiscoverDisplay.qml"
        }, {
            name: "mlsettings",
            url: "qrc:///qt/qml/VLC/MediaLibrary/MLFoldersSettings.qml"
        }
    ]


    z: 3

    anchors {
        top : parent.top
        left: parent.left
    }

    width: VLCStyle.isScreenReallySmall ? 0.0 : collapsedWidth

    property real collapsedWidth: VLCStyle.icon_normal + VLCStyle.margin_small + VLCStyle.margin_xsmall + VLCStyle.applicationHorizontalMargin

    delegateShowText: (state === "expanded")

    visible: (width > 0.0)

    height: parent.height - sidebar.mainDisplay.displayMargin

    property int maximumWidth: Math.max(minimumWidth, (sidebar.mainDisplay.width + sidebarResizeHandle.width) / 3)

    topPadding: 0
    leftPadding: 0
    rightPadding: sidebarResizeHandle.visible ? sidebarResizeHandle.visualBorder.width : 0.0
    bottomPadding: VLCStyle.applicationVerticalMargin + VLCStyle.margin_small

    safeAreaLeftMargin: VLCStyle.applicationHorizontalMargin

    useAcrylic: (VLCStyle.isScreenSmall ? (sidebar.state === "") : true) // See `694d51a7` for the reasoning.

    NavigationBarContextMenu {
        id: navigationBarContextMenu

        ctx: MainCtx

        model: sidebar.model

        onPageRequested: (uri) => {
            if (sidebar.view.isDefaulLoadedForPath([...uri]) ||
                History.exactMatch(History.viewPath, uri)) {
                sidebar.view.positionContentAtBeginning()
                return
            }

            History.push(uri)
        }
    }

    onItemClicked: (modelUri, item) => {
        console.assert(modelUri)

        console.assert(item)
        if ((sidebar.state !== 'expanded') && item.expandable) {
            // TODO: Investigate opening the menu on hover, if
            //       we switch to `Popup.Item` type of menus.
            const mappedPos = item.mapToGlobal(item.width, 0)
            navigationBarContextMenu.popup(item.index, mappedPos, !item.hovered)

            return
        }

        if (sidebar.view.isDefaulLoadedForPath([...modelUri]) ||
            !!modelUri.length && History.exactMatch(History.viewPath, modelUri)) {
            sidebar.view.positionContentAtBeginning()
            return
        }

        History.push(modelUri)
    }

    implicitWidth: Math.round(Helpers.clamp(MainCtx.navigationPanel.width, minimumWidth, maximumWidth))

    Navigation.parentItem: sidebar.mainDisplay
    Navigation.upItem: sidebar.toolbar
    Navigation.downItem: sidebar.updatePane
    Navigation.rightItem: sidebar.view.currentItem

    state: sidebar.panels.showNavigation ? "expanded" : ""

    onVisibleChanged: {
        if (!visible) {
            sidebar.view.focus = true
        }
    }

    Component.onCompleted: {
        Qt.callLater(() => { sidebarTransition.enabled = true; })
    }

    states: State {
        name: "expanded"
        PropertyChanges {
            target: sidebar
            width: sidebar.implicitWidth
        }
    }

    transitions: Transition {
        id: sidebarTransition
        enabled: false

        from: ""; to: "expanded";
        reversible: true

        NumberAnimation {
            property: "width"
            duration: VLCStyle.duration_short
            easing.type: Easing.InOutSine
        }
    }

    PaneResizeHandle {
        id: sidebarResizeHandle

        parent: sidebar
        target: sidebar

        panelObject: MainCtx.navigationPanel
        atRight: true

        resizeHandle.visible: (sidebar.state === "expanded") && !VLCStyle.isScreenSmall
        visualBorder.visible: !sidebar.roundedCornerVisible

        minimumWidth: sidebar.minimumWidth
        maximumWidth: sidebar.maximumWidth

        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }

    }
    Rectangle {
        id: smallScreenOverlay
        parent: sidebar.parent

        // overlay for smallscreens
        z: 2

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        height: parent.height - sidebar.mainDisplay.displayMargin

        visible: VLCStyle.isScreenSmall && (sidebar.playqueueShown || (sidebar.visible && (sidebar.state === "expanded")))
        color: "black"
        opacity: 0.4

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked:  sidebar.panels.hideVisiblePanels()

            // Capture WheelEvents before they reach stackView
            onWheel: (wheel) => {
                wheel.accepted = true
            }
        }
    }

}

