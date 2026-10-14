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

    signal unload()
    property bool saved: false
    property bool previousGlobalShortcuts: true
    readonly property ColorContext colorContext: ColorContext {
        palette: VLCStyle.palette
        colorSet: ColorContext.Window
    }

    onOpened: {
        saved = false
        previousGlobalShortcuts = MainCtx.useGlobalShortcuts
        MainCtx.useGlobalShortcuts = false
        // Retain the current profile as the rollback point for Cancel/Escape.
        MainCtx.controlbarProfileModel.save(false)
        closeButton.forceActiveFocus(Qt.PopupFocusReason)
    }
    onClosed: {
        if (!saved)
            MainCtx.controlbarProfileModel.reload()
        MainCtx.useGlobalShortcuts = previousGlobalShortcuts
        unload()
    }

    function saveEditor() {
        if (!MainCtx.controlbarProfileModel.save())
            return
        saved = true
        close()
    }

    function newProfile(createProfile) {
        const count = MainCtx.controlbarProfileModel.rowCount()
        const dialog = DialogsProvider.getTextDialog(null,
                                                     qsTr("Profile Name"),
                                                     qsTr("Please enter the new profile name:"),
                                                     qsTr("Profile %1").arg(count + 1))
        if (!dialog.ok)
            return
        createProfile(dialog.text)
        MainCtx.controlbarProfileModel.selectedProfile = count
    }

    function markedName(name, dirty) { return dirty ? name + " *" : name }

    contentItem: Item {
        id: scene

        // This strip sits over the actual player's control bar. Its editor
        // views are reparented here; no static screenshot or parallel model.
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
            height: Math.min(VLCStyle.dp(624, VLCStyle.scale),
                             scene.height - playerDropHost.height - VLCStyle.dp(32, VLCStyle.scale))
            x: (scene.width - width) / 2
            y: Math.max(VLCStyle.dp(16, VLCStyle.scale),
                        (scene.height - playerDropHost.height - height) / 2)
            radius: VLCStyle.dp(8, VLCStyle.scale)
            color: VLCStyle.redesign.color("#0e0e0e", root.colorContext.bg.primary)
            border.color: VLCStyle.redesign.color("#242424", root.colorContext.border)

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
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
                    Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
                    Layout.preferredHeight: VLCStyle.dp(38, VLCStyle.scale)
                    wrapMode: Text.WordWrap
                    text: qsTr("Drag controls onto the player bar to add or reorder them. Drag them back here to remove.")
                    color: VLCStyle.redesign.color("#747474", root.colorContext.fg.secondary)
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.redesign.fontNormal
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
                    Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
                    Layout.preferredHeight: VLCStyle.dp(42, VLCStyle.scale)
                    spacing: VLCStyle.margin_xsmall
                    Text {
                        text: qsTr("Profile")
                        color: VLCStyle.redesign.color("#969696", root.colorContext.fg.primary)
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: VLCStyle.redesign.fontNormal
                    }
                    Widgets.ComboBoxExt {
                        id: profilePicker
                        objectName: "toolbarEditorProfile"
                        Layout.preferredWidth: VLCStyle.dp(230, VLCStyle.scale)
                        Layout.minimumHeight: VLCStyle.combobox_height_normal
                        model: MainCtx.controlbarProfileModel
                        currentIndex: MainCtx.controlbarProfileModel.selectedProfile
                        onCurrentIndexChanged: MainCtx.controlbarProfileModel.selectedProfile = currentIndex
                        displayText: {
                            const profile = MainCtx.controlbarProfileModel.currentModel
                            return profile ? root.markedName(profile.name, profile.dirty) : qsTr("No profile")
                        }
                        delegate: T.ItemDelegate {
                            width: profilePicker.width
                            contentItem: Text {
                                text: root.markedName(model.name, model.dirty)
                                color: profilePicker.color
                                font: profilePicker.font
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                        Accessible.name: qsTr("Profiles")
                    }
                    Widgets.IconToolButton {
                        description: qsTr("Clone selected profile")
                        text: VLCIcons.ic_fluent_document_copy_24_regular
                        onClicked: root.newProfile(MainCtx.controlbarProfileModel.cloneSelectedProfile)
                    }
                    Widgets.IconToolButton {
                        description: qsTr("New profile")
                        text: VLCIcons.ic_fluent_document_add_24_regular
                        onClicked: root.newProfile(MainCtx.controlbarProfileModel.newProfile)
                    }
                    Widgets.IconToolButton {
                        description: qsTr("Delete selected profile")
                        text: VLCIcons.del
                        onClicked: MainCtx.controlbarProfileModel.deleteSelectedProfile()
                    }
                    Item { Layout.fillWidth: true }
                }

                ToolbarEditor {
                    id: toolbarEditor
                    objectName: "toolbarEditorContents"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: VLCStyle.dp(12, VLCStyle.scale)
                    Layout.rightMargin: VLCStyle.dp(12, VLCStyle.scale)
                    previewHost: playerDropHost
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
                        activeFocusOnTab: true
                        onClicked: root.saveEditor()
                        background: Rectangle {
                            radius: VLCStyle.redesign.controlRadius
                            color: parent.down ? Qt.lighter(VLCStyle.redesign.accentBackground, 1.15)
                                               : VLCStyle.redesign.accentBackground
                            border.color: parent.activeFocus ? VLCStyle.redesign.focusColor : "transparent"
                        }
                        contentItem: Text {
                            text: parent.text
                            color: VLCStyle.redesign.accent
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
