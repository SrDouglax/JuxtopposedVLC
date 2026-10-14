/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as C
import VLC.Player
import VLC.Style

ColumnLayout {
    id: root
    required property var menu
    spacing: VLCStyle.dp(18, VLCStyle.scale)
    Text {
        text: qsTr("Defaults")
        color: VLCStyle.redesign.color("#8f8f8f", "#4d4d4d")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
    }
    PanelField {
        controlHeight: VLCStyle.dp(32, VLCStyle.scale)
        Layout.fillWidth: true
        label: qsTr("Subtitle Track")
        controlWidth: VLCStyle.dp(138, VLCStyle.scale)
        PanelChoice {
            objectName: "playerSubtitleTrackChoice"
            anchors.fill: parent
            model: Player.subtitleTracks
        }
    }
    PanelField {
        controlHeight: VLCStyle.dp(32, VLCStyle.scale)
        Layout.fillWidth: true
        label: qsTr("Subtitle Language")
        controlWidth: VLCStyle.dp(138, VLCStyle.scale)
        C.TextField {
            anchors.fill: parent
            text: root.menu.defaultValue("sub-language") || qsTr("Any")
            onEditingFinished: root.menu.writeDefault("sub-language", text === qsTr("Any") ? "" : text)
            color: VLCStyle.redesign.color("#8f8f8f", "#4d4d4d")
            background: Rectangle {
                color: VLCStyle.redesign.color("#090909", "#dedede")
                radius: VLCStyle.dp(4, VLCStyle.scale)
            }
        }
    }
    Rectangle {
        Layout.fillWidth: true
        height: VLCStyle.dp(1, VLCStyle.scale)
        color: VLCStyle.redesign.color("#222222", "#8e8e8d")
    }
    Text {
        text: qsTr("Synchronization")
        color: VLCStyle.redesign.color("#8f8f8f", "#4d4d4d")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
    }
    PanelRange {
        Layout.fillWidth: true
        objectName: "playerSubtitleDelay"
        label: qsTr("Subtitle Track Delay")
        value: Player.subtitleDelayMS / 1000
        enabled: Player.isStarted
        onEdited: number => Player.subtitleDelayMS = Math.round(number * 1000)
    }
    PanelRange {
        Layout.fillWidth: true
        label: qsTr("Subtitle Speed")
        objectName: "playerSubtitleSpeed"
        value: Player.subtitleFPS
        minimum: 0
        maximum: 1000
        suffix: " fps"
        ticks: []
        enabled: Player.isStarted
        onEdited: number => Player.subtitleFPS = number
    }
    PanelRange {
        Layout.fillWidth: true
        label: qsTr("Subtitle Duration Factor")
        minimum: 0
        maximum: 20
        suffix: ""
        ticks: []
        value: Number(root.menu.defaultValue("subsdelay-factor")) || 0
        enabled: root.menu.config.hasOption("subsdelay-factor")
        onEdited: number => root.menu.writeDefault("subsdelay-factor", number)
        HoverHandler {
            id: durationHover
        }
        C.ToolTip.visible: durationHover.hovered
        C.ToolTip.text: qsTr("Default for the subtitle duration filter")
    }
    Rectangle {
        Layout.fillWidth: true
        height: VLCStyle.dp(1, VLCStyle.scale)
        color: VLCStyle.redesign.color("#222222", "#8e8e8d")
    }
    Text {
        text: qsTr("Appearance")
        color: VLCStyle.redesign.color("#8f8f8f", "#4d4d4d")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
    }
    PanelField {
        controlHeight: VLCStyle.dp(32, VLCStyle.scale)
        Layout.fillWidth: true
        label: qsTr("Embedded Sub Format")
        controlWidth: VLCStyle.dp(64, VLCStyle.scale)
        PanelToggle {
            anchors.right: parent.right
            checked: Boolean(root.menu.defaultValue("subsdec-formatted"))
            enabled: root.menu.config.hasOption("subsdec-formatted")
            onClicked: root.menu.writeDefault("subsdec-formatted", checked)
        }
    }
    PanelField {
        controlHeight: VLCStyle.dp(32, VLCStyle.scale)
        Layout.fillWidth: true
        label: qsTr("Subtitle Font")
        controlWidth: VLCStyle.dp(138, VLCStyle.scale)
        C.TextField {
            anchors.fill: parent
            text: root.menu.defaultValue("freetype-font") || ""
            enabled: root.menu.config.hasOption("freetype-font")
            color: VLCStyle.redesign.color("#8f8f8f", "#4d4d4d")
            onEditingFinished: root.menu.writeDefault("freetype-font", text)
            background: Rectangle {
                color: VLCStyle.redesign.color("#090909", "#dedede")
                radius: VLCStyle.dp(4, VLCStyle.scale)
            }
            C.ToolTip.visible: hovered
            C.ToolTip.text: qsTr("Font for newly created subtitle renderers")
        }
    }
    Repeater {
        model: [{
                "label": qsTr("Text Color"),
                "key": "freetype-color"
            }, {
                "label": qsTr("Outline Color"),
                "key": "freetype-outline-color"
            }]
        PanelField {
            controlHeight: VLCStyle.dp(32, VLCStyle.scale)
            required property var modelData
            Layout.fillWidth: true
            label: modelData.label
            controlWidth: VLCStyle.dp(138, VLCStyle.scale)
            C.TextField {
                id: colorField
                anchors.fill: parent
                rightPadding: VLCStyle.dp(40, VLCStyle.scale)
                Rectangle {
                    x: parent.width - width - VLCStyle.dp(12, VLCStyle.scale)
                    anchors.verticalCenter: parent.verticalCenter
                    width: VLCStyle.dp(16, VLCStyle.scale)
                    height: width
                    radius: VLCStyle.dp(2, VLCStyle.scale)
                    color: /^#[0-9a-fA-F]{6}$/.test(colorField.text) ? colorField.text : "transparent"
                    border.color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
                }
                text: "#" + Number(root.menu.defaultValue(modelData.key)).toString(16).padStart(6, "0").toUpperCase()
                enabled: root.menu.config.hasOption(modelData.key)
                color: VLCStyle.redesign.color("#8f8f8f", "#4d4d4d")
                onEditingFinished: if (/^#[0-9a-fA-F]{6}$/.test(text))
                    root.menu.writeDefault(modelData.key, parseInt(text.slice(1), 16))
                background: Rectangle {
                    color: VLCStyle.redesign.color("#090909", "#dedede")
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                }
            }
        }
    }
}
