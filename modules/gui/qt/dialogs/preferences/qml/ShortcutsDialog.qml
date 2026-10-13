/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import VLC.Dialogs
import VLC.MainInterface
import VLC.Style

Dialog {
    id: root
    objectName: "redesignShortcutsDialog"
    modal: true
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape
    width: Math.min(VLCStyle.dp(1048, VLCStyle.scale),
                    parent ? parent.width - VLCStyle.dp(32, VLCStyle.scale)
                           : VLCStyle.dp(1048, VLCStyle.scale))
    height: Math.min(VLCStyle.dp(790, VLCStyle.scale),
                     parent ? parent.height - VLCStyle.dp(32, VLCStyle.scale)
                            : VLCStyle.dp(790, VLCStyle.scale))
    anchors.centerIn: parent

    property bool saved: false
    property bool resetRequested: false
    property bool previousGlobalShortcuts: true
    property string captureOption: ""
    property string captureAction: ""
    property bool captureGlobal: false
    property int capturedKey: 0
    property int capturedModifiers: 0
    property string conflictAction: ""
    readonly property bool dark: VLCStyle.palette.isDark
    readonly property var scopes: [
        { text: qsTr("All Fields"), value: "all" },
        { text: qsTr("Action"), value: "action" },
        { text: qsTr("Hotkey"), value: "hotkey" },
        { text: qsTr("Global Hotkey"), value: "global" }
    ]

    function beginCapture(option, global, action) {
        captureOption = option
        captureGlobal = global
        captureAction = action
        conflictAction = ""
        capturePopup.open()
    }

    function assignCaptured(key, modifiers, replaceConflict) {
        const result = shortcuts.stageKey(captureOption, captureGlobal,
                                          key, modifiers, replaceConflict)
        if (result.ok) {
            capturePopup.close()
            return
        }
        if (result.needsConfirmation) {
            capturedKey = key
            capturedModifiers = modifiers
            conflictAction = result.conflictAction
        }
    }

    function openReset() {
        if (visible) resetConfirmation.open()
        else { resetRequested = true; open() }
    }

    onOpened: {
        saved = false
        previousGlobalShortcuts = MainCtx.useGlobalShortcuts
        MainCtx.useGlobalShortcuts = false
        shortcuts.reload()
        searchField.text = ""
        scopePicker.currentIndex = 0
        if (resetRequested) resetConfirmation.open()
        resetRequested = false
    }
    onClosed: {
        capturePopup.close()
        resetConfirmation.close()
        restartNotice.close()
        if (!saved)
            shortcuts.cancel()
        MainCtx.useGlobalShortcuts = previousGlobalShortcuts
    }

    ShortcutsModel {
        id: shortcuts
        ctx: MainCtx
        search: searchField.text
        searchField: root.scopes[Math.max(0, scopePicker.currentIndex)].value
    }

    background: Rectangle {
        color: VLCStyle.redesign.color(VLCStyle.redesign.windowBackground,
                                       VLCStyle.palette.lightGrey100)
        border.color: root.dark ? "#222222" : "#d6d6d6"
        radius: VLCStyle.dp(8, VLCStyle.scale)
    }

    contentItem: Item {
        Rectangle {
            id: titlebar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: VLCStyle.dp(43, VLCStyle.scale)
            color: "transparent"
            Label {
                anchors.left: parent.left
                anchors.leftMargin: VLCStyle.dp(18, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Keyboard Shortcuts")
                color: root.dark ? "#999999" : "#444444"
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }
            Button {
                anchors.right: parent.right
                anchors.rightMargin: 13
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                onClicked: root.reject()
                background: Item {}
                contentItem: Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: "qrc:///redesign/icons/close/default.png"
                }
            }
        }

        Rectangle {
            id: filterbar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: titlebar.bottom
            height: VLCStyle.dp(45, VLCStyle.scale)
            color: "transparent"
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.right: scopePicker.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                height: VLCStyle.dp(34, VLCStyle.scale)
                color: root.dark ? "#181818" : "#eeeeee"
                radius: 4
                Image {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    source: "qrc:///redesign/icons/search/default.png"
                }
                TextField {
                    id: searchField
                    objectName: "shortcutsSearch"
                    anchors.fill: parent
                    leftPadding: 42
                    rightPadding: 10
                    placeholderText: qsTr("Search Keyboard Shortcuts...")
                    color: root.dark ? "#dddddd" : "#222222"
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    background: Item {}
                }
            }
            ComboBox {
                id: scopePicker
                objectName: "shortcutsSearchField"
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: VLCStyle.dp(200, VLCStyle.scale)
                height: VLCStyle.dp(34, VLCStyle.scale)
                model: root.scopes
                textRole: "text"
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                leftPadding: 12
                rightPadding: 34
                contentItem: Label {
                    text: scopePicker.displayText
                    color: root.dark ? "#d4d4d4" : "#292929"
                    font: scopePicker.font
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                indicator: Image {
                    x: scopePicker.width - width - 10
                    y: (scopePicker.height - height) / 2
                    width: 18
                    height: 18
                    source: "qrc:///redesign/icons/chevron-down/default.png"
                }
                background: Rectangle {
                    color: root.dark ? "#191919" : "#eeeeee"
                    border.color: scopePicker.activeFocus ? VLCStyle.redesign.accent
                                                           : (root.dark ? "#333333" : "#cccccc")
                    radius: 4
                }
                delegate: ItemDelegate {
                    required property var modelData
                    width: scopePicker.width
                    height: VLCStyle.dp(34, VLCStyle.scale)
                    contentItem: Label {
                        text: modelData.text
                        color: root.dark ? "#d4d4d4" : "#292929"
                        font: scopePicker.font
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    background: Rectangle {
                        color: parent.highlighted ? (root.dark ? "#303030" : "#e5e5e5")
                                                  : (root.dark ? "#191919" : "#f7f7f7")
                    }
                }
                popup: Popup {
                    y: scopePicker.height
                    width: scopePicker.width
                    implicitHeight: Math.min(contentItem.implicitHeight,
                                             VLCStyle.dp(180, VLCStyle.scale))
                    padding: 1
                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: scopePicker.popup.visible ? scopePicker.delegateModel : null
                        currentIndex: scopePicker.highlightedIndex
                        ScrollIndicator.vertical: ScrollIndicator {}
                    }
                    background: Rectangle {
                        color: root.dark ? "#191919" : "#f7f7f7"
                        border.color: root.dark ? "#383838" : "#cccccc"
                        radius: 4
                    }
                }
            }
        }

        Rectangle {
            id: tableHeader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: filterbar.bottom
            height: VLCStyle.dp(64, VLCStyle.scale)
            color: root.dark ? "#171717" : "#eeeeee"
            Label {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Action")
                color: root.dark ? "#777777" : "#555555"
            }
            Label {
                x: parent.width * 0.49
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Hotkey")
                color: root.dark ? "#777777" : "#555555"
            }
            Label {
                x: parent.width * 0.81
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Global Hotkey")
                color: root.dark ? "#777777" : "#555555"
            }
        }

        ListView {
            id: shortcutList
            objectName: "shortcutsList"
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.top: tableHeader.bottom
            anchors.bottom: footer.top
            clip: true
            model: shortcuts
            spacing: 0
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            section.property: "group"
            section.criteria: ViewSection.FullString
            section.delegate: Item {
                width: shortcutList.width
                height: VLCStyle.dp(57, VLCStyle.scale)
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 1
                    color: root.dark ? "#252525" : "#dddddd"
                }
                Label {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: section
                    color: root.dark ? "#a0a0a0" : "#333333"
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                }
            }
            delegate: Item {
                id: shortcutRow
                required property string key
                required property string action
                required property string hotkey
                required property string globalHotkey
                required property bool dirty
                width: shortcutList.width
                height: VLCStyle.dp(47, VLCStyle.scale)

                Label {
                    anchors.left: parent.left
                    anchors.right: hotkeyButton.left
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: shortcutRow.action
                    color: shortcutRow.dirty ? VLCStyle.redesign.accent
                                            : (root.dark ? "#b8b8b8" : "#333333")
                    elide: Text.ElideRight
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                }
                Button {
                    id: hotkeyButton
                    objectName: "hotkey_" + shortcutRow.key
                    x: parent.width * 0.37
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.28
                    height: VLCStyle.dp(34, VLCStyle.scale)
                    onClicked: root.beginCapture(shortcutRow.key, false, shortcutRow.action)
                    background: Rectangle {
                        color: root.dark ? "#080808" : "#fafafa"
                        radius: 5
                    }
                    contentItem: Item {
                        Label {
                            anchors.centerIn: parent
                            width: parent.width - 40
                            text: shortcutRow.hotkey
                            color: root.dark ? "#c6c6c6" : "#333333"
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                        }
                        Image {
                            anchors.right: parent.right
                            anchors.rightMargin: 7
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            source: "qrc:///redesign/icons/edit/default.png"
                        }
                    }
                }
                Button {
                    objectName: "globalHotkey_" + shortcutRow.key
                    x: parent.width * 0.73
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.27
                    height: VLCStyle.dp(34, VLCStyle.scale)
                    onClicked: root.beginCapture(shortcutRow.key, true, shortcutRow.action)
                    background: Rectangle {
                        color: root.dark ? "#080808" : "#fafafa"
                        radius: 5
                    }
                    contentItem: Item {
                        Label {
                            anchors.centerIn: parent
                            width: parent.width - 40
                            text: shortcutRow.globalHotkey
                            color: root.dark ? "#c6c6c6" : "#333333"
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                        }
                        Image {
                            anchors.right: parent.right
                            anchors.rightMargin: 7
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            source: "qrc:///redesign/icons/edit/default.png"
                        }
                    }
                }
            }
        }

        Rectangle {
            id: footer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: VLCStyle.dp(60, VLCStyle.scale)
            color: "transparent"
            Label {
                anchors.left: resetButton.right
                anchors.leftMargin: 12
                anchors.right: saveButton.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: shortcuts.error
                visible: shortcuts.error.length > 0
                color: "#df8950"
                elide: Text.ElideRight
                font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
            }
            ActionButton {
                id: cancelButton
                objectName: "shortcutsCancel"
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Cancel")
                onClicked: root.reject()
            }
            ActionButton {
                id: resetButton
                objectName: "shortcutsResetAll"
                anchors.left: cancelButton.right
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Reset all")
                onClicked: resetConfirmation.open()
            }
            ActionButton {
                id: saveButton
                objectName: "shortcutsSave"
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Save")
                primary: true
                enabled: shortcuts.dirty
                onClicked: {
                    if (!shortcuts.apply())
                        return
                    root.saved = true
                    restartNotice.open()
                }
            }
        }
    }

    ShortcutsCapturePopup {
        id: capturePopup
        objectName: "shortcutCapturePopup"
        parent: root.contentItem
        anchors.centerIn: parent
        width: Math.min(VLCStyle.dp(470, VLCStyle.scale), root.width - 30)
        captureGlobal: root.captureGlobal
        captureAction: root.captureAction
        conflictAction: root.conflictAction
        errorText: shortcuts.error
        onKeyCaptured: (key, modifiers) => root.assignCaptured(key, modifiers, false)
        onClearRequested: {
            shortcuts.clearKey(root.captureOption, root.captureGlobal)
            capturePopup.close()
        }
        onReplaceRequested: root.assignCaptured(root.capturedKey,
                                                 root.capturedModifiers, true)
    }

    ShortcutsResetPopup {
        id: resetConfirmation
        objectName: "shortcutsResetConfirmation"
        parent: root.contentItem
        anchors.centerIn: parent
        width: Math.min(VLCStyle.dp(420, VLCStyle.scale), root.width - 30)
        onConfirmed: shortcuts.resetAll()
        onClosed: {
            if (root.visible)
                resetButton.forceActiveFocus(Qt.PopupFocusReason)
        }
    }

    ShortcutsRestartNotice {
        id: restartNotice
        parent: root.parent
        anchors.centerIn: parent
        onAccepted: root.close()
    }
}
