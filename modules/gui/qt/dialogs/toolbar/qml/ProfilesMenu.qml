import QtQuick
import QtQuick.Controls.Basic as Controls

import VLC.Dialogs
import VLC.MainInterface
import VLC.Style

Controls.Popup {
    id: root
    objectName: "profilesMenu"
    property var profileModel: MainCtx.controlbarProfileModel
    property string switchError: ""

    width: 264
    height: Math.min(profileModel.count, 6) * 48 + 61
            + ((switchError || profileModel.lastError) ? 56 : 0)
    padding: 0
    closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside

    background: Rectangle {
        color: "#1b1b1b"
        radius: 11
        border.color: "#252525"
    }

    contentItem: Column {
        spacing: 0

        ListView {
            id: profileList
            width: parent.width
            height: Math.min(root.profileModel.count, 6) * 48
            clip: true
            model: root.profileModel
            currentIndex: root.profileModel.selectedProfile
            boundsBehavior: Flickable.StopAtBounds

            delegate: Controls.ItemDelegate {
                required property int index
                required property string name
                readonly property bool activeProfile: root.profileModel.selectedProfile === index
                objectName: "profileOption_" + index
                width: profileList.width
                height: 48
                leftPadding: 18
                rightPadding: 16
                background: Rectangle {
                    radius: 6
                    color: parent.hovered || parent.activeProfile ? "#252525" : "transparent"
                }
                contentItem: Row {
                    spacing: 12
                    Image {
                        width: 24
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter
                        source: "qrc:///redesign/icons/check/selected.png"
                        opacity: activeProfile ? 1 : 0
                    }
                    Text {
                        width: parent.width - 36
                        height: parent.height
                        text: name
                        color: "#969696"
                        elide: Text.ElideRight
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: 16
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                Accessible.name: name
                Accessible.description: activeProfile ? qsTr("Selected profile") : ""
                onClicked: {
                    root.switchError = ""
                    if (root.profileModel.selectedProfile !== index) {
                        const previous = root.profileModel.selectedProfile
                        if (!root.profileModel.setSelectedProfile(index))
                            return
                        if (!root.profileModel.save()) {
                            root.switchError = root.profileModel.lastError
                            root.profileModel.setSelectedProfile(previous)
                            return
                        }
                    }
                    root.close()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: "#292929"
        }

        Text {
            visible: !!(root.switchError || root.profileModel.lastError)
            width: parent.width - 32
            height: visible ? 56 : 0
            x: 16
            text: root.switchError || root.profileModel.lastError
            color: "#e4a580"
            wrapMode: Text.WordWrap
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
            Accessible.role: Accessible.AlertMessage
        }

        Controls.ItemDelegate {
            objectName: "newProfileAction"
            width: parent.width
            height: 60
            leftPadding: 18
            background: Rectangle {
                radius: 6
                color: parent.hovered ? "#252525" : "transparent"
            }
            contentItem: Row {
                spacing: 12
                Text {
                    width: 20
                    height: parent.height
                    text: "+"
                    color: "#969696"
                    font.pixelSize: 25
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    height: parent.height
                    text: qsTr("New profile…")
                    color: "#969696"
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                }
            }
            onClicked: {
                root.close()
                // The existing editor owns creation, cloning, Save, and Cancel.
                DialogsProvider.showToolbarEditorDialog()
            }
        }
    }
}
