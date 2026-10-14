/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Controls.Basic as Controls
import VLC.MainInterface
import VLC.Player
import VLC.Style
Controls.Popup {
    id: root
    objectName: "audioVisualizationDialog"
    property string selectedText: qsTr("Disabled")
    property bool previousShortcuts: true
    width: Math.min(VLCStyle.dp(400, VLCStyle.scale), parent.width - 32)
    height: Math.min(VLCStyle.dp(400, VLCStyle.scale), parent.height - 48)
    padding: VLCStyle.dp(20, VLCStyle.scale)
    focus: true
    closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside
    onOpened: { previousShortcuts = MainCtx.useGlobalShortcuts; MainCtx.useGlobalShortcuts = false }
    onClosed: MainCtx.useGlobalShortcuts = previousShortcuts
    background: Rectangle { color: VLCStyle.redesign.color("#191919", "#c2c2c1"); radius: 6 }
    contentItem: Column {
        spacing: VLCStyle.dp(8, VLCStyle.scale)
        Rectangle {
            width: parent.width
            height: VLCStyle.dp(46, VLCStyle.scale)
            color: VLCStyle.redesign.color("#222222", "#ababaa")
            radius: 4
            Text {
                anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter
                text: root.selectedText
                color: VLCStyle.redesign.color("#969696", "#4d4d4d")
                font.family: VLCStyle.redesign.fontFamily; font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }
            Image {
                anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                source: "qrc:///redesign/icons/chevron-down/default.png"; width: 24; height: 24
            }
        }
        ListView {
            id: options
            objectName: "audioVisualizationModes"
            width: parent.width
            height: root.availableHeight - VLCStyle.dp(54, VLCStyle.scale)
            clip: true
            model: Player.audioVisualization
            Controls.ScrollBar.vertical: Controls.ScrollBar {}
            delegate: Controls.ItemDelegate {
                id: row
                required property int index
                required property var model
                checked: model.checked
                width: options.width
                height: VLCStyle.dp(46, VLCStyle.scale)
                text: index === 0 ? qsTr("Disabled") : model.display
                Component.onCompleted: if (checked) root.selectedText = text
                onCheckedChanged: if (checked) root.selectedText = text
                onClicked: Player.audioVisualization.toggleIndex(index)
                background: Rectangle {
                    color: row.hovered || row.checked ? VLCStyle.redesign.color("#222222", "#ababaa") : "transparent"
                    radius: 4
                    border.color: row.visualFocus ? VLCStyle.redesign.accent : "transparent"
                }
                contentItem: Row {
                    spacing: 10
                    Image {
                        width: row.index === 0 ? 0 : 24; height: 24
                        anchors.verticalCenter: parent.verticalCenter
                        source: row.index === 0 ? "" : "qrc:///redesign/icons/" +
                            (row.model.display.toLowerCase().includes("spectrometer") ? "spectrometer" :
                             row.model.display.toLowerCase().includes("spectrum") ? "spectrum" :
                             row.model.display.toLowerCase().includes("scope") ? "scope" : "waveform") + "/default.png"
                    }
                    Text {
                        width: row.width - 78; height: parent.height; verticalAlignment: Text.AlignVCenter
                        text: row.text; color: VLCStyle.redesign.color("#969696", "#4d4d4d")
                        font.family: VLCStyle.redesign.fontFamily; font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    }
                    Image { width: 24; height: 24; anchors.verticalCenter: parent.verticalCenter
                        source: "qrc:///redesign/icons/check/selected.png"; visible: row.checked }
                }
            }
            Text {
                anchors.fill: parent
                visible: options.count === 0
                text: qsTr("Play audio to select a visualization.")
                color: VLCStyle.redesign.textSecondary
                wrapMode: Text.WordWrap
                font.family: VLCStyle.redesign.fontFamily; font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }
        }
    }
}
