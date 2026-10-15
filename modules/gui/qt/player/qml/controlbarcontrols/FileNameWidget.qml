import VLC.Player

MetadataText {
    property bool preferTitle: false
    iconSource: "qrc:///redesign/icons/file/default.png"
    value: {
        if (preferTitle && Player.name) return Player.name
        const mrl = Player.url.toString().split(/[?#]/)[0]
        const leaf = mrl.substring(mrl.lastIndexOf("/") + 1)
        try { return leaf ? decodeURIComponent(leaf) : (Player.name || "") }
        catch (error) { return leaf || Player.name || "" }
    }
    placeholder: preferTitle ? qsTr("VLC Media Player") : qsTr("File name unavailable")
}
