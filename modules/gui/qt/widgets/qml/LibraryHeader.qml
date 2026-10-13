/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *****************************************************************************/
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Style
import VLC.Menus
import VLC.Util
import VLC.Widgets as Widgets

T.ToolBar {
    id: root
    objectName: "libraryHeader"

    required property string title
    property int itemCount: -1
    property Component headerAction: null
    property SortMenu sortMenu: null
    required property SearchCtx search
    required property SortCtx sort

    readonly property bool compact: width < VLCStyle.dp(1320, VLCStyle.scale)
    readonly property string breadcrumb: {
        const detail = History.viewProp && History.viewProp.title ? History.viewProp.title : ""
        return detail && detail !== title ? title + "  ›  " + detail : title
    }

    position: T.ToolBar.Header
    leftPadding: VLCStyle.dp(20, VLCStyle.scale)
    rightPadding: leftPadding
    topPadding: VLCStyle.dp(20, VLCStyle.scale)
    bottomPadding: VLCStyle.dp(17, VLCStyle.scale)
    implicitHeight: implicitContentHeight + topPadding + bottomPadding + 1
    implicitWidth: implicitContentWidth + leftPadding + rightPadding

    Navigation.navigable: true

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }
    readonly property bool darkTheme: theme.palette ? theme.palette.isDark : true

    background: Rectangle {
        color: VLCStyle.redesign.color(VLCStyle.redesign.windowBackground,
                                       theme.bg.primary, root.darkTheme)
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: VLCStyle.redesign.color(VLCStyle.redesign.separator,
                                           theme.border, root.darkTheme)
        }
    }

    contentItem: GridLayout {
        columns: root.compact ? 2 : 4
        columnSpacing: VLCStyle.dp(14, VLCStyle.scale)
        rowSpacing: VLCStyle.dp(12, VLCStyle.scale)

        RowLayout {
            Layout.row: 0
            Layout.column: 0
            Layout.fillWidth: true
            spacing: VLCStyle.dp(12, VLCStyle.scale)

            Widgets.IconToolButton {
                text: VLCIcons.back
                description: qsTr("Previous")
                width: VLCStyle.dp(24, VLCStyle.scale)
                height: width
                contentItem: Widgets.ScaledImage {
                    source: "qrc:///redesign/arrow-left.svg"
                    mirror: true
                    opacity: parent.enabled ? 1 : 0.4
                }
                enabled: !History.previousEmpty
                onClicked: History.previous()
            }

            Widgets.IconToolButton {
                text: VLCIcons.back
                description: qsTr("Next")
                width: VLCStyle.dp(24, VLCStyle.scale)
                height: width
                contentItem: Widgets.ScaledImage {
                    source: "qrc:///redesign/arrow-right.svg"
                    mirror: true
                    opacity: 0.4
                }
                enabled: false // NavigationHistory exposes previous, but has no forward stack.
            }

            Widgets.ListLabel {
                Layout.fillWidth: true
                text: root.breadcrumb
                elide: Text.ElideMiddle
                font.family: VLCStyle.redesign.fontFamily
                font.weight: Font.Normal
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                color: VLCStyle.redesign.color(VLCStyle.redesign.textSecondary,
                                               theme.fg.primary, root.darkTheme)
            }
        }

        Widgets.MenuCaption {
            Layout.row: root.compact ? 1 : 0
            Layout.column: root.compact ? 0 : 1
            visible: root.itemCount >= 0
            text: qsTr("%n items", "", root.itemCount)
            color: VLCStyle.redesign.color("#6B6B6B", theme.fg.secondary,
                                           root.darkTheme)
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }

        Loader {
            id: actionLoader
            Layout.row: root.compact ? 1 : 0
            Layout.column: root.compact ? 1 : 2
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            sourceComponent: root.headerAction
            active: sourceComponent !== null
            visible: active
        }

        RowLayout {
            Layout.row: root.compact ? 2 : 0
            Layout.column: root.compact ? 0 : 3
            Layout.columnSpan: root.compact ? 2 : 1
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: VLCStyle.dp(10, VLCStyle.scale)

            Widgets.SortControl {
                visible: root.sort.available
                width: VLCStyle.dp(24, VLCStyle.scale)
                height: width
                contentItem: Widgets.ScaledImage {
                    source: "qrc:///redesign/sort.svg"
                    fillMode: Image.PreserveAspectFit
                }
                model: root.sort.model
                menu: root.sortMenu
                sortKey: root.sort.criteria
                sortOrder: root.sort.order
                onSortSelected: (key) => root.sort.criteria = key
                onSortOrderSelected: (order) => root.sort.order = order
            }

            Widgets.IconToolButton {
                visible: MainCtx.hasGridListMode
                text: MainCtx.gridView ? VLCIcons.list : VLCIcons.grid
                description: qsTr("List/Grid")
                width: VLCStyle.dp(24, VLCStyle.scale)
                height: width
                contentItem: Widgets.ScaledImage {
                    source: "qrc:///redesign/grid.svg"
                    fillMode: Image.PreserveAspectFit
                }
                onClicked: MainCtx.gridView = !MainCtx.gridView
            }

            Rectangle {
                id: searchBackground
                visible: root.search.available
                Layout.preferredWidth: VLCStyle.dp(325, VLCStyle.scale)
                Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: VLCStyle.redesign.color("#151515", theme.bg.secondary,
                                               root.darkTheme)
                border.width: searchField.activeFocus ? 1 : 0
                border.color: VLCStyle.redesign.focusColor

                Widgets.ScaledImage {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.leftMargin: VLCStyle.dp(8, VLCStyle.scale)
                    anchors.verticalCenter: parent.verticalCenter
                    width: VLCStyle.dp(24, VLCStyle.scale)
                    height: width
                    source: "qrc:///redesign/search.svg"
                    fillMode: Image.PreserveAspectFit
                }

                Widgets.TextFieldExt {
                    id: searchField
                    objectName: "librarySearchField"
                    anchors.left: searchIcon.right
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: VLCStyle.dp(10, VLCStyle.scale)
                    anchors.rightMargin: VLCStyle.dp(8, VLCStyle.scale)
                    background: Item {}
                    padding: 0
                    placeholderText: qsTr("Search")
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    Accessible.searchEdit: true

                    onActiveFocusChanged: MainCtx.useGlobalShortcuts = !activeFocus
                }

                Binding {
                    target: root.search
                    property: "pattern"
                    value: searchField.text
                    delayed: true
                }

                Connections {
                    target: root.search
                    function onAskShow() { searchField.forceActiveFocus(Qt.ShortcutFocusReason) }
                }
            }
        }
    }
}
