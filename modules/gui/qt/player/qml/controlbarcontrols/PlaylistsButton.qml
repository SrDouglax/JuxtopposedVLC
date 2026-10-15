/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import VLC.MainInterface
import VLC.Util
RedesignIconButton {
    iconSource: "qrc:///redesign/icons/playlist/default.png"
    description: qsTr("Playlists")
    enabled: MainCtx.mediaLibraryAvailable
    onClicked: { History.push(["video", "playlists"]); MainCtx.playerView = false }
}
