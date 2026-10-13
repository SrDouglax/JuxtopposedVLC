/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Controls.Basic as Controls
import VLC.Dialogs
import VLC.Style
import VLC.Player

Controls.Popup {
    id: root
    width: 344
    padding: 12
    closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside
    background: Rectangle { color: "#1b1b1b"; radius: 11; border.color: "#252525" }
    contentItem: Column {
        spacing: 4
        PersonalizationActions { width: parent.width }
        HideUIAction { width: parent.width; onClicked: root.close() }
        Repeater {
            model: [qsTr("Sleep timer"), qsTr("Preferences")]
            delegate: Controls.ItemDelegate {
                required property int index
                required property string modelData
                width: root.availableWidth
                height: 48
                background: Rectangle { color: parent.hovered ? "#252525" : "transparent"; radius: 6 }
                contentItem: Text {
                    text: modelData
                    color: "#969696"
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 12
                }
                onClicked: {
                    root.close()
                    if (index === 0) DialogsProvider.sleepTimerDialog()
                    else DialogsProvider.prefsDialog()
                }
            }
        }
    }
}
