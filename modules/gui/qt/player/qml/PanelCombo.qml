/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Controls.Basic as C
import QtQuick.Controls.impl as Impl
import VLC.Style

C.ComboBox {
    id: root
    implicitHeight: VLCStyle.dp(44, VLCStyle.scale)
    leftPadding: VLCStyle.dp(12, VLCStyle.scale)
    rightPadding: VLCStyle.dp(34, VLCStyle.scale)
    background: Rectangle {
        radius: VLCStyle.dp(4, VLCStyle.scale)
        color: VLCStyle.redesign.color("#191919", "#ababaa")
        border.color: root.visualFocus ? VLCStyle.redesign.accent : VLCStyle.redesign.color("#222222", "#8e8e8d")
    }
    contentItem: Text {
        text: root.displayText
        verticalAlignment: Text.AlignVCenter
        color: VLCStyle.redesign.color("#8f8f8f", "#2e2e2e")
        opacity: root.enabled ? 1 : 0.45
        elide: Text.ElideRight
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    }
    indicator: Impl.IconImage {
        x: root.width - width - VLCStyle.dp(12, VLCStyle.scale)
        y: (root.height - height) / 2
        width: VLCStyle.dp(16, VLCStyle.scale)
        height: width
        source: "qrc:///redesign/icons/chevron-down/default.png"
        color: VLCStyle.redesign.color("#8f8f8f", "#4d4d4d")
    }
    delegate: C.ItemDelegate {
        required property var model
        required property int index
        width: root.width
        text: root.textRole ? model[root.textRole] : model.modelData
        highlighted: root.highlightedIndex === index
        palette.text: VLCStyle.redesign.color("#eaeaea", "#2e2e2e")
        background: Rectangle {
            color: parent.highlighted ? VLCStyle.redesign.accentBackground : VLCStyle.redesign.color("#191919", "#ababaa")
        }
    }
    popup: C.Popup {
        y: root.height
        width: root.width
        implicitHeight: Math.min(contentItem.implicitHeight, VLCStyle.dp(280, VLCStyle.scale))
        padding: 0
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            C.ScrollBar.vertical: C.ScrollBar {
            }
        }
        background: Rectangle {
            radius: VLCStyle.dp(4, VLCStyle.scale)
            color: VLCStyle.redesign.color("#191919", "#ababaa")
        }
    }
}
