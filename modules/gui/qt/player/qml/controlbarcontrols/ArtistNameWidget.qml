import VLC.Player

MetadataText {
    iconSource: "qrc:///redesign/icons/artist/default.png"
    value: Player.artist || ""
    placeholder: qsTr("Artist unavailable")
}
