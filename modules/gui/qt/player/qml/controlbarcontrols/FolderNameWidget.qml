/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import VLC.Player
MetadataText {
    property bool preferSourceName: false
    iconSource: "qrc:///redesign/icons/folder/default.png"
    value: {
        if (preferSourceName && Player.playlistName) return Player.playlistName
        const path = Player.url.toString().split(/[?#]/)[0]
        const directory = path.substring(0, path.lastIndexOf("/"))
        const leaf = directory.substring(directory.lastIndexOf("/") + 1)
        try { return decodeURIComponent(leaf) } catch (error) { return leaf }
    }
    placeholder: qsTr("Folder name unavailable")
}
