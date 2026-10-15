/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import VLC.Style

ColumnLayout {
    id: root
    required property var effects
    property alias expanded: essential.expanded
    property bool showEssentialLabel: true
    spacing: VLCStyle.dp(20, VLCStyle.scale)
    Text {
        visible: root.showEssentialLabel
        text: qsTr("Essential")
        color: VLCStyle.redesign.color("#6b6b6b", "#494949")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    }
    EffectsSection {
        id: essential
        objectName: "videoEssential"
        Layout.fillWidth: true
        panel: Component { VideoEssential { effects: root.effects } }
    }
    Text {
        text: qsTr("Crop")
        color: VLCStyle.redesign.color("#6b6b6b", "#494949")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    }
    EffectsSection {
        objectName: "videoCrop"
        Layout.fillWidth: true
        contentMargin: 0
        panel: Component { CropPanel { effects: root.effects } }
    }
    Text {
        text: qsTr("Colors")
        color: VLCStyle.redesign.color("#6b6b6b", "#494949")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    }
    EffectsSection {
        objectName: "videoColors"
        Layout.fillWidth: true
        panel: Component { VideoColors { effects: root.effects } }
    }
}
