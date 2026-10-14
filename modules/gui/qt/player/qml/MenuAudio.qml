/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as C
import VLC.Player
import VLC.Playlist
import VLC.Dialogs
import VLC.Style

ColumnLayout {
    id: root
    required property var menu
    readonly property var effects: menu.audioEffects
    property bool expanded: false
    property bool previewWasPaused: false
    property string previewUrl: ""
    spacing: VLCStyle.dp(20, VLCStyle.scale)
    Text {
        text: qsTr("Defaults")
        color: VLCStyle.redesign.color("#8f8f8f", "#4d4d4d")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
    }
    PanelField {
        Layout.fillWidth: true
        label: qsTr("Audio Track")
        controlWidth: VLCStyle.dp(138, VLCStyle.scale)
        controlHeight: VLCStyle.dp(32, VLCStyle.scale)
        PanelChoice {
            anchors.fill: parent
            model: Player.audioTracks
        }
    }
    PanelField {
        Layout.fillWidth: true
        label: qsTr("Audio Language")
        controlWidth: VLCStyle.dp(138, VLCStyle.scale)
        controlHeight: VLCStyle.dp(32, VLCStyle.scale)
        C.TextField {
            anchors.fill: parent
            text: root.menu.defaultValue("audio-language") || qsTr("Any")
            enabled: root.menu.config.hasOption("audio-language")
            onEditingFinished: root.menu.writeDefault("audio-language", text === qsTr("Any") ? "" : text)
            color: VLCStyle.redesign.color("#8f8f8f", "#4d4d4d")
            background: Rectangle {
                color: VLCStyle.redesign.color("#090909", "#dedede")
                radius: VLCStyle.dp(4, VLCStyle.scale)
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: qsTr("Stereo Mode")
            color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }
        C.Button {
            objectName: "playerStereoTest"
            implicitWidth: VLCStyle.dp(84, VLCStyle.scale)
            implicitHeight: VLCStyle.dp(28, VLCStyle.scale)
            text: preview.running ? qsTr("Testing…") : qsTr("Test")
            enabled: Player.isStarted && !preview.running
            background: Rectangle {
                radius: VLCStyle.dp(4, VLCStyle.scale)
                color: parent.hovered ? VLCStyle.redesign.color("#191919", "#ababaa") : VLCStyle.redesign.color("#090909", "#dedede")
            }
            contentItem: Text {
                text: parent.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: VLCStyle.redesign.color("#8f8f8f", "#4d4d4d")
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }
            onClicked: {
                root.previewWasPaused = Player.playingState !== Player.PLAYING_STATE_PLAYING;
                root.previewUrl = Player.url.toString();
                if (root.previewWasPaused)
                    MainPlaylistController.play();
                preview.start();
            }
            C.ToolTip.visible: hovered
            C.ToolTip.text: qsTr("Preview the current audio track in this mode")
        }
    }
    Timer {
        id: preview
        interval: 3000
        onTriggered: if (root.previewWasPaused && root.previewUrl === Player.url.toString() && Player.playingState === Player.PLAYING_STATE_PLAYING)
            MainPlaylistController.pause()
    }
    PanelChoice {
        Layout.fillWidth: true
        model: Player.audioStereoMode
        objectName: "playerStereoMode"
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
        objectName: "playerAudioDelay"
        label: qsTr("Audio Track Delay")
        value: Player.audioDelayMS / 1000
        enabled: Player.isStarted
        onEdited: number => Player.audioDelayMS = Math.round(number * 1000)
    }
    Rectangle {
        Layout.fillWidth: true
        height: VLCStyle.dp(1, VLCStyle.scale)
        color: VLCStyle.redesign.color("#222222", "#8e8e8d")
    }
    Text {
        text: qsTr("Filters")
        color: VLCStyle.redesign.color("#8f8f8f", "#4d4d4d")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
    }
    Text {
        text: qsTr("Equalizer")
        color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    }
    PanelCombo {
        id: preset
        Layout.fillWidth: true
        objectName: "playerEqualizerPreset"
        model: [{
                "name": qsTr("None"),
                "id": ""
            }].concat(root.effects.presets)
        textRole: "name"
        currentIndex: {
            root.effects.preamp;
            root.effects.preset;
            if (!root.effects.filterEnabled("equalizer"))
                return 0;
            return Math.max(0, model.findIndex(p => p.id === root.effects.preset));
        }
        enabled: root.effects.activeAudio && root.effects.filterAvailable("equalizer")
        onActivated: index => {
            if (!root.effects.begin())
                return;
            if (index === 0)
                root.effects.setFilterEnabled("equalizer", false);
            else if (root.effects.setPreset(model[index].id))
                root.effects.setFilterEnabled("equalizer", true);
        }
    }
    PanelAction {
        Layout.fillWidth: true
        arrow: root.expanded ? "chevron-down" : "chevron-right"
        text: root.expanded ? qsTr("Collapse Settings") : qsTr("Expand Settings")
        onClicked: root.expanded = !root.expanded
        palette.buttonText: "#8f8f8f"
    }
    EqualizerPanel {
        Layout.fillWidth: true
        visible: root.expanded
        effects: root.effects
    }
    PanelField {
        Layout.fillWidth: true
        label: qsTr("2 Pass")
        controlWidth: VLCStyle.dp(64, VLCStyle.scale)
        PanelToggle {
            anchors.right: parent.right
            checked: root.effects.twoPass
            enabled: root.effects.activeAudio
            onClicked: {
                if (root.effects.begin())
                    root.effects.setTwoPass(checked);
            }
        }
    }
}
