/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Window
import VLC.Style

RedesignIconButton {
    id: root
    // The factory's context may contain a hidden page. The containing window
    // remains the correct coordinate space even while pages or profiles change.
    readonly property Item popupViewport: root.Window.window ? root.Window.window.contentItem : null
    readonly property Item controlsBar: {
        let item = root.parent
        while (item) {
            if ("inlineTimeline" in item && "sliderY" in item) return item
            item = item.parent
        }
        return null
    }
    readonly property real panelTop: controlsBar
        ? controlsBar.y + controlsBar.parent.mapToItem(popupViewport, 0, 0).y
        : root.mapToItem(popupViewport, 0, 0).y
    property var activePopup: null

    function offsetY(height) {
        return popupViewport.mapToItem(root, 0, panelTop - height - VLCStyle.dp(8, VLCStyle.scale)).y
    }

    function positionPopup(menu) {
        if (!popupViewport || !menu) return
        menu.width = Math.min(VLCStyle.dp(400, VLCStyle.scale), popupViewport.width)
        const top = panelTop
        menu.height = Math.max(0, Math.min(VLCStyle.dp(500, VLCStyle.scale), top - VLCStyle.dp(16, VLCStyle.scale)))
        menu.x = popupViewport.mapToItem(root, Math.max(0, popupViewport.width - menu.width - VLCStyle.dp(20, VLCStyle.scale)), 0).x
        menu.y = offsetY(menu.height)
        activePopup = menu
    }
    Connections {
        target: root.popupViewport
        function onWidthChanged() { Qt.callLater(() => { if (root.activePopup?.visible) root.positionPopup(root.activePopup) }) }
        function onHeightChanged() { Qt.callLater(() => { if (root.activePopup?.visible) root.positionPopup(root.activePopup) }) }
    }
}
