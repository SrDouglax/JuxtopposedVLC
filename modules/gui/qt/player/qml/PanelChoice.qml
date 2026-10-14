/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick

PanelCombo {
    id: root
    textRole: "display"
    currentIndex: -1
    displayText: currentIndex < 0 ? qsTr("None") : currentText
    enabled: count > 0
    function syncSelection() {
        for (let i = 0; i < count; ++i) {
            if (model.data(model.index(i, 0), Qt.CheckStateRole)) {
                currentIndex = i;
                return;
            }
        }
        currentIndex = -1;
    }
    onActivated: index => {
        if (typeof model.toggleIndex === "function")
            model.toggleIndex(index);
        else
            model.setData(model.index(index, 0), true, Qt.CheckStateRole);
    }
    Repeater {
        model: root.model
        delegate: Item {
            required property int index
            required property bool checked
            visible: false
            onCheckedChanged: root.syncSelection()
            Component.onCompleted: root.syncSelection()
        }
    }
}
