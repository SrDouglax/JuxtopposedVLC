/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import VLC.Dialogs
import VLC.MainInterface
import VLC.Player
import VLC.Playlist

Item {
    id: root
    SleepTimerController { id: sleepTimer; player: Player; playlist: MainPlaylistController }
    PlayerMenu { id: playerMenu; parent: root; anchors.centerIn: parent }
    SleepTimerMenu { id: timerMenu; parent: root; anchors.centerIn: parent; timerController: sleepTimer }
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
        function onEffectsRequested() { root.show(effects) }
        function onPlayerMenuRequested() { playerMenu.open() }
        function onSleepTimerRequested() { timerMenu.open() }
    }
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
        anchors.fill: parent
        active: false
        source: "qrc:/qt/qml/VLC/Dialogs/EffectsDialog.qml"
        onLoaded: { item.parent = root; item.open() }
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
