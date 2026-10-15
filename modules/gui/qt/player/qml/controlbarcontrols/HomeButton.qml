/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import VLC.MainInterface
import VLC.Util
RedesignIconButton {
    iconSource: "qrc:///redesign/icons/home/default.png"
    description: qsTr("Go Home")
    onClicked: { History.push(["home"]); MainCtx.playerView = false }
}
