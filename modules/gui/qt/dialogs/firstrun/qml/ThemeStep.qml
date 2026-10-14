import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Controls.impl as Impl

import VLC.Style

Item {
    id: root
    property int themeIndex: 0
    property color accent: "#d37918"
    signal themeRequested(int index)
    signal accentRequested(color colorValue)

    readonly property var accentChoices: VLCStyle.redesign.accentChoices
    readonly property bool darkPreview: themeIndex === 2
                                        || (themeIndex === 0 && VLCStyle.palette.isDark)
    readonly property color previewChrome: VLCStyle.redesign.color(
        VLCStyle.redesign.playerControlBackground, "#ababaa", darkPreview)
    readonly property color previewForeground: VLCStyle.redesign.color(
        darkPreview ? VLCStyle.redesign.textMuted : VLCStyle.redesign.textSecondary,
        "#4d4d4d", darkPreview)

    component PreviewIcon: Impl.IconImage {
        width: 12
        height: 12
        anchors.verticalCenter: parent.verticalCenter
        color: root.previewForeground
        Accessible.ignored: true
    }

    component PreviewTime: Text {
        width: 42
        anchors.verticalCenter: parent.verticalCenter
        color: root.previewForeground
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: 8
        Accessible.ignored: true
    }

    // A miniature window previews appearance only; it never controls playback.
    Rectangle {
        id: preview
        x: 16
        y: 18
        width: parent.width - 32
        height: 594
        color: root.darkPreview ? "#090909" : "#dedede"
        Accessible.role: Accessible.StaticText
        Accessible.name: qsTr("Player appearance preview")

        Rectangle {
            width: parent.width
            height: 22
            color: root.previewChrome

            PreviewIcon {
                x: 6
                source: "qrc:/redesign/logo.svg"
                color: root.accent
            }
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 6
                height: parent.height
                spacing: 8
                Repeater {
                    model: ["minimize", "maximize", "fullscreen", "close"]
                    delegate: PreviewIcon {
                        required property string modelData
                        source: "qrc:/redesign/" + modelData + ".svg"
                    }
                }
            }
        }

        Rectangle {
            id: controlsPreview
            anchors.bottom: parent.bottom
            width: parent.width
            height: 30
            color: root.previewChrome

            Row {
                x: 12
                height: parent.height
                spacing: 10

                PreviewIcon {
                    width: 10
                    source: "qrc:/redesign/previous.svg"
                }
                Rectangle {
                    width: 30
                    height: 16
                    radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.accent
                    PreviewIcon {
                        anchors.centerIn: parent
                        source: "qrc:/redesign/play.svg"
                        color: "#090909"
                    }
                }
                PreviewIcon {
                    width: 10
                    source: "qrc:/redesign/next.svg"
                }
                PreviewTime { width: 36; text: "00:02:10" }

                Rectangle {
                    width: controlsPreview.width - 376
                    height: 16
                    radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: VLCStyle.redesign.color(
                        VLCStyle.redesign.seekBackground, "#dedede", root.darkPreview)
                    Rectangle {
                        width: parent.width * (130 / 1540)
                        height: parent.height
                        radius: parent.radius
                        color: Qt.tint(parent.color,
                                       Qt.rgba(root.accent.r, root.accent.g,
                                               root.accent.b, 0.3))
                    }
                    Rectangle {
                        x: parent.width * (130 / 1540) - width / 2
                        width: 4
                        height: parent.height
                        radius: 2
                        color: root.accent
                    }
                }

                PreviewTime { text: "00:25:40" }
                Row {
                    width: 66
                    height: parent.height
                    spacing: 6
                    PreviewIcon {
                        source: "qrc:/redesign/volume-medium.png"
                    }
                    Item {
                        width: 48
                        height: 16
                        anchors.verticalCenter: parent.verticalCenter
                        Impl.IconImage {
                            anchors.fill: parent
                            source: "qrc:/redesign/volume-background.svg"
                            color: VLCStyle.redesign.color(
                                VLCStyle.redesign.seekBackground, "#dedede", root.darkPreview)
                        }
                        Item {
                            x: 1
                            y: 1
                            width: 18
                            height: 14
                            clip: true
                            Image {
                                width: 46
                                height: 14
                                source: "qrc:/redesign/volume-fill.svg"
                            }
                        }
                    }
                }
                Row {
                    width: 88
                    height: parent.height
                    spacing: 12
                    Repeater {
                        model: ["equalizer", "subtitles", "player-settings", "queue"]
                        delegate: PreviewIcon {
                            required property string modelData
                            source: "qrc:/redesign/" + modelData + ".svg"
                        }
                    }
                }
            }
        }
    }

    Text {
        y: 180
        width: parent.width
        text: qsTr("Select your preferred theme and color.")
        color: VLCStyle.redesign.color(VLCStyle.redesign.textSecondary,
                                       "#4d4d4d", root.darkPreview)
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
                    color: root.previewForeground
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
