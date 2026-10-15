/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls.Basic as C
import QtQuick.Controls.impl as Impl
import VLC.Dialogs
import VLC.MainInterface
import VLC.MediaLibrary
import VLC.Player
import VLC.Style

C.Popup {
    id: root
    objectName: "tracksMenu"
    property int currentTab: 0 // subtitle=0, audio=1, video=2; preserve callers
    property var seriesPreset: null
    property bool previousGlobalShortcuts: true
    readonly property bool visiblePanel: visible || subtitleTools.visible
    function dismiss() {
        subtitleTools.close();
        close();
    }
    width: VLCStyle.dp(400, VLCStyle.scale)
    height: VLCStyle.dp(500, VLCStyle.scale)
    padding: 0
    focus: true
    closePolicy: C.Popup.CloseOnEscape | C.Popup.CloseOnPressOutside
    onOpened: {
        subtitleTools.close();
        previousGlobalShortcuts = MainCtx.useGlobalShortcuts;
        MainCtx.useGlobalShortcuts = false;
        PlayerPanelState.reloadCues();
        tabs.focusCurrent();
    }
    onClosed: MainCtx.useGlobalShortcuts = previousGlobalShortcuts
    background: Rectangle {
        radius: VLCStyle.dp(6, VLCStyle.scale)
        color: VLCStyle.redesign.color("#0e0e0e", "#c2c2c1")
    }
    C.Popup {
        id: subtitleTools
        objectName: "subtitleToolsMenu"
        property int preferredHeight: 700
        property bool previousShortcuts: true
        parent: root.parent
        width: root.width
        padding: VLCStyle.dp(20, VLCStyle.scale)
        focus: true
        closePolicy: C.Popup.CloseOnEscape | C.Popup.CloseOnPressOutsideParent
        onOpened: {
            previousShortcuts = MainCtx.useGlobalShortcuts;
            MainCtx.useGlobalShortcuts = false;
        }
        onClosed: MainCtx.useGlobalShortcuts = previousShortcuts
        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: VLCStyle.redesign.color("#0e0e0e", "#c2c2c1")
        }
        contentItem: C.ScrollView {
            id: toolsScroll
            contentWidth: availableWidth
            clip: true
            SubtitleTracksPanel {
                width: toolsScroll.availableWidth
                presets: root.seriesPreset
            }
        }
    }
    contentItem: ColumnLayout {
        spacing: 0
        PanelTabs {
            id: tabs
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            model: [{
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
            currentIndex: 2 - root.currentTab
            onSelected: index => root.currentTab = 2 - index
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
                    spacing: VLCStyle.dp(12, VLCStyle.scale)
                    Text {
                        text: qsTr("Embedded Tracks")
                        color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    }
                    MenuTrackList {
                        Layout.fillWidth: true
                        sourceModel: root.currentTab === 0 ? Player.subtitleTracks : root.currentTab === 1 ? Player.audioTracks : Player.videoTracks
                    }
                    RowLayout {
                        visible: root.currentTab === 0
                        Layout.fillWidth: true
                        spacing: VLCStyle.dp(16, VLCStyle.scale)
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("External Tracks")
                            color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
                            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                        }
                        C.ToolButton {
                            id: editExternal
                            objectName: "playerSubtitleTools"
                            Accessible.name: qsTr("Edit subtitles and series preset")
                            Layout.preferredWidth: VLCStyle.dp(28, VLCStyle.scale)
                            Layout.preferredHeight: VLCStyle.dp(28, VLCStyle.scale)
                            padding: VLCStyle.dp(4, VLCStyle.scale)
                            background: Rectangle {
                                radius: VLCStyle.dp(4, VLCStyle.scale)
                                color: editExternal.hovered || editExternal.visualFocus
                                    ? VLCStyle.redesign.color("#202020", "#dedede") : "transparent"
                            }
                            contentItem: Impl.IconImage {
                                source: "qrc:///redesign/icons/edit/default.png"
                                sourceSize: Qt.size(20, 20)
                                fillMode: Image.PreserveAspectFit
                                color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
                            }
                            enabled: Player.isStarted
                            onClicked: {
                                root.close();
                                root.parent.positionPopup(subtitleTools);
                                subtitleTools.open();
                            }
                        }
                        C.ToolButton {
                            id: addExternal
                            Accessible.name: qsTr("Add subtitles")
                            Layout.preferredWidth: VLCStyle.dp(28, VLCStyle.scale)
                            Layout.preferredHeight: VLCStyle.dp(28, VLCStyle.scale)
                            padding: VLCStyle.dp(4, VLCStyle.scale)
                            background: Rectangle {
                                radius: VLCStyle.dp(4, VLCStyle.scale)
                                color: addExternal.hovered || addExternal.visualFocus
                                    ? VLCStyle.redesign.color("#202020", "#dedede") : "transparent"
                            }
                            contentItem: Impl.IconImage {
                                source: "qrc:///redesign/icons/add/default.png"
                                sourceSize: Qt.size(20, 20)
                                fillMode: Image.PreserveAspectFit
                                color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
                            }
                            onClicked: DialogsProvider.loadSubtitlesFile()
                        }
                    }
                    Repeater {
                        model: root.currentTab === 0 ? PlayerPanelState.subtitleSources : []
                        Text {
                            required property string modelData
                            Layout.fillWidth: true
                            Layout.leftMargin: VLCStyle.dp(40, VLCStyle.scale)
                            text: modelData.split('/').pop()
                            elide: Text.ElideRight
                            color: VLCStyle.redesign.color("#8f8f8f", "#4d4d4d")
                            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                        }
                    }
                    Text {
                        visible: root.currentTab === 1
                        text: qsTr("Output Device")
                        color: VLCStyle.redesign.color("#6b6b6b", "#4d4d4d")
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    }
                    MenuTrackList {
                        visible: root.currentTab === 1
                        Layout.fillWidth: true
                        sourceModel: Player.audioDevices
                        showNone: false
                    }
                }
            }
        }
        PanelAction {
            Layout.fillWidth: true
            Layout.margins: VLCStyle.dp(20, VLCStyle.scale)
            Layout.bottomMargin: VLCStyle.dp(20, VLCStyle.scale)
            implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
            text: qsTr("Show Preferences")
            onClicked: {
                root.close();
                DialogsProvider.prefsDialog();
            }
        }
    }
}
