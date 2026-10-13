/*****************************************************************************
 * Copyright (C) 2021 VLC authors and VideoLAN
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
import QtQuick.Window
import QtQuick.Templates as T
import QtQuick.Layouts

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Dialogs


WindowDialog {
    id: root
    objectName: "toolbarEditorDialog"

    width: Math.max(minimumWidth, Math.min(VLCStyle.dp(1048, VLCStyle.scale),
                                          Screen.availableWidth - VLCStyle.dp(40, VLCStyle.scale)))
    height: Math.max(minimumHeight, Math.min(VLCStyle.dp(700, VLCStyle.scale),
                                            Screen.availableHeight - VLCStyle.dp(40, VLCStyle.scale)))

    minimumWidth: VLCStyle.dp(640, VLCStyle.scale)
    minimumHeight: VLCStyle.dp(480, VLCStyle.scale)

    modal: true
    title: qsTr("Customize Player")
    color: VLCStyle.redesign.color("#0e0e0e", root.colorContext.bg.primary)
    standardButtons: 0

    signal unload()

    Component.onCompleted: {
        // Save first, in case the dialog is rejected.
        MainCtx.controlbarProfileModel.save(false)
    }

    onAccepted: {
        MainCtx.controlbarProfileModel.save()
        hide()
        unload()
    }

    onRejected: (byButton) => {
        // Load saved to discard the changes
        MainCtx.controlbarProfileModel.reload()
        hide()
        unload()
    }

    function newProfile(profileCreatorFunction) {
        console.assert(typeof profileCreatorFunction === 'function')

        const count = MainCtx.controlbarProfileModel.rowCount()
        const npDialog = DialogsProvider.getTextDialog(null,
                                                       qsTr("Profile Name"),
                                                       qsTr("Please enter the new profile name:"),
                                                       qsTr("Profile %1").arg(count + 1))
        if (!npDialog.ok)
            return

        profileCreatorFunction(npDialog.text)
        MainCtx.controlbarProfileModel.selectedProfile = count
    }

    function _markDirty(text) {
        return (text += " *")
    }

    contentComponent: Item {
        MouseArea {
            anchors.fill: parent

            cursorShape: toolbarEditor.dragActive ? Qt.ForbiddenCursor : Qt.ArrowCursor
        }

        ColumnLayout {
            anchors.fill: parent

            spacing: VLCStyle.dp(12, VLCStyle.scale)

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: VLCStyle.dp(32, VLCStyle.scale)

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Customize Player")
                    color: VLCStyle.redesign.color("#969696", root.colorContext.fg.primary)
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.redesign.fontNormal
                }

                Widgets.IconToolButton {
                    description: qsTr("Cancel and close")
                    text: VLCIcons.clear
                    onClicked: root.rejected(true)
                }
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Drag controls between the player sections to reorder them. Drag controls into the list to remove them from the player.")
                color: VLCStyle.redesign.color("#969696", root.colorContext.fg.secondary)
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.redesign.fontNormal
            }

            RowLayout {
                Layout.fillHeight: false

                spacing: VLCStyle.margin_xsmall

                Widgets.MenuLabel {
                    Layout.minimumWidth: implicitWidth

                    color: VLCStyle.redesign.color("#969696", root.colorContext.fg.primary)
                    text: qsTr("Select profile:")
                }

                Widgets.ComboBoxExt {
                    id: comboBox
                    objectName: "toolbarEditorProfile"

                    Layout.fillWidth: (implicitWidth > Layout.minimumWidth)
                    Layout.minimumWidth: VLCStyle.combobox_width_large
                    Layout.minimumHeight: VLCStyle.combobox_height_normal

                    // this is not proper way to do it,
                    // but ComboBoxExt does not provide
                    // correct implicit width:
                    implicitWidth: implicitContentWidth
                    font.pixelSize: VLCStyle.fontSize_normal

                    delegate: T.ItemDelegate {
                        width: comboBox.width
                        leftPadding: comboBox.leftPadding
                        background: Item {}
                        contentItem: Text {
                            text: model.dirty ? _markDirty(model.name)
                                              : model.name
                            color: comboBox.color
                            font: comboBox.font
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        highlighted: (comboBox.highlightedIndex === index)
                    }

                    displayText: {
                        let text

                        if (!!MainCtx.controlbarProfileModel.currentModel)
                            text = MainCtx.controlbarProfileModel.currentModel.name
                        else {
                            text = "N/A"
                            return text
                        }

                        if (MainCtx.controlbarProfileModel.currentModel.dirty)
                            return _markDirty(text)
                        else
                            return text
                    }

                    model: MainCtx.controlbarProfileModel

                    currentIndex: MainCtx.controlbarProfileModel.selectedProfile

                    onCurrentIndexChanged: {
                        MainCtx.controlbarProfileModel.selectedProfile = currentIndex
                    }

                    Accessible.name: qsTr("Profiles")
                }

                Widgets.IconToolButton {
                    description: qsTr("Clone the selected profile")
                    text: VLCIcons.ic_fluent_document_copy_24_regular

                    onClicked: {
                        root.newProfile(MainCtx.controlbarProfileModel.cloneSelectedProfile)
                    }
                }

                Widgets.IconToolButton {
                    description: qsTr("New profile")
                    text: VLCIcons.ic_fluent_document_add_24_regular

                    onClicked: {
                        root.newProfile(MainCtx.controlbarProfileModel.newProfile)
                    }
                }

                Widgets.IconToolButton {
                    description: qsTr("Delete the current profile.\nDeleting all profiles brings back the default styles.")
                    text: VLCIcons.del

                    onClicked: {
                          MainCtx.controlbarProfileModel.deleteSelectedProfile()
                    }
                }
            }

            // The main context of the toolbareditor dialog:
            ToolbarEditor {
                id: toolbarEditor

                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: VLCStyle.dp(42, VLCStyle.scale)

                T.Button {
                    objectName: "toolbarEditorCancel"
                    Layout.preferredWidth: VLCStyle.dp(100, VLCStyle.scale)
                    Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
                    text: qsTr("Cancel")
                    activeFocusOnTab: true
                    onClicked: root.rejected(true)

                    background: Rectangle {
                        radius: VLCStyle.redesign.controlRadius
                        color: "#1b1b1b"
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

                Item { Layout.fillWidth: true }

                T.Button {
                    objectName: "toolbarEditorSave"
                    Layout.preferredWidth: VLCStyle.dp(100, VLCStyle.scale)
                    Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
                    text: qsTr("Save")
                    activeFocusOnTab: true
                    onClicked: root.accepted()

                    background: Rectangle {
                        radius: VLCStyle.redesign.controlRadius
                        color: VLCStyle.redesign.accentBackground
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
