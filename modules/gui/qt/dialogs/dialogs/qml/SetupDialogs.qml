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
        timerController: sleepTimer
        parent: sourceButton ? sourceButton : root
        closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutsideParent
        property Item sourceButton: null
        readonly property real controlsTop: sourceButton
            ? sourceButton.panelTop : root.height - VLCStyle.dp(80, VLCStyle.scale)
        function updatePosition() {
            if (sourceButton) { sourceButton.positionPopup(playerMenu); return }
            height = Math.max(0, Math.min(VLCStyle.dp(preferredHeight, VLCStyle.scale), controlsTop - VLCStyle.dp(16, VLCStyle.scale)))
            x = root.mapToItem(parent, Math.max(0, root.width - width - VLCStyle.dp(20, VLCStyle.scale)), 0).x
            y = sourceButton ? sourceButton.offsetY(height)
                             : Math.max(0, controlsTop - height - VLCStyle.dp(8, VLCStyle.scale))
        }
        width: Math.min(VLCStyle.dp(400, VLCStyle.scale), root.width)
        onHeightChanged: if (visible) updatePosition()
        onVisibleChanged: {
            if (sourceButton) sourceButton.panelOpen = visible
            DialogsProvider.setRedesignDialogVisible("playerMenu", visible)
        }
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
    function togglePlayerMenu(source, page) {
        const sameSource = playerMenu.sourceButton === source
        if (playerMenu.visible) {
            playerMenu.close()
            if (sameSource) return
        }
        playerMenu.sourceButton = source
        if (page >= 0) playerMenu.showEffects(page)
        playerMenu.updatePosition()
        playerMenu.open()
        Qt.callLater(playerMenu.updatePosition)
    }
    Component.onCompleted: { PlayerPanelState.player = Player; if (setupState.needsSetup) Qt.callLater(() => show(setup)) }
    Connections {
        target: DialogsProvider
        function onPreferencesRequested() { root.show(preferences) }
        function onNetworkRequested() { root.show(network) }
        function onSetupRequested() { if (!setup.item || !setup.item.visible) root.show(setup) }
        function onEffectsRequested(page) {
            root.togglePlayerMenu(null, page === 1 ? 1 : 2)
        }
        function onPlayerMenuRequested(source, page) { root.togglePlayerMenu(source, page) }
        function onSleepTimerRequested() { timerMenu.open() }
        function onAudioVisualizationRequested() { visualization.open() }
        function onHdrOutputRequested() { hdr.open() }
    }
    PlaybackFeedback { anchors.fill: parent }
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
        id: network
        active: false
        source: "qrc:/qt/qml/VLC/Dialogs/NetworkDialog.qml"
        onLoaded: item.open()
    }
    Connections {
        target: setup.item
        function onVisibleChanged() { DialogsProvider.setRedesignDialogVisible("firstRunDialog", setup.item.visible) }
    }
    Connections {
        target: preferences.item
        function onVisibleChanged() { DialogsProvider.setRedesignDialogVisible("prefsDialog", preferences.item.visible) }
    }
}
