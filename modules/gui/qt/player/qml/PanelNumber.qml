/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Controls.Basic as C
import VLC.Style

C.TextField {
    id: root
    property real value: 0
    property real minimum: -10000
    property real maximum: 10000
    property int decimals: 3
    property string suffix: ""
    signal edited(real number)
    text: (suffix === "x" ? String(Number(value)) : Number(value).toFixed(decimals)) + suffix
    selectByMouse: true
    implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
    color: VLCStyle.redesign.color("#8f8f8f", "#2e2e2e")
    font.family: VLCStyle.redesign.fontFamily
    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    onEditingFinished: {
        const number = parseFloat(text);
        if (Number.isFinite(number) && number >= minimum && number <= maximum)
            edited(number);
        text = Qt.binding(() => (suffix === "x" ? String(Number(value)) : Number(value).toFixed(decimals)) + suffix);
    }
    background: Rectangle {
        radius: VLCStyle.dp(4, VLCStyle.scale)
        color: VLCStyle.redesign.color("#090909", "#dedede")
        border.color: root.activeFocus ? VLCStyle.redesign.accent : VLCStyle.redesign.color("#222222", "#8e8e8d")
    }
}
