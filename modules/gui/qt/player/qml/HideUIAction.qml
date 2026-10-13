import QtQuick.Controls.Basic as Controls

import VLC.MainInterface
import VLC.Style

Controls.MenuItem {
    font.family: VLCStyle.redesign.fontFamily
    font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
    palette.text: VLCStyle.redesign.textSecondary
    palette.windowText: VLCStyle.redesign.textSecondary
    objectName: "hidePlayerUIAction"
    text: MainCtx.minimalView ? qsTr("Show player UI") : qsTr("Hide player UI")
    checkable: true
    checked: MainCtx.minimalView
    onTriggered: MainCtx.minimalView = !MainCtx.minimalView
}
