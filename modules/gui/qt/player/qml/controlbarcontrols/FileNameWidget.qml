import VLC.Player

MetadataText {
    iconSource: "qrc:///redesign/icons/file/default.png"
    value: {
        const mrl = Player.url.toString().split(/[?#]/)[0]
        const leaf = mrl.substring(mrl.lastIndexOf("/") + 1)
        try { return leaf ? decodeURIComponent(leaf) : (Player.name || "") }
        catch (error) { return leaf || Player.name || "" }
    }
    placeholder: qsTr("File name unavailable")
}
