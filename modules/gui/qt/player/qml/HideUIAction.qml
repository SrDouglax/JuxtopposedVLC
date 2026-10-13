import QtQuick.Controls.Basic as Controls

import VLC.MainInterface

Controls.MenuItem {
    objectName: "hidePlayerUIAction"
    text: MainCtx.minimalView ? qsTr("Show player UI") : qsTr("Hide player UI")
    checkable: true
    checked: MainCtx.minimalView
    onTriggered: MainCtx.minimalView = !MainCtx.minimalView
}
