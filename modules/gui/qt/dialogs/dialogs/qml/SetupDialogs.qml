/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Templates as T
import VLC.Dialogs
import VLC.MainInterface
import VLC.Player
import VLC.Playlist
import VLC.Style

Item {
    id: root
    SleepTimerController { id: sleepTimer; player: Player; playlist: MainPlaylistController }
    PlayerMenu {
        id: playerMenu
        parent: sourceButton ? sourceButton : root
        closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutsideParent
        property Item sourceButton: null
        readonly property real controlsTop: sourceButton
            ? sourceButton.panelTop : root.height - VLCStyle.dp(80, VLCStyle.scale)
        function updatePosition() {
            x = root.mapToItem(parent, Math.max(0, root.width - width - VLCStyle.dp(20, VLCStyle.scale)), 0).x
            y = sourceButton ? sourceButton.offsetY(height)
                             : Math.max(0, controlsTop - height - VLCStyle.dp(8, VLCStyle.scale))
        }
        width: Math.min(VLCStyle.dp(344, VLCStyle.scale), root.width)
        onHeightChanged: if (visible) updatePosition()
        onVisibleChanged: DialogsProvider.setRedesignDialogVisible("playerMenu", visible)
    }
    SleepTimerMenu { id: timerMenu; parent: root; anchors.centerIn: parent; timerController: sleepTimer }
    AudioVisualizationDialog { id: visualization; parent: root; anchors.centerIn: parent }
    HdrOutputDialog { id: hdr; parent: root; anchors.centerIn: parent }
    OnboardingController {
        id: setupState
        ctx: MainCtx
        onNeedsSetupChanged: if (needsSetup && (!setup.item || !setup.item.visible))
                                 Qt.callLater(() => root.show(setup))
    }
    function show(loader) {
        if (!loader.active) loader.active = true
        else if (loader.item) {
            if (!loader.item.visible) loader.item.open()
        }
    }
    Component.onCompleted: if (setupState.needsSetup) Qt.callLater(() => show(setup))
    Connections {
        target: DialogsProvider
        function onPreferencesRequested() { root.show(preferences) }
        function onSetupRequested() { if (!setup.item || !setup.item.visible) root.show(setup) }
        function onEffectsRequested(page) {
            effects.requestedTab = page
            if (effects.item) effects.item.switchTab(page)
            root.show(effects)
        }
        function onPlayerMenuRequested(source) {
            if (playerMenu.visible) playerMenu.close()
            else {
                playerMenu.sourceButton = source
                playerMenu.updatePosition()
                playerMenu.open()
                Qt.callLater(playerMenu.updatePosition)
            }
        }
        function onSleepTimerRequested() { timerMenu.open() }
        function onAudioVisualizationRequested() { visualization.open() }
        function onHdrOutputRequested() { hdr.open() }
    }
    onWidthChanged: if (playerMenu.visible) Qt.callLater(playerMenu.updatePosition)
    onHeightChanged: if (playerMenu.visible) Qt.callLater(playerMenu.updatePosition)
    Loader {
        id: setup
        anchors.fill: parent
        active: false
        source: "qrc:/qt/qml/VLC/Dialogs/OnboardingDialog.qml"
        onLoaded: { item.parent = root; item.open() }
    }
    Loader {
        id: preferences
        anchors.fill: parent
        active: false
        source: "qrc:/qt/qml/VLC/Dialogs/SettingsDialog.qml"
        onLoaded: { item.parent = root; item.openSettings("general") }
    }
    Loader {
        id: effects
        property int requestedTab: 0
        anchors.fill: parent
        active: false
        source: "qrc:/qt/qml/VLC/Dialogs/EffectsDialog.qml"
        onLoaded: { item.parent = root; item.currentTab = requestedTab; item.open() }
    }
    Connections {
        target: setup.item
        function onVisibleChanged() { DialogsProvider.setRedesignDialogVisible("firstRunDialog", setup.item.visible) }
    }
    Connections {
        target: preferences.item
        function onVisibleChanged() { DialogsProvider.setRedesignDialogVisible("prefsDialog", preferences.item.visible) }
    }
    Connections {
        target: effects.item
        function onVisibleChanged() { DialogsProvider.setRedesignDialogVisible("extendedDialog", effects.item.visible) }
    }
}
