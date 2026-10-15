/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import VLC.Style

SettingsOptionRow {
    id: root
    required property var settingsModel
    required property string kind
    property int revision: 0
    property bool customBuffering: false
    signal bufferingModeChanged(bool custom)
    implicitHeight: VLCStyle.dp(tickedSlider ? 64 : 46, VLCStyle.scale)
    settingKey: "composite_" + kind
    settingType: kind === "hideafter" ? "float" : "integer"
    editorKind: kind === "hideafter" ? "slider" : ""
    minimum: 0
    maximum: 10
    readonly property var caches: ["file-caching", "disc-caching", "network-caching", "live-caching"]
    readonly property var presets: [[300, 300, 1000, 300], [100, 100, 300, 100], [1000, 1000, 3000, 1000]]
    function value(key) { revision; return settingsModel.valueFor(key) }
    function write(key, number) { return settingsModel.setValue(key, number) }
    function bufferIndex() {
        revision
        if (customBuffering) return 3
        for (let i = 0; i < presets.length; ++i)
            if (caches.every((key, j) => Number(value(key)) === presets[i][j])) return i
        return 3
    }
    Connections {
        target: root.settingsModel
        function onDataChanged() { ++root.revision }
        function onModelReset() { ++root.revision }
    }
    label: ({repeat: qsTr("Repeat"), finished: qsTr("When playback finishes"),
             buffering: qsTr("Buffering"), hardware: qsTr("Hardware-accelerated decoding"), artwork: qsTr("Fetch titles and artwork"),
             resume: qsTr("Continue where you left off"), resize: qsTr("Resize window to fit video"), hideafter: qsTr("Hide after"), autohide: qsTr("Auto-hide the controls"), screen: qsTr("Open fullscreen on")})[kind] || ""
    choices: {
        const titles = ({repeat: [qsTr("Off"), qsTr("Current item"), qsTr("Playlist")],
                         finished: [qsTr("Stop"), qsTr("Pause on the last frame"), qsTr("Quit VLC")],
                         hardware: [qsTr("Automatic"), qsTr("Disabled")], buffering: [qsTr("Normal"), qsTr("Low latency"), qsTr("High"), qsTr("Custom")],
                         artwork: [qsTr("From the file only"), qsTr("From the file and internet")],
                         autohide: [qsTr("Always"), qsTr("In fullscreen only")], resize: [qsTr("Never"), qsTr("Always")]})[kind]
        if (kind === "screen") return settingsModel.screenChoices()
        if (kind === "resume") return settingsModel.optionFor("restore-playback-pos").choices || []
        return (titles || []).map((label, value) => ({label, value}))
    }
    settingValue: {
        revision
        switch (kind) {
        case "repeat": return value("repeat") ? 1 : value("loop") ? 2 : 0
        case "finished": return value("play-and-exit") ? 2 : value("play-and-pause") ? 1 : 0
        case "buffering": return bufferIndex()
        case "hardware": return value("hw-dec") ? 0 : 1
        case "artwork": return value("metadata-network-access") ? 1 : 0
        case "resume": return value("restore-playback-pos")
        case "resize": return value("qt-video-autoresize") ? 1 : 0
        case "hideafter": return Number(value("mouse-hide-timeout")) / 1000
        case "autohide": return value("qt-pin-controls") ? 1 : 0
        case "screen": return value("qt-fullscreen-screennumber")
        }
        return 0
    }
    enabled: {
        revision
        if (kind === "buffering") return caches.every(key => settingsModel.hasOption(key))
        if (kind === "hardware") return settingsModel.hasOption("hw-dec")
        return settingsModel.hasOption(({repeat: "repeat", finished: "play-and-pause", artwork: "metadata-network-access", resume: "restore-playback-pos", resize: "qt-video-autoresize", hideafter: "mouse-hide-timeout", autohide: "qt-pin-controls", screen: "qt-fullscreen-screennumber"})[kind] || "")
    }
    onCommit: number => {
        switch (kind) {
        case "repeat": write("repeat", number === 1); write("loop", number === 2); break
        case "hardware": write("hw-dec", number === 0); break
        case "finished": write("play-and-pause", number === 1); write("play-and-exit", number === 2); break
        case "buffering":
            customBuffering = number === 3
            bufferingModeChanged(customBuffering)
            if (number < 3) caches.forEach((key, i) => write(key, presets[number][i]))
            break
        case "artwork": write("metadata-network-access", number === 1); break
        case "resume": write("restore-playback-pos", number); break
        case "resize": write("qt-video-autoresize", number === 1); break
        case "hideafter": write("mouse-hide-timeout", Math.round(number * 1000)); break
        case "autohide": write("qt-pin-controls", number === 1); break
        case "screen": write("qt-fullscreen-screennumber", number); break
        }
    }
}
