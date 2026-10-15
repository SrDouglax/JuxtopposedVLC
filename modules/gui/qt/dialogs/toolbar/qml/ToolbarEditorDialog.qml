/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 *****************************************************************************/
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Dialogs
import VLC.Player

Controls.Popup {
    id: root
    objectName: "toolbarEditorDialog"
    parent: T.Overlay.overlay
    x: 0
    y: 0
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    padding: 0
    modal: true
    dim: true
    focus: true
    closePolicy: Controls.Popup.CloseOnEscape
    background: Item {}
    T.Overlay.modal: Rectangle { color: "#a6000000" }

    // Editing includes controls reparented onto the player strip. Escape
    // belongs to this modal session even when that strip has keyboard focus.
    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: root.opened
        onActivated: root.close()
    }

    signal unload()
    property bool saved: false
    property string newProfileName: ""
    property int initialProfileCount: 0
    property bool previousGlobalShortcuts: true
    property bool previousPlayerView: false
    property bool ownsEditorSession: false
    readonly property ColorContext colorContext: ColorContext {
        palette: VLCStyle.palette
        colorSet: ColorContext.Window
    }

    onOpened: {
        saved = false
        previousPlayerView = MainCtx.playerView
        ownsEditorSession = true
        PlayerControlbarControls.editing = true
        MainCtx.playerView = true
        previousGlobalShortcuts = MainCtx.useGlobalShortcuts
        MainCtx.useGlobalShortcuts = false
        // Retain the current profile as the rollback point for Cancel/Escape.
        MainCtx.controlbarProfileModel.save(false)
        initialProfileCount = MainCtx.controlbarProfileModel.rowCount()
        if (newProfileName.length) {
            MainCtx.controlbarProfileModel.cloneSelectedProfile(newProfileName)
            MainCtx.controlbarProfileModel.setSelectedProfile(initialProfileCount)
        }
        closeButton.forceActiveFocus(Qt.PopupFocusReason)
    }
    onClosed: {
        if (!saved)
            MainCtx.controlbarProfileModel.reload()
        MainCtx.useGlobalShortcuts = previousGlobalShortcuts
        ownsEditorSession = false
        PlayerControlbarControls.editing = false
        MainCtx.playerView = previousPlayerView
        unload()
    }
    Component.onDestruction: {
        if (ownsEditorSession) PlayerControlbarControls.editing = false
    }

    function saveEditor() {
        if (!MainCtx.controlbarProfileModel.save())
            return
        saved = true
        close()
    }

    contentItem: Item {
        id: scene
        // ColorContext follows the visual QQuickItem tree. Popup itself is
        // not an item, so its context cannot provide colors to these controls.
        readonly property ColorContext colorContext: ColorContext {
            palette: VLCStyle.palette
            colorSet: ColorContext.Window
        }

        // This strip sits over the actual player's control bar. Its editor
        // views are reparented here; no static screenshot or parallel model.
        Rectangle {
            id: headerDropHost
            objectName: "toolbarEditorHeaderDropHost"
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: VLCStyle.dp(44, VLCStyle.scale)
            anchors.rightMargin: VLCStyle.dp(152, VLCStyle.scale)
            height: VLCStyle.redesign.topbarHeight
            color: VLCStyle.redesign.color("#1b1b1b", root.colorContext.bg.primary)
        }

        Rectangle {
            id: playerDropHost
            objectName: "toolbarEditorPlayerDropHost"
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.min(VLCStyle.dp(52, VLCStyle.scale), scene.height * 0.20)
            color: VLCStyle.redesign.color("#1b1b1b", root.colorContext.bg.primary)
            border.color: VLCStyle.redesign.color("#343434", root.colorContext.border)
            border.width: 1
        }

        Rectangle {
            id: panel
            objectName: "toolbarEditorPanel"
            width: Math.min(VLCStyle.dp(1048, VLCStyle.scale), scene.width - VLCStyle.dp(32, VLCStyle.scale))
            height: Math.min(VLCStyle.dp(656, VLCStyle.scale),
                             scene.height - playerDropHost.height - VLCStyle.dp(32, VLCStyle.scale))
            x: (scene.width - width) / 2
            y: Math.max(VLCStyle.dp(16, VLCStyle.scale),
                        (scene.height - playerDropHost.height - height) / 2 + VLCStyle.dp(4, VLCStyle.scale))
            radius: VLCStyle.dp(16, VLCStyle.scale)
            color: VLCStyle.redesign.color("#0e0e0e", root.colorContext.bg.primary)
            border.color: VLCStyle.redesign.color("#242424", root.colorContext.border)

            Rectangle {
                width: parent.width
                height: VLCStyle.dp(94, VLCStyle.scale)
                radius: parent.radius
                color: VLCStyle.redesign.color("#090909", "#eeeeee")
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: VLCStyle.dp(16, VLCStyle.scale)
                    color: parent.color
                }
            }

            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: VLCStyle.dp(48, VLCStyle.scale)
                    Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
                    Layout.rightMargin: VLCStyle.dp(12, VLCStyle.scale)
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Customize Player")
                        color: VLCStyle.redesign.color("#969696", root.colorContext.fg.primary)
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: VLCStyle.redesign.fontNormal
                    }
                    Widgets.IconToolButton {
                        id: closeButton
                        objectName: "toolbarEditorClose"
                        description: qsTr("Cancel and close")
                        text: VLCIcons.clear
                        onClicked: root.close()
                        Keys.onEscapePressed: event => {
                            root.close()
                            event.accepted = true
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
                    Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
                    Layout.preferredHeight: VLCStyle.dp(46, VLCStyle.scale)
                    topPadding: VLCStyle.dp(13, VLCStyle.scale)
                    wrapMode: Text.WordWrap
                    text: qsTr("Drag controls onto the player bar to add or reorder them. Drag them back here to remove.")
                    color: VLCStyle.redesign.color("#747474", root.colorContext.fg.secondary)
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.redesign.fontNormal
                }

                ToolbarEditor {
                    id: toolbarEditor
                    objectName: "toolbarEditorContents"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: VLCStyle.dp(22, VLCStyle.scale)
                    Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
                    previewHost: playerDropHost
                    headerPreviewHost: headerDropHost
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: VLCStyle.dp(60, VLCStyle.scale)
                    Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
                    Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
                    T.Button {
                        objectName: "toolbarEditorCancel"
                        Layout.preferredWidth: VLCStyle.dp(100, VLCStyle.scale)
                        Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
                        text: qsTr("Cancel")
                        activeFocusOnTab: true
                        onClicked: root.close()
                        background: Rectangle {
                            radius: VLCStyle.redesign.controlRadius
                            color: parent.down ? "#292929" : "#1b1b1b"
                            border.color: parent.activeFocus ? VLCStyle.redesign.focusColor : "transparent"
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#969696"
                            font.family: VLCStyle.redesign.fontFamily
                            font.pixelSize: VLCStyle.redesign.fontNormal
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                    Text {
                        visible: !!MainCtx.controlbarProfileModel.lastError
                        text: MainCtx.controlbarProfileModel.lastError
                        color: "#e4a580"
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: VLCStyle.redesign.fontSmall
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Accessible.role: Accessible.AlertMessage
                    }
                    Item { Layout.fillWidth: true }
                    T.Button {
                        objectName: "toolbarEditorSave"
                        Layout.preferredWidth: VLCStyle.dp(100, VLCStyle.scale)
                        Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
                        text: qsTr("Save")
                        enabled: !!MainCtx.controlbarProfileModel.currentModel?.dirty
                                 || MainCtx.controlbarProfileModel.count !== root.initialProfileCount
                        activeFocusOnTab: true
                        onClicked: root.saveEditor()
                        background: Rectangle {
                            radius: VLCStyle.redesign.controlRadius
                            color: !parent.enabled ? "#1b1b1b" : parent.down ? Qt.lighter(VLCStyle.redesign.accentBackground, 1.15)
                                               : VLCStyle.redesign.accentBackground
                            border.color: parent.activeFocus ? VLCStyle.redesign.focusColor : "transparent"
                        }
                        contentItem: Text {
                            text: parent.text
                            color: parent.enabled ? VLCStyle.redesign.accent : "#747474"
                            font.family: VLCStyle.redesign.fontFamily
                            font.pixelSize: VLCStyle.redesign.fontNormal
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }
}
