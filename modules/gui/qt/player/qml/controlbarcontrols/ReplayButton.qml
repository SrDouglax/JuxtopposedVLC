/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import VLC.Player
import VLC.MainInterface
RedesignIconButton {
    iconSource: "qrc:///redesign/icons/replay/default.png"
    enabled: Player.seekable
    description: qsTr("Replay")
    onClicked: { Player.jumpToPos(0); MainPlaylistController.play() }
}
