import QtQuick
import QtQuick.Controls.Basic as Controls

import VLC.Style

Item {
    id: root
    property var shortcuts: []

    Text {
        y: 66
        width: parent.width
        text: qsTr("Learn the basic keyboard shortcuts.")
        color: "#969696"
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: 24
        font.weight: Font.Light
        horizontalAlignment: Text.AlignHCenter
    }

    Text {
        anchors.centerIn: parent
        visible: root.shortcuts.length === 0
        text: qsTr("No playback shortcuts are currently assigned.")
        color: "#969696"
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: 16
    }

    Controls.ScrollView {
        x: 62
        y: 144
        width: parent.width - 124
        height: 490
        clip: true
        visible: root.shortcuts.length > 0
        contentWidth: availableWidth
        Column {
            width: parent.width
            spacing: 14
            Repeater {
                model: Math.ceil(root.shortcuts.length / 2)
                delegate: Row {
                    id: shortcutRow
                    required property int index
                    width: parent.width
                    height: 55
                    spacing: 38
                    Repeater {
                        model: 2
                        delegate: Item {
                            required property int index
                            readonly property int shortcutIndex: shortcutRow.index + index * Math.ceil(root.shortcuts.length / 2)
                            readonly property var shortcut: shortcutIndex < root.shortcuts.length ? root.shortcuts[shortcutIndex] : null
                            width: (parent.width - 38) / 2
                            height: 55
                            visible: shortcut !== null
                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * 0.53
                                text: parent.shortcut ? parent.shortcut.action : ""
                                color: "#969696"
                                elide: Text.ElideRight
                                font.family: VLCStyle.redesign.fontFamily
                                font.pixelSize: 16
                            }
                            Rectangle {
                                id: keycap
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.max(52, Math.min(parent.width * 0.44, keyText.implicitWidth + 28))
                                height: 43
                                radius: 12
                                color: "#1d1d1d"
                                border.width: 3
                                border.color: "#383838"
                                Text {
                                    id: keyText
                                    anchors.centerIn: parent
                                    text: keycap.parent.shortcut ? keycap.parent.shortcut.sequence : ""
                                    color: "#c6c6c6"
                                    font.family: VLCStyle.redesign.fontFamily
                                    font.pixelSize: 15
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Text {
        x: 62
        y: 677
        text: qsTr("Find the full list in the menu.")
        color: "#777777"
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: 16
    }
}
