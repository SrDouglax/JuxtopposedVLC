/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import QtQuick.Controls.impl as Impl
import VLC.Style

Item {
    id: root
    required property var model
    property int currentIndex: 0
    signal selected(int index)
    implicitHeight: VLCStyle.dp(50, VLCStyle.scale)
    function focusCurrent() {
        tabs.itemAt(currentIndex)?.forceActiveFocus();
    }
    Row {
        anchors.fill: parent
        Repeater {
            id: tabs
            model: root.model
            T.Button {
                id: button
                required property int index
                required property var modelData
                objectName: "panelTab" + index
                width: root.width / tabs.count
                height: root.height
                text: modelData.title
                checked: root.currentIndex === index
                focusPolicy: Qt.StrongFocus
                onClicked: root.selected(index)
                background: Rectangle {
                    radius: VLCStyle.dp(6, VLCStyle.scale)
                    color: button.hovered ? VLCStyle.redesign.color("#191919", "#ababaa") : VLCStyle.redesign.color("#090909", "#bcbcbc")
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: parent.height / 2
                        color: parent.color
                    }
                    Rectangle {
                        x: button.index === 0 ? VLCStyle.dp(6, VLCStyle.scale) : 0
                        width: parent.width - (button.index === 0 || button.index === tabs.count - 1 ? VLCStyle.dp(6, VLCStyle.scale) : 0)
                        height: parent.height
                        color: parent.color
                    }
                    Rectangle {
                        anchors {
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                        width: parent.width - VLCStyle.dp(28, VLCStyle.scale)
                        height: VLCStyle.dp(2, VLCStyle.scale)
                        visible: button.checked
                        color: VLCStyle.redesign.accent
                    }
                }
                contentItem: RowLayout {
                    spacing: VLCStyle.dp(6, VLCStyle.scale)
                    Item {
                        Layout.fillWidth: true
                    }
                    Impl.IconImage {
                        Layout.preferredWidth: VLCStyle.dp(24, VLCStyle.scale)
                        Layout.preferredHeight: Layout.preferredWidth
                        source: button.checked && button.modelData.activeIcon ? button.modelData.activeIcon : button.modelData.icon
                        color: button.modelData.activeIcon && VLCStyle.palette.isDark ? "transparent" : button.checked ? VLCStyle.redesign.accent : VLCStyle.redesign.color("#8f8f8f", "#4d4d4d")
                        sourceSize: Qt.size(24, 24)
                        fillMode: Image.PreserveAspectFit
                    }
                    Text {
                        text: button.text
                        color: VLCStyle.redesign.color("#8f8f8f", "#4d4d4d")
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: VLCStyle.dp(tabs.count === 4 ? 12 : 14, VLCStyle.scale)
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
