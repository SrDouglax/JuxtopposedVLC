import QtQuick
import QtQuick.Controls.Basic as Controls

import VLC.Style

Item {
    id: root
    property int themeIndex: 0
    property color accent: "#d37918"
    signal themeRequested(int index)
    signal accentRequested(color colorValue)

    readonly property var accentChoices: [
        "#d37918", "#8d3525", "#826a1d", "#17652e", "#136b83",
        "#1d4689", "#65318d", "#823760", "#707070"
    ]

    Text {
        y: 180
        width: parent.width
        text: qsTr("Select your preferred theme and color.")
        color: "#969696"
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: 24
        font.weight: Font.Light
        horizontalAlignment: Text.AlignHCenter
    }

    Row {
        y: 278
        spacing: 46
        anchors.horizontalCenter: parent.horizontalCenter
        Repeater {
            model: [
                { title: qsTr("Light"), index: 1 },
                { title: qsTr("Dark"), index: 2 },
                { title: qsTr("System"), index: 0 }
            ]
            delegate: Item {
                required property var modelData
                width: 110
                height: 160
                Rectangle {
                    x: 0
                    y: 0
                    width: 110
                    height: 110
                    radius: 22
                    color: "transparent"
                    border.width: root.themeIndex === modelData.index ? 4 : 0
                    border.color: root.accent
                    Rectangle {
                        x: 11
                        y: 11
                        width: 88
                        height: 88
                        radius: 11
                        color: modelData.index === 1 ? "#b0b0b0" : "#202020"
                        clip: true
                        Canvas {
                            anchors.fill: parent
                            visible: modelData.index === 0
                            onPaint: {
                                const context = getContext("2d")
                                context.fillStyle = "#b0b0b0"
                                context.beginPath()
                                context.moveTo(width * 0.17, 0)
                                context.lineTo(width, 0)
                                context.lineTo(width, height)
                                context.closePath()
                                context.fill()
                            }
                        }
                    }
                }
                Text {
                    y: 142
                    width: parent.width
                    text: modelData.title
                    color: "#8f8f8f"
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                }
                Controls.Button {
                    anchors.fill: parent
                    background: Item {}
                    contentItem: Item {}
                    Accessible.name: modelData.title
                    onClicked: root.themeRequested(modelData.index)
                }
            }
        }
    }

    // A decorative sample shows the chosen accent without suggesting media is playing.
    Rectangle {
        x: 16
        y: 568
        width: parent.width - 32
        height: 42
        color: root.themeIndex === 1 ? "#dedede" : "#1b1b1b"
        Rectangle {
            x: 22
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 20
            radius: 4
            color: root.accent
        }
        Rectangle {
            x: 70
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 92
            height: 6
            radius: 3
            color: root.themeIndex === 1 ? "#a0a0a0" : "#343434"
            Rectangle {
                width: parent.width * 0.28
                height: parent.height
                radius: parent.radius
                color: root.accent
            }
        }
    }

    Row {
        x: 52
        y: 660
        spacing: 27
        Repeater {
            model: root.accentChoices
            delegate: Item {
                required property int index
                required property var modelData
                width: 53
                height: 53
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.width: root.accent.toString().toLowerCase() === modelData ? 4 : 0
                    border.color: modelData
                    Rectangle {
                        anchors.centerIn: parent
                        width: 40
                        height: 40
                        radius: 20
                        color: modelData
                    }
                }
                Controls.Button {
                    anchors.fill: parent
                    background: Item {}
                    contentItem: Item {}
                    Accessible.name: qsTr("Accent color %1").arg(index + 1)
                    onClicked: root.accentRequested(modelData)
                }
            }
        }
    }
}
