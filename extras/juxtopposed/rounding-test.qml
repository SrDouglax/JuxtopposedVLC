import QtQuick

Rectangle {
    id: scene
    width: 640
    height: 180
    color: "#36506b"
    property Item cropImage
    Row {
        x: 20
        y: 20
        spacing: 30
        Repeater {
            model: 3
            delegate: Loader {
                required property int index
                width: 180
                height: index === 1 ? 160 : 100
                source: componentUrl
                onLoaded: {
                    if (index === 0) scene.cropImage = item
                    item.objectName = index === 0 ? "cropImage" : "otherImage"
                    item.radius = 20
                    if (index === 2) {
                        item.radiusTopRight = 0
                        item.radiusBottomLeft = 0
                    }
                    item.fillMode = index === 1 ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                    item.source = "image://fixture/sample"
                }
            }
        }
    }
}
