/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Controls.Basic as C
import QtQuick.Layouts
import VLC.Style

Column {
    id: root
    required property var settingsModel
    property int revision: 0
    readonly property int pixels: { revision; return Number(settingsModel.valueFor("freetype-absolute-size")) || 0 }
    width: parent.width
    Connections {
        target: root.settingsModel
        function onDataChanged() { ++root.revision }
        function onModelReset() { ++root.revision }
    }
    RowLayout {
        width: parent.width
        height: VLCStyle.dp(46, VLCStyle.scale)
        C.Label {
            Layout.fillWidth: true
            text: qsTr("Size values")
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            color: VLCStyle.redesign.color("#949494", "#494949")
        }
        RowLayout {
            Layout.preferredWidth: Math.min(VLCStyle.dp(320, VLCStyle.scale), root.width * 0.46)
            Layout.maximumWidth: Layout.preferredWidth
            Layout.minimumWidth: 0
            spacing: VLCStyle.dp(2, VLCStyle.scale)
            Repeater {
                model: [qsTr("Relative"), qsTr("Pixels")]
                C.Button {
                    required property string modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: VLCStyle.dp(34, VLCStyle.scale)
                    objectName: "subtitleSizeMode" + index
                    checked: (root.pixels > 0 ? 1 : 0) === index
                    onClicked: {
                        root.settingsModel.setValue("freetype-absolute-size", index === 0 ? 0 : 32)
                        if (index === 1) root.settingsModel.setValue("sub-text-scale", 100)
                    }
                    background: Rectangle { radius: 4; color: parent.checked ? VLCStyle.redesign.accentBackground : VLCStyle.redesign.color("#191919", "#dedede") }
                    contentItem: C.Label {
                        text: modelData
                        color: parent.checked ? VLCStyle.redesign.accent : VLCStyle.redesign.color("#6b6b6b", "#494949")
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    }
                }
            }
        }
    }
    SettingsOptionRow {
        width: parent.width
        settingKey: "subtitle-size"
        label: qsTr("Font size")
        help: qsTr("Default size for FreeType subtitles. Embedded styles can override it.")
        settingType: "integer"
        settingValue: { root.revision; return root.pixels || root.settingsModel.valueFor("sub-text-scale") }
        choices: root.pixels > 0 ? [] : [
            {label: qsTr("Automatic"), value: 100}, {label: "50%", value: 50},
            {label: "75%", value: 75}, {label: "125%", value: 125},
            {label: "150%", value: 150}, {label: "200%", value: 200}
        ]
        onCommit: value => root.settingsModel.setValue(root.pixels > 0 ? "freetype-absolute-size" : "sub-text-scale", value)
    }
}
