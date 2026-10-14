/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import VLC.Player

PanelCombo {
    id: root
    property int revision: 0
    model: {
        revision;
        const names = [qsTr("Local")];
        for (let i = 0; i < rows.count; ++i)
            names.push(Player.rendererManager.data(Player.rendererManager.index(i, 0), Qt.UserRole));
        return names;
    }
    currentIndex: {
        revision;
        if (!Player.rendererManager.useRenderer)
            return 0;
        for (let i = 0; i < rows.count; ++i)
            if (Player.rendererManager.data(Player.rendererManager.index(i, 0), Qt.CheckStateRole) === Qt.Checked)
                return i + 1;
        return 0;
    }
    onActivated: index => {
        if (index === 0)
            Player.rendererManager.disableRenderer();
        else
            Player.rendererManager.setData(Player.rendererManager.index(index - 1, 0), true, Qt.CheckStateRole);
    }
    Repeater {
        id: rows
        model: Player.rendererManager
        delegate: Item {
            visible: false
        }
    }
    Connections {
        target: Player.rendererManager
        function onDataChanged() {
            ++root.revision;
        }
    }
    Connections {
        target: root.popup
        function onVisibleChanged() {
            if (root.popup.visible)
                Player.rendererManager.StartScan();
            else
                Player.rendererManager.StopScan();
        }
    }
}
