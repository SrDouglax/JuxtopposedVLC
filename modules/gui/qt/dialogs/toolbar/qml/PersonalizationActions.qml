import QtQuick
import QtQuick.Controls.Basic as Controls

import VLC.Dialogs
import VLC.MainInterface
import VLC.Style

Column {
    id: root
    objectName: "personalizationActions"
    property bool showProfiles: true
    property var profileModel: MainCtx.controlbarProfileModel
    signal customizeRequested()
    width: 320
    spacing: 0

    Controls.ItemDelegate {
        id: profileButton
        visible: root.showProfiles
        objectName: "openProfilesAction"
        width: parent.width
        height: 48
        background: Rectangle {
            radius: 6
            color: profileButton.hovered || profilesMenu.opened ? VLCStyle.redesign.color("#252525", "#dddddd") : "transparent"
        }
        contentItem: Row {
            spacing: 12
            Text {
                width: profileButton.width - 54
                height: parent.height
                text: qsTr("Profile (%1)").arg(root.profileModel.currentModel
                                            ? root.profileModel.currentModel.name : qsTr("None"))
                elide: Text.ElideRight
                color: VLCStyle.redesign.color("#969696", "#494949")
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: 16
                verticalAlignment: Text.AlignVCenter
            }
            Image {
                width: 24
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                source: "qrc:///redesign/icons/chevron-right/default.png"
            }
        }
        onClicked: profilesMenu.open()

        ProfilesMenu {
            id: profilesMenu
            parent: profileButton
            profileModel: root.profileModel
            x: 0
            y: profileButton.height
        }
    }

    Controls.ItemDelegate {
        id: customizeButton
        objectName: "customizePlayerAction"
        width: parent.width
        height: 48
        background: Rectangle {
            radius: 6
            color: customizeButton.hovered ? VLCStyle.redesign.color("#252525", "#dddddd") : "transparent"
        }
        contentItem: Text {
            text: qsTr("Customize player")
            color: VLCStyle.redesign.color("#969696", "#494949")
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: 16
            verticalAlignment: Text.AlignVCenter
            leftPadding: 12
        }
        onClicked: root.customizeRequested()
    }
}
