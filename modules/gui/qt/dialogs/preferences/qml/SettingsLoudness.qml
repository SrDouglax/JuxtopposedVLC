/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import VLC.Style

Column {
    id: root
    required property var effects
    objectName: "settingsLoudness"
    property int revision: 0
    property string error: ""
    readonly property var nightPreset: ({
        "compressor-rms-peak": 0.3, "compressor-attack": 20,
        "compressor-release": 250, "compressor-threshold": -20,
        "compressor-ratio": 4, "compressor-knee": 6, "compressor-makeup-gain": 4
    })
    readonly property bool nightEnabled: {
        revision
        if (!effects || !effects.filterEnabled("compressor")) return false
        for (const key of Object.keys(nightPreset))
            if (Math.abs(Number(effects.parameterValue(key)) - nightPreset[key]) > 0.001) return false
        return true
    }
    function compressorState() {
        const state = { enabled: effects.filterEnabled("compressor"), values: {} }
        for (const key of Object.keys(nightPreset)) state.values[key] = effects.parameterValue(key)
        return state
    }
    function applyCompressor(values, enabled) {
        for (const key of Object.keys(values))
            if (!effects.setParameter(key, values[key])) return false
        return effects.setFilterEnabled("compressor", enabled)
    }
    function setNightMode(enabled) {
        error = ""
        const previous = compressorState()
        const target = enabled ? { enabled: true, values: nightPreset }
                               : (effects.nightSnapshot || { enabled: false, values: previous.values })
        if (!applyCompressor(target.values, target.enabled)) {
            const reason = effects.lastError
            const restored = applyCompressor(previous.values, previous.enabled)
            error = reason || qsTr("Night mode could not be applied.")
            if (!restored) error += " " + qsTr("Previous compressor settings could not be restored.")
            return false
        }
        effects.nightSnapshot = enabled ? previous : null
        return true
    }
    readonly property bool available: !!effects && effects.transactionActive && effects.filterAvailable("normvol")
    Connections {
        target: root.effects
        function onStateChanged() {
            ++root.revision
            if (!root.effects.transactionActive) { root.effects.nightSnapshot = null; root.error = "" }
        }
    }
    SettingsOptionRow {
        width: parent.width
        settingKey: "normalize-loudness"
        label: qsTr("Normalize loudness")
        help: root.available ? qsTr("Uses VLC's volume normalizer") : qsTr("Play audio with the volume normalizer module installed to preview this setting")
        enabled: root.available
        settingType: "boolean"
        settingValue: { root.revision; return !!root.effects && root.effects.filterEnabled("normvol") }
        onCommit: value => root.effects.setFilterEnabled("normvol", value)
    }
    SettingsOptionRow {
        width: parent.width
        settingKey: "norm-max-level"
        label: qsTr("Target level")
        help: qsTr("Maximum average power used by VLC's volume normalizer")
        enabled: root.available
        settingType: "float"
        minimum: 0.01
        maximum: 10
        settingValue: { root.revision; return root.effects ? root.effects.parameterValue("norm-max-level") : 2 }
        onCommit: value => root.effects.setParameter("norm-max-level", value)
    }
    SettingsOptionRow {
        width: parent.width
        settingKey: "night-mode"
        label: qsTr("Night mode")
        help: qsTr("Reduces the difference between quiet and loud sounds using VLC’s compressor.")
        enabled: !!root.effects && root.effects.transactionActive && root.effects.filterAvailable("compressor")
        settingType: "boolean"
        settingValue: root.nightEnabled
        onCommit: value => root.setNightMode(value)
    }
    Text {
        width: parent.width
        visible: root.error.length > 0
        text: root.error
        color: VLCStyle.redesign.accent
        wrapMode: Text.WordWrap
        font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
        Accessible.role: Accessible.AlertMessage
    }

}
