/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as C
import QtQuick.Templates as T
import VLC.MainInterface
import VLC.Style

C.Popup {
    id: root
    property string title
    required property Component panel
    property real preferredWidth: 1048
    property real preferredHeight: 632
    property bool canSave: false
    property bool previousGlobalShortcuts: true
    signal saveRequested()
    width: Math.min(VLCStyle.dp(preferredWidth, VLCStyle.scale), parent ? parent.width - VLCStyle.dp(32, VLCStyle.scale) : VLCStyle.dp(preferredWidth, VLCStyle.scale))
    height: Math.min(VLCStyle.dp(preferredHeight, VLCStyle.scale), parent ? parent.height - VLCStyle.dp(32, VLCStyle.scale) : VLCStyle.dp(preferredHeight, VLCStyle.scale))
    padding: 0
    parent: T.Overlay.overlay
    anchors.centerIn: parent
    modal: true
    focus: true
    closePolicy: C.Popup.CloseOnEscape
    onOpened: { previousGlobalShortcuts = MainCtx.useGlobalShortcuts; MainCtx.useGlobalShortcuts = false }
    onClosed: MainCtx.useGlobalShortcuts = previousGlobalShortcuts
    background: Rectangle { color: VLCStyle.redesign.color("#191919", "#eeeeee"); radius: VLCStyle.dp(12, VLCStyle.scale) }
    contentItem: Item {
        Rectangle {
            width: parent.width
            height: VLCStyle.dp(49, VLCStyle.scale)
            color: VLCStyle.redesign.color("#090909", "#dedede")
            radius: VLCStyle.dp(12, VLCStyle.scale)
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: parent.height / 2; color: parent.color }
            Text {
                anchors.left: parent.left
                anchors.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                text: root.title
                color: VLCStyle.redesign.color("#8f8f8f", "#494949")
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }
            C.Button {
                objectName: root.objectName + "Close"
                anchors.right: parent.right
                anchors.rightMargin: VLCStyle.dp(12, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                width: VLCStyle.dp(32, VLCStyle.scale)
                height: width
                Accessible.name: qsTr("Close")
                onClicked: root.close()
                background: Rectangle { radius: 4; color: parent.hovered ? VLCStyle.redesign.color("#252525", "#cccccc") : "transparent" }
                contentItem: Image { source: "qrc:///redesign/icons/close/default.png"; sourceSize: Qt.size(20,20); fillMode: Image.PreserveAspectFit }
            }
        }
        C.ScrollView {
            anchors.fill: parent
            anchors.topMargin: VLCStyle.dp(69, VLCStyle.scale)
            anchors.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
            anchors.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
            anchors.bottomMargin: VLCStyle.dp(84, VLCStyle.scale)
            contentWidth: availableWidth
            clip: true
            Loader { width: parent.width; sourceComponent: root.panel }
        }
        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: VLCStyle.dp(20, VLCStyle.scale)
            anchors.bottomMargin: VLCStyle.dp(28, VLCStyle.scale)
            ActionButton { text: qsTr("Cancel"); onClicked: root.close(); Layout.preferredWidth: VLCStyle.dp(100, VLCStyle.scale) }
            Item { Layout.fillWidth: true }
            ActionButton {
                objectName: root.objectName + "Save"
                text: qsTr("Save")
                enabled: root.canSave
                onClicked: root.saveRequested()
                Layout.preferredWidth: VLCStyle.dp(100, VLCStyle.scale)
            }
        }
    }
}
