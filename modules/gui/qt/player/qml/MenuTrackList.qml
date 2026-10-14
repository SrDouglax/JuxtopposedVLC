/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    required property var sourceModel
    property bool showNone: true
    property int revision: 0
    spacing: 0
    Connections {
        target: root.sourceModel
        function onDataChanged() {
            ++root.revision;
        }
        function onModelReset() {
            ++root.revision;
        }
    }
    PanelTrackRow {
        Layout.fillWidth: true
        visible: root.showNone
        text: qsTr("None")
        checked: {
            root.revision;
            rows.count;
            for (let i = 0; i < rows.count; ++i)
                if (root.sourceModel.data(root.sourceModel.index(i, 0), Qt.CheckStateRole))
                    return false;
            return true;
        }
        onClicked: {
            for (let i = 0; i < rows.count; ++i)
                root.sourceModel.setData(root.sourceModel.index(i, 0), false, Qt.CheckStateRole);
        }
    }
    Repeater {
        id: rows
        model: root.sourceModel
        PanelTrackRow {
            required property var model
            required property int index
            Layout.fillWidth: true
            text: model.display
            checked: model.checked
            onClicked: root.sourceModel.setData(root.sourceModel.index(index, 0), true, Qt.CheckStateRole)
        }
    }
}
