/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import VLC.Dialogs
import VLC.Player
import VLC.Style
RedesignIconButton {
    iconSource: "qrc:///redesign/icons/HDR/default.png"
    text: "HDR"
    description: qsTr("HDR output")
    enabled: !paintOnly && Player.videoTracks.count > 0
    onClicked: DialogsProvider.hdrOutputDialog()
}
