/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import VLC.Player
RedesignIconButton {
    iconSource: "qrc:///redesign/icons/forward-15-sec/default.png"
    enabled: Player.seekable
    description: qsTr("Forward 15s")
    onClicked: Player.jumpSeconds(15)
}
