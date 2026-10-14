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
                    height: implicitHeight
                    spacing: 38
                    Repeater {
                        model: 2
                        delegate: Item {
                            required property int index
                            readonly property int shortcutIndex: shortcutRow.index + index * Math.ceil(root.shortcuts.length / 2)
                            readonly property var shortcut: shortcutIndex < root.shortcuts.length ? root.shortcuts[shortcutIndex] : null
                            readonly property var sequences: shortcut
                                ? shortcut.sequence.split("\t").filter(sequence => sequence.length > 0) : []
                            width: (parent.width - 38) / 2
                            implicitHeight: Math.max(55, keycaps.implicitHeight + 12)
                            height: implicitHeight
                            visible: shortcut !== null
                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - keycaps.width - 16
                                text: parent.shortcut ? parent.shortcut.action : ""
                                color: "#969696"
                                elide: Text.ElideRight
                                font.family: VLCStyle.redesign.fontFamily
                                font.pixelSize: 16
                            }
                            Flow {
                                id: keycaps
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * 0.56
                                spacing: 8
                                Repeater {
                                    model: keycaps.parent.sequences
                                    delegate: Row {
                                        required property int index
                                        required property string modelData
                                        spacing: 8
                                        Text {
                                            visible: index > 0
                                            width: 8
                                            height: 43
                                            text: "/"
                                            color: "#777777"
                                            font.pixelSize: 15
                                            verticalAlignment: Text.AlignVCenter
                                            Accessible.ignored: true
                                        }
                                        Rectangle {
                                            id: keycap
                                            width: Math.min(keycaps.width - (index > 0 ? 16 : 0),
                                                            Math.max(52, keyText.implicitWidth + 28))
                                            height: 43
                                            radius: 12
                                            color: "#1d1d1d"
                                            border.width: 3
                                            border.color: "#383838"
                                            Accessible.role: Accessible.StaticText
                                            Accessible.name: modelData
                                            Text {
                                                id: keyText
                                                anchors.centerIn: parent
                                                width: parent.width - 28
                                                text: modelData
                                                color: "#c6c6c6"
                                                font.family: VLCStyle.redesign.fontFamily
                                                font.pixelSize: 15
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight
                                            }
                                            MouseArea {
                                                id: hover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                acceptedButtons: Qt.NoButton
                                            }
                                            Controls.ToolTip.visible: hover.containsMouse && keyText.truncated
                                            Controls.ToolTip.text: modelData
                                        }
                                    }
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
