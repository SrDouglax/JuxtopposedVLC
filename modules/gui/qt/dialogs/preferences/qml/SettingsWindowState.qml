/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import VLC.MainInterface

QtObject {
    required property var settingsModel
    property bool initial: false
    property bool selected: false
    readonly property bool dirty: selected !== initial
    function begin() { initial = MainCtx.interfaceAlwaysOnTop; selected = initial }
    function preview(value) { selected = value; settingsModel.setValue("video-on-top", value); MainCtx.interfaceAlwaysOnTop = value }
    function save() { initial = selected }
    function cancel() { if (dirty) preview(initial) }
}
