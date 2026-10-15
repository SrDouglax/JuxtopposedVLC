/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick

SettingsOptionRow {
    id: root
    required property var settingsModel
    property int revision: 0
    settingKey: "web-remote"
    label: qsTr("Web remote control")
    help: qsTr("Uses VLC's HTTP interface after restart. Set a password below before enabling it.")
    settingType: "boolean"
    enabled: settingsModel.moduleAvailable("lua") || settingsModel.moduleAvailable("luahttp")
    settingValue: {
        revision
        const names = String(settingsModel.valueFor("extraintf") || "").split(":")
        return names.includes("http") || names.includes("luahttp")
    }
    onCommit: value => {
        const names = String(settingsModel.valueFor("extraintf") || "").split(":").filter(name => name && name !== "http" && name !== "luahttp")
        if (value) names.push("http")
        settingsModel.setValue("extraintf", names.join(":"))
    }
    Connections {
        target: root.settingsModel
        function onDataChanged() { ++root.revision }
        function onModelReset() { ++root.revision }
    }
}
