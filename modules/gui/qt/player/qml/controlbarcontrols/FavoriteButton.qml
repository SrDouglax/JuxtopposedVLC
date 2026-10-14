import QtQuick
import VLC.Player
import VLC.MainInterface
import VLC.PlayerControls

RedesignIconButton {
    id: root
    iconSource: state.favorite ? "qrc:///redesign/icons/favorite/active.png"
                               : "qrc:///redesign/icons/favorite/default.png"
    checked: state.favorite
    enabled: !paintOnly && state.available && !state.busy
    description: state.error.length ? state.error
                 : !state.available ? qsTr("Available for items in your library")
                 : state.favorite ? qsTr("Remove from favorites") : qsTr("Add to favorites")
    Accessible.name: description
    onClicked: state.toggle()
    FavoriteState { id: state; ctx: MainCtx; url: Player.url }
}
