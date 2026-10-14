import QtQuick
import VLC.Player
import VLC.MainInterface
import VLC.PlayerControls

MetadataText {
    id: root
    value: details.resolution
    placeholder: qsTr("Resolution unavailable")
    PlayerMediaDetails { id: details; ctx: MainCtx; url: Player.url }
    Connections {
        target: Player.videoTracks
        function onCountChanged() { details.refresh() }
        function onDataChanged() { details.refresh() }
        function onModelReset() { details.refresh() }
    }
}
