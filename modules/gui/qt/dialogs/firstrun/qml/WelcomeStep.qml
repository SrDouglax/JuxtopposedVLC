import QtQuick
import QtQuick.Controls.Basic as Controls

import VLC.Style

Item {
    id: root
    property var folderUrl
    property bool metadataNetworkAccess: false
    signal browseRequested()
    signal consentRequested(bool allowed)

    Image {
        width: 141
        height: 141
        anchors.horizontalCenter: parent.horizontalCenter
        y: 116
        source: "qrc:///redesign/welcome.svg"
        sourceSize: Qt.size(141, 141)
        fillMode: Image.PreserveAspectFit
        Accessible.name: qsTr("VLC")
    }
    Text {
        width: parent.width
        y: 286
        text: qsTr("Welcome to VLC!")
        color: "#eaeaea"
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: 32
        font.weight: Font.Light
        horizontalAlignment: Text.AlignHCenter
    }
    Text {
        x: (parent.width - width) / 2
        y: 362
        width: 595
        wrapMode: Text.WordWrap
        lineHeight: 1.75
        text: qsTr("VLC is a free and open source cross-platform multimedia player and framework that plays most multimedia files as well as DVDs, Audio CDs, VCDs, and various streaming protocols.")
        color: "#969696"
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: 16
        font.weight: Font.Light
    }
    Text {
        x: (parent.width - 595) / 2
        y: 500
        text: qsTr("Choose a media folder to get started with")
        color: "#8f8f8f"
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: 14
    }
    Rectangle {
        x: (parent.width - 595) / 2
        y: 532
        width: 471
        height: 36
        color: "#090909"
        border.width: 2
        border.color: "#191919"
        radius: 6
        Text {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideMiddle
            text: root.folderUrl && root.folderUrl.toString() !== ""
                  ? decodeURIComponent(root.folderUrl.toString().replace(/^file:\/\//, "")) : qsTr("No folder selected")
            color: "#c6c6c6"
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: 16
        }
    }
    OnboardingButton {
        x: (parent.width - 595) / 2 + 481
        y: 532
        width: 114
        height: 36
        objectName: "onboardingBrowseFolder"
        text: qsTr("Browse")
        onClicked: root.browseRequested()
    }
    Controls.CheckBox {
        id: onlineConsent
        x: (parent.width - 595) / 2
        y: 592
        width: 595
        checked: root.metadataNetworkAccess
        text: qsTr("Allow online metadata and cover art lookup")
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: 14
        onToggled: root.consentRequested(checked)
        indicator: Rectangle {
            x: 0
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            radius: 4
            color: onlineConsent.checked ? VLCStyle.redesign.accent : "#090909"
            border.color: onlineConsent.checked ? VLCStyle.redesign.accent : "#555555"
            Text {
                anchors.centerIn: parent
                text: "✓"
                visible: onlineConsent.checked
                color: "#161616"
                font.pixelSize: 13
            }
        }
        contentItem: Text {
            leftPadding: 29
            text: onlineConsent.text
            font: onlineConsent.font
            color: "#969696"
            verticalAlignment: Text.AlignVCenter
        }
    }
}
