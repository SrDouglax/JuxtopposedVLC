import VLC.Player

MetadataText {
    value: Player.isStarted && Player.length.toSeconds() > 0 ? Player.length.formatHMS() : ""
    placeholder: qsTr("Duration unavailable")
}
