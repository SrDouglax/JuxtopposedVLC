/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as C
import VLC.Dialogs
import VLC.MainInterface
import VLC.Style
import VLC.Player

C.Popup {
    id: root
    objectName: "playerSettingsMenu"
    property int currentTab: 0
    property int preferredHeight: 940
    property var timerController: null
    property alias videoEffects: videoEffects
    property alias audioEffects: audioEffects
    property alias config: config
    property bool previousGlobalShortcuts: true
    readonly property var tabModel: [{
            "title": qsTr("Playback"),
            "icon": "qrc:///redesign/icons/playback/default.png",
            "activeIcon": "qrc:///redesign/icons/playback/active.png"
        }, {
            "title": qsTr("Video"),
            "icon": "qrc:///redesign/icons/video/default.png",
            "activeIcon": "qrc:///redesign/icons/video/active.png"
        }, {
            "title": qsTr("Audio"),
            "icon": "qrc:///redesign/icons/audio/default.png",
            "activeIcon": "qrc:///redesign/icons/audio/active.png"
        }, {
            "title": qsTr("Subtitles"),
            "icon": "qrc:///redesign/icons/subtitles/default.png",
            "activeIcon": "qrc:///redesign/icons/subtitles/active.png"
        }]
    VideoEffects {
        id: videoEffects
        ctx: MainCtx
    }
    AudioEffects {
        id: audioEffects
        ctx: MainCtx
    }
    ConfigModel {
        id: config
        ctx: MainCtx
    }
    property int configRevision: 0
    Connections {
        target: config
        function onDataChanged() {
            ++root.configRevision;
        }
        function onModelReset() {
            ++root.configRevision;
        }
    }
    function defaultValue(key) {
        configRevision;
        return config.valueFor(key);
    }
    function writeDefault(key, value) {
        return config.setValue(key, value) && config.apply();
    }
    function resetCurrent() {
        if (currentTab === 0)
            Player.rate = 1;
        else if (currentTab === 1 && videoEffects.begin()) {
            videoEffects.setFilterEnabled("transform", false);
            videoEffects.setFilterEnabled("rotate", false);
            Player.zoom.toggleIndex(0);
            Player.aspectRatio.toggleIndex(0);
            Player.crop.toggleIndex(0);
        } else if (currentTab === 2) {
            Player.audioDelayMS = 0;
            if (audioEffects.begin())
                audioEffects.resetDefaults("equalizer");
        } else if (currentTab === 3)
            Player.subtitleDelayMS = 0;
    }
    onOpened: {
        previousGlobalShortcuts = MainCtx.useGlobalShortcuts;
        MainCtx.useGlobalShortcuts = false;
        config.reload();
        PlayerPanelState.reloadCues();
        if (videoEffects.activeVideo)
            videoEffects.begin();
        if (audioEffects.activeAudio)
            audioEffects.begin();
        tabs.focusCurrent();
    }
    onClosed: {
        // Keep playback edits; only the preset action writes effect defaults.
        videoEffects.finalizeConfiguration();
        audioEffects.finalizeConfiguration();
        MainCtx.useGlobalShortcuts = previousGlobalShortcuts;
    }
    focus: true
    width: VLCStyle.dp(400, VLCStyle.scale)
    height: VLCStyle.dp(preferredHeight, VLCStyle.scale)
    padding: 0
    closePolicy: C.Popup.CloseOnEscape | C.Popup.CloseOnPressOutside
    background: Rectangle {
        radius: VLCStyle.dp(6, VLCStyle.scale)
        color: VLCStyle.redesign.color("#0e0e0e", "#c2c2c1")
    }
    contentItem: ColumnLayout {
        spacing: 0
        PanelTabs {
            id: tabs
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            model: root.tabModel
            currentIndex: root.currentTab
            onSelected: index => root.currentTab = index
        }
        C.ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ColumnLayout {
                width: scroll.availableWidth
                spacing: 0
                Item {
                    Layout.preferredHeight: VLCStyle.dp(24, VLCStyle.scale)
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: VLCStyle.dp(24, VLCStyle.scale)
                    Layout.rightMargin: VLCStyle.dp(24, VLCStyle.scale)
                    MenuPlayback {
                        Layout.fillWidth: true
                        visible: root.currentTab === 0
                        menu: root
                    }
                    MenuVideo {
                        Layout.fillWidth: true
                        visible: root.currentTab === 1
                        menu: root
                    }
                    MenuAudio {
                        Layout.fillWidth: true
                        visible: root.currentTab === 2
                        menu: root
                    }
                    MenuSubtitles {
                        Layout.fillWidth: true
                        visible: root.currentTab === 3
                        menu: root
                    }
                }
                Item {
                    Layout.preferredHeight: VLCStyle.dp(24, VLCStyle.scale)
                }
            }
        }
        Text {
            Layout.fillWidth: true
            Layout.margins: VLCStyle.dp(12, VLCStyle.scale)
            visible: videoEffects.lastError.length > 0 || audioEffects.lastError.length > 0 || config.error.length > 0
            text: videoEffects.lastError || audioEffects.lastError || config.error
            color: VLCStyle.redesign.accent
            wrapMode: Text.WordWrap
        }
        Rectangle {
            visible: root.currentTab !== 0
            Layout.fillWidth: true
            height: VLCStyle.dp(1, VLCStyle.scale)
            color: VLCStyle.redesign.color("#222222", "#8e8e8d")
        }
        PanelAction {
            id: presetButton
            visible: root.currentTab !== 0
            Layout.fillWidth: true
            Layout.margins: VLCStyle.dp(20, VLCStyle.scale)
            Layout.bottomMargin: VLCStyle.dp(4, VLCStyle.scale)
            text: qsTr("Default Preset")
            arrow: "chevron-up"
            onClicked: presetPopup.open()
            C.Popup {
                id: presetPopup
                parent: presetButton
                y: -implicitHeight - 4
                width: presetButton.width
                closePolicy: C.Popup.CloseOnEscape | C.Popup.CloseOnPressOutsideParent
                background: Rectangle {
                    color: VLCStyle.redesign.color("#191919", "#ababaa")
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                }
                contentItem: Column {
                    PanelAction {
                        width: parent.width
                        text: qsTr("Reset current playback settings")
                        onClicked: {
                            root.resetCurrent();
                            presetPopup.close();
                        }
                    }
                    PanelAction {
                        width: parent.width
                        text: qsTr("Save current settings as default")
                        onClicked: {
                            if (config.applyWithEffects(audioEffects.transactionActive ? audioEffects : null, videoEffects.transactionActive ? videoEffects : null))
                                presetPopup.close();
                        }
                    }
                }
            }
        }
        C.Button {
            visible: root.currentTab !== 0
            Layout.fillWidth: true
            implicitHeight: VLCStyle.dp(42, VLCStyle.scale)
            text: qsTr("Open Advanced Settings")
            onClicked: {
                root.close();
                DialogsProvider.prefsDialog();
            }
            background: Item {
            }
            contentItem: RowLayout {
                Item {
                    Layout.fillWidth: true
                }
                Image {
                    source: "qrc:///redesign/icons/settings/default.png"
                    Layout.preferredWidth: VLCStyle.dp(24, VLCStyle.scale)
                    Layout.preferredHeight: VLCStyle.dp(24, VLCStyle.scale)
                }
                Text {
                    text: parent.parent.text
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
                }
                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
