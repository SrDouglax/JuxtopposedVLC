/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as C
import VLC.Player
import VLC.MainInterface
import VLC.Dialogs
import VLC.Style

ColumnLayout {
    id: root
    required property var menu
    readonly property var effects: menu.videoEffects
    property alias expanded: videoFilters.expanded
    property alias effectsHeading: effectsHeading
    spacing: VLCStyle.dp(20, VLCStyle.scale)
    Text {
        text: qsTr("Defaults")
        color: VLCStyle.redesign.color("#8f8f8f", "#4d4d4d")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
    }
    Text {
        text: qsTr("Flip")
        color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: VLCStyle.dp(2, VLCStyle.scale)
        Repeater {
            model: [{
                    "title": qsTr("None"),
                    "value": ""
                }, {
                    "title": qsTr("Horizontal"),
                    "value": "hflip"
                }, {
                    "title": qsTr("Vertical"),
                    "value": "vflip"
                }]
            C.Button {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: VLCStyle.dp(40, VLCStyle.scale)
                objectName: "playerFlip-" + modelData.value
                text: modelData.title
                enabled: root.effects.activeVideo && root.effects.filterAvailable("transform")
                checked: {
                    root.effects.revision;
                    const value = root.effects.filterEnabled("transform") ? root.effects.parameterValue("transform-type") : "";
                    return value === modelData.value;
                }
                onClicked: {
                    if (!root.effects.begin())
                        return;
                    if (!modelData.value)
                        root.effects.setFilterEnabled("transform", false);
                    else if (root.effects.setParameter("transform-type", modelData.value))
                        root.effects.setFilterEnabled("transform", true);
                }
                background: Rectangle {
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    color: parent.checked ? VLCStyle.redesign.accentBackground : VLCStyle.redesign.color("#191919", "#ababaa")
                    border.color: VLCStyle.redesign.color("#222222", "#8e8e8d")
                }
                contentItem: Text {
                    text: parent.text
                    color: parent.checked ? VLCStyle.redesign.accent : VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                }
            }
        }
    }
    PanelField {
        Layout.fillWidth: true
        label: qsTr("Rotate")
        controlWidth: VLCStyle.dp(138, VLCStyle.scale)
        PanelNumber {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            objectName: "playerRotate"
            value: {
                root.effects.revision;
                return Number(root.effects.parameterValue("rotate-angle")) || 0;
            }
            minimum: 0
            maximum: 359
            decimals: 0
            suffix: " deg"
            enabled: root.effects.activeVideo && root.effects.filterAvailable("rotate")
            onEdited: number => {
                if (root.effects.begin() && root.effects.setParameter("rotate-angle", number))
                    root.effects.setFilterEnabled("rotate", number !== 0);
            }
        }
    }
    PanelField {
        Layout.fillWidth: true
        label: qsTr("Zoom")
        PanelChoice {
            anchors.fill: parent
            objectName: "playerZoom"
            model: Player.zoom
        }
    }
    HdrOutput {
        id: hdr
        ctx: MainCtx
    }
    PanelField {
        Layout.fillWidth: true
        label: qsTr("HDR")
        PanelCombo {
            anchors.fill: parent
            model: hdr.choices
            textRole: "label"
            currentIndex: hdr.selectedIndex
            displayText: hdr.available ? currentText : qsTr("Unavailable")
            enabled: hdr.available
            onActivated: index => hdr.select(index)
            C.ToolTip.visible: hovered && !enabled
            C.ToolTip.text: hdr.message
        }
    }
    PanelField {
        Layout.fillWidth: true
        label: qsTr("Resolution")
        PanelCombo {
            anchors.fill: parent
            model: [qsTr("Best Available"), "1080p", "720p", "480p", "360p"]
            readonly property var values: [-1, 1080, 720, 480, 360]
            currentIndex: Math.max(0, values.indexOf(Number(root.menu.defaultValue("preferred-resolution"))))
            enabled: root.menu.config.hasOption("preferred-resolution") && !Player.url.toString().startsWith("file:")
            onActivated: index => root.menu.writeDefault("preferred-resolution", values[index])
            C.ToolTip.visible: hovered
            C.ToolTip.text: qsTr("Preferred quality when opening adaptive streams")
        }
    }
    PanelField {
        Layout.fillWidth: true
        label: qsTr("Aspect Ratio")
        PanelChoice {
            anchors.fill: parent
            model: Player.aspectRatio
        }
    }
    PanelField {
        Layout.fillWidth: true
        label: qsTr("Crop")
        PanelChoice {
            anchors.fill: parent
            model: Player.crop
        }
    }
    PanelField {
        Layout.fillWidth: true
        label: qsTr("Render")
        MenuRenderer {
            anchors.fill: parent
        }
    }
    Rectangle {
        Layout.fillWidth: true
        height: VLCStyle.dp(1, VLCStyle.scale)
        color: VLCStyle.redesign.color("#222222", "#8e8e8d")
    }
    Text {
        id: effectsHeading
        text: qsTr("Filters")
        color: VLCStyle.redesign.color("#8f8f8f", "#4d4d4d")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
    }
    Text {
        text: qsTr("Essential")
        color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    }
    VideoEffectsPanel {
        id: videoFilters
        showEssentialLabel: false
        Layout.fillWidth: true
        effects: root.effects
    }
}
