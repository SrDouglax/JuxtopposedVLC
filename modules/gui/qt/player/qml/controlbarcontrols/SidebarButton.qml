/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import VLC.MainInterface
import VLC.Style

RedesignIconButton {
    objectName: "sourceSidebarButton"
    text: VLCIcons.playlist
    description: qsTr("Show source library")
    iconSource: "qrc:///redesign/icons/sidebar/active.png"
    checked: MainCtx.playqueuePanel.visible
    onClicked: MainCtx.playqueuePanel.visible = !MainCtx.playqueuePanel.visible
}
