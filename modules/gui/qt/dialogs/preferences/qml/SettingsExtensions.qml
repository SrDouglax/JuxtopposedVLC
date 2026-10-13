/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import VLC.MainInterface
import VLC.Network
import VLC.Style

Column {
    id: root
    property var settingsModel
    property bool onlineRequested: false
    readonly property bool dark: VLCStyle.palette.isDark
    readonly property var selectedAddon: addonsView.currentItem
    width: parent ? parent.width : implicitWidth
    spacing: VLCStyle.dp(12, VLCStyle.scale)

    ServicesDiscoveryModel {
        id: addons
        ctx: MainCtx
        typeFilter: ServicesDiscoveryModel.TYPE_NONE
        stateFilter: installedOnly.checked
                     ? ServicesDiscoveryModel.STATE_INSTALLED
                     : ServicesDiscoveryModel.STATE_NONE
        searchPattern: searchField.text
    }

    Label {
        text: qsTr("Add-ons")
        color: root.dark ? "#d2d2d2" : "#252525"
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
    }

    Rectangle {
        width: root.width
        height: VLCStyle.dp(192, VLCStyle.scale)
        color: root.dark ? "#0c0c0c" : "#fafafa"
        border.color: root.dark ? "#242424" : "#d7d7d7"
        radius: 4

        ListView {
            id: addonsView
            objectName: "settingsAddonsList"
            anchors.fill: parent
            anchors.margins: 2
            clip: true
            model: addons
            currentIndex: -1
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            delegate: Item {
                id: addonRow
                required property int index
                required property string name
                required property string summary
                required property string author
                required property int state
                required property bool manageable
                required property bool broken
                width: addonsView.width
                height: VLCStyle.dp(52, VLCStyle.scale)
                readonly property bool selected: addonsView.currentIndex === index

                Rectangle {
                    anchors.fill: parent
                    color: addonRow.selected ? (root.dark ? "#262626" : "#e8e8e8")
                                             : (root.dark ? "#111111" : "#fafafa")
                }
                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: stateLabel.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Label {
                        width: parent.width
                        text: addonRow.name
                        color: root.dark ? "#d0d0d0" : "#292929"
                        elide: Text.ElideRight
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    }
                    Label {
                        width: parent.width
                        text: addonRow.summary || addonRow.author
                        color: root.dark ? "#858585" : "#666666"
                        elide: Text.ElideRight
                        font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
                    }
                }
                Label {
                    id: stateLabel
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: addonRow.state === ServicesDiscoveryModel.STATE_INSTALLED
                          ? qsTr("Installed")
                          : addonRow.state === ServicesDiscoveryModel.STATE_INSTALLING
                            ? qsTr("Installing…")
                            : addonRow.state === ServicesDiscoveryModel.STATE_UNINSTALLING
                              ? qsTr("Removing…") : ""
                    color: root.dark ? "#969696" : "#555555"
                    font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: addonsView.currentIndex = addonRow.index
                }
            }
        }

        BusyIndicator {
            anchors.centerIn: parent
            running: addons.loading
            visible: running
            width: 32
            height: 32
        }
        Label {
            anchors.centerIn: parent
            visible: !addons.loading && addons.count === 0
            text: root.onlineRequested
                  ? qsTr("No add-ons found. The online catalog may be unavailable.")
                  : qsTr("No add-ons found in the local catalog.")
            color: root.dark ? "#858585" : "#666666"
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
        }
    }

    Row {
        width: root.width
        spacing: VLCStyle.dp(10, VLCStyle.scale)
        TextField {
            id: searchField
            objectName: "settingsAddonsSearch"
            width: Math.min(VLCStyle.dp(208, VLCStyle.scale), root.width * 0.3)
            height: VLCStyle.dp(34, VLCStyle.scale)
            placeholderText: qsTr("Search")
            selectByMouse: true
            color: root.dark ? "#d0d0d0" : "#292929"
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            background: Rectangle {
                color: root.dark ? "#101010" : "#fafafa"
                border.color: searchField.activeFocus ? VLCStyle.redesign.accent
                                                      : (root.dark ? "#272727" : "#cccccc")
                radius: 4
            }
            onTextChanged: addonsView.currentIndex = -1
        }
        Item { width: Math.max(0, root.width - searchField.width - findButton.width
                                   - addButton.width - removeButton.width
                                   - VLCStyle.dp(30, VLCStyle.scale)); height: 1 }
        ActionButton {
            id: findButton
            objectName: "settingsFindAddons"
            text: root.onlineRequested ? qsTr("Refresh online list")
                                       : qsTr("Find more extensions")
            enabled: !addons.loading
            onClicked: {
                root.onlineRequested = true
                addonsView.currentIndex = -1
                addons.loadFromDefaultRepository()
            }
        }
        ActionButton {
            id: addButton
            objectName: "settingsInstallAddon"
            text: qsTr("Add")
            enabled: root.selectedAddon
                     && root.selectedAddon.manageable && !root.selectedAddon.broken
                     && root.selectedAddon.state === ServicesDiscoveryModel.STATE_NOTINSTALLED
            onClicked: addons.installService(addonsView.currentIndex)
        }
        ActionButton {
            id: removeButton
            objectName: "settingsRemoveAddon"
            text: qsTr("Remove")
            enabled: root.selectedAddon && root.selectedAddon.manageable
                     && root.selectedAddon.state === ServicesDiscoveryModel.STATE_INSTALLED
            onClicked: addons.removeService(addonsView.currentIndex)
        }
    }

    CheckBox {
        id: installedOnly
        objectName: "settingsInstalledOnly"
        text: qsTr("Installed only")
        checked: false
        onCheckedChanged: addonsView.currentIndex = -1
        indicator: Rectangle {
            x: 2
            y: (installedOnly.height - height) / 2
            width: 17
            height: 17
            radius: 3
            color: installedOnly.checked ? "#371f06" : (root.dark ? "#181818" : "#fafafa")
            border.color: installedOnly.activeFocus ? VLCStyle.redesign.accent
                                                  : (root.dark ? "#555555" : "#aaaaaa")
            Label {
                anchors.centerIn: parent
                text: installedOnly.checked ? "✓" : ""
                color: VLCStyle.redesign.accent
                font.pixelSize: 13
            }
        }
        contentItem: Label {
            text: installedOnly.text
            color: root.dark ? "#a0a0a0" : "#444444"
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
            leftPadding: installedOnly.indicator.width + installedOnly.spacing
            verticalAlignment: Text.AlignVCenter
        }
    }

    Label {
        visible: root.selectedAddon
                 && (!root.selectedAddon.manageable || root.selectedAddon.broken)
        width: root.width
        text: root.selectedAddon && root.selectedAddon.broken
              ? qsTr("This add-on is marked as broken.")
              : qsTr("This add-on was installed manually and cannot be managed here.")
        color: root.dark ? "#d19a67" : "#8a4a17"
        wrapMode: Text.WordWrap
        font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
    }

    Repeater {
        model: root.settingsModel
        delegate: SettingsOptionRow {
            width: root.width
            settingKey: model.key
            label: qsTr("Load add-ons on startup")
            help: model.help
            settingType: model.type
            settingValue: model.value
            choices: model.choices
            dirty: model.dirty
            onCommit: (value) => root.settingsModel.setValue(settingKey, value)
        }
    }
}
