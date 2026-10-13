import QtQuick
import VLC.Network as Network
import VLC.MainInterface
import VLC.Dialogs
import VLC.MediaLibrary
import VLC.Widgets as Widgets

Widgets.ButtonExt {
    id: root
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
