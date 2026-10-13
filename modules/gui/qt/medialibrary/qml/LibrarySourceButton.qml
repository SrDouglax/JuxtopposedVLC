import QtQuick
import QtQuick.Layouts
import VLC.Style
import VLC.Network as Network
import VLC.MainInterface
import VLC.Dialogs
import VLC.MediaLibrary
import VLC.Widgets as Widgets

Widgets.ButtonExt {
    id: root
    property bool iconOnly: false
    colorContext.palette: VLCStyle.palette
    padding: iconOnly ? 0 : VLCStyle.dp(8, VLCStyle.scale)
    contentItem: RowLayout {
        spacing: 0
        Image {
            visible: root.iconOnly
            Layout.preferredWidth: VLCStyle.redesign.iconSize
            Layout.preferredHeight: VLCStyle.redesign.iconSize
            source: "qrc:///redesign/add.svg"
            sourceSize: Qt.size(24, 24)
        }
        Widgets.LabelExt {
            visible: !root.iconOnly
            text: root.text
            color: VLCStyle.redesign.textMuted
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        }
    }
    objectName: "libraryAddFolderButton"
    text: qsTr("Add folder")
    enabled: MainCtx.mediaLibraryAvailable
    onClicked: {
        const folder = filePicker.chooseFolder(qsTr("Add folder to media library"))
        if (folder.toString() !== "") folders.add(folder)
    }

    Network.MLFolderModel {
        id: folders
        ctx: MainCtx
        onOperationFailed: (op, url) => {
            DialogsProvider.messageDialog(qsTr("Could not add this folder to the library: %1").arg(url),
                                           qsTr("Media library"))
        }
    }

    Widgets.FilePicker { id: filePicker; ctx: MainCtx }
}
